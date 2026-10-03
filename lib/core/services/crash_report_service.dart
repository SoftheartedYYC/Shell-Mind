import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../storage/hive_storage_service.dart';

/// One persisted crash / uncaught-exception record.
///
/// Privacy contract: [message] and [stackTrace] pass through the redaction
/// sweep in [redact] before being stored, so secrets that happened to leak
/// into an error payload (API keys, PEM blocks, bearer tokens) never survive
/// to disk or to the diagnostic export. No host identities or user content
/// are recorded beyond what the error itself carries.
@immutable
class CrashReportEntry {
  const CrashReportEntry({
    required this.id,
    required this.source,
    required this.message,
    required this.stackTrace,
    required this.appVersion,
    required this.platform,
    required this.locale,
    required this.occurredAt,
  });

  /// Stable unique id (`micros_counter`), mirroring the audit log scheme so
  /// JSON round-trips keep entries distinct within the same millisecond.
  final String id;

  /// Where the error was caught: `flutter` (framework handler) or `platform`
  /// (uncaught Dart-zone error via PlatformDispatcher).
  final String source;

  /// Redacted error summary (single line, capped).
  final String message;

  /// Redacted stack trace, at most [stackTraceMaxLength] characters.
  final String stackTrace;

  /// App version at crash time, e.g. `1.4.1`.
  final String appVersion;

  /// Operating system label, e.g. `android`, `ios`, `windows`.
  final String platform;

  /// Locale tag at crash time, e.g. `zh_CN` (empty when unavailable).
  final String locale;

  /// When the error was caught.
  final DateTime occurredAt;

  /// Maximum stored length of [stackTrace].
  static const int stackTraceMaxLength = 2000;

  /// Maximum stored length of [message].
  static const int messageMaxLength = 300;

  /// Best-effort secret sweep applied to every stored string.
  ///
  /// Replaces recognised credential fragments with `[REDACTED]`:
  /// - `sk-…` style API keys (OpenAI/DeepSeek family)
  /// - PEM private-key blocks, plus dangling BEGIN/END lines when the block
  ///   was truncated by the stack cap
  /// - `Bearer <token>` / `Authorization: Bearer …` headers
  /// - `api_key=…` / `apikey=…` / `token=…` query-style values (the label is
  ///   kept, the value is masked)
  static String redact(String input) {
    if (input.isEmpty) return input;
    return input
        .replaceAllMapped(_pemPattern, (_) => '[REDACTED]')
        .replaceAllMapped(_pemLinePattern, (_) => '[REDACTED]')
        .replaceAllMapped(_bearerPattern, (_) => '[REDACTED]')
        .replaceAllMapped(_querySecretPattern,
            (Match m) => '${m.group(1)}[REDACTED]')
        .replaceAllMapped(_skKeyPattern, (_) => '[REDACTED]');
  }

  /// Flattens an arbitrary error into a redacted single-line summary.
  static String summarize(Object? error) {
    final String raw = error?.toString() ?? 'Unknown error';
    final String flattened = raw
        .replaceAll('\r', '')
        .replaceAll('\n', ' ⏎ ')
        .trim();
    final String redacted = redact(flattened);
    if (redacted.length <= messageMaxLength) return redacted;
    return '${redacted.substring(0, messageMaxLength)}…';
  }

  /// Builds a redacted, length-capped stack trace string.
  static String stackToString(StackTrace? stack) {
    if (stack == null) return '';
    final String raw = stack.toString();
    final String redacted = redact(raw);
    if (redacted.length <= stackTraceMaxLength) return redacted;
    return '${redacted.substring(0, stackTraceMaxLength)}…';
  }

  // `sk-` followed by ≥8 word chars/dashes — long enough that ordinary prose
  // like "task-sk-1" cannot trip it, short enough for real keys.
  static final RegExp _skKeyPattern =
      RegExp(r'sk-[A-Za-z0-9_-]{8,}', multiLine: true);

  // PEM blocks (private keys, but also certificates for safety).
  static final RegExp _pemPattern = RegExp(
    r'-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z ]*PRIVATE KEY-----',
    multiLine: true,
  );

  // Dangling PEM boundary lines (block truncated by the stack cap, or a
  // stack trace that merely references the key file).
  static final RegExp _pemLinePattern =
      RegExp(r'^-----BEGIN [A-Z ]*PRIVATE KEY-----.*$', multiLine: true);

  // `Authorization: Bearer xyz` and bare `Bearer xyz` fragments.
  static final RegExp _bearerPattern = RegExp(
    r'\b(?:bearer|authorization\s*:?\s*bearer)\s+[A-Za-z0-9._~+/=-]{8,}',
    caseSensitive: false,
  );

  // `api_key=…`, `apikey=…`, `token=…`, `key=…` value capture.
  // Group 1 keeps the label (`api_key=`), group 2 carries the secret value.
  static final RegExp _querySecretPattern = RegExp(
      r'((?:api_?key|token|secret|pass(?:word)?)\s*[=:]\s*)["\x27]?([^\s"\x27;&]{4,})',
      caseSensitive: false);

  /// Decodes a persisted JSON map produced by [toJsonMap]. Returns `null`
  /// for malformed frames so a corrupt entry can never crash startup.
  static CrashReportEntry? fromJsonMap(Object? raw) {
    if (raw is! Map) return null;
    final Object? id = raw['id'];
    final Object? source = raw['source'];
    final Object? message = raw['message'];
    final Object? stackTrace = raw['stackTrace'];
    final Object? appVersion = raw['appVersion'];
    final Object? platform = raw['platform'];
    final Object? locale = raw['locale'];
    final Object? occurredAt = raw['occurredAt'];
    if (id is! String ||
        source is! String ||
        message is! String ||
        stackTrace is! String ||
        appVersion is! String ||
        platform is! String ||
        locale is! String ||
        occurredAt is! String) {
      return null;
    }
    final DateTime? when = DateTime.tryParse(occurredAt);
    if (when == null) return null;
    return CrashReportEntry(
      id: id,
      source: source == 'platform' ? 'platform' : 'flutter',
      message: message,
      stackTrace: stackTrace,
      appVersion: appVersion,
      platform: platform,
      locale: locale,
      occurredAt: when,
    );
  }

  /// Encodes this entry for Hive persistence (a JSON map).
  Map<String, Object?> toJsonMap() => <String, Object?>{
        'id': id,
        'source': source,
        'message': message,
        'stackTrace': stackTrace,
        'appVersion': appVersion,
        'platform': platform,
        'locale': locale,
        'occurredAt': occurredAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CrashReportEntry &&
          other.id == id &&
          other.source == source &&
          other.message == message &&
          other.stackTrace == stackTrace &&
          other.appVersion == appVersion &&
          other.platform == platform &&
          other.locale == locale &&
          other.occurredAt == occurredAt;

  @override
  int get hashCode => Object.hash(id, source, message, stackTrace, appVersion,
      platform, locale, occurredAt);

  @override
  String toString() => 'CrashReportEntry($id, $source, "$message")';
}

/// Global error capture with a bounded ring buffer.
///
/// Backed by a single JSON-array key inside the `app_meta` Hive box (same
/// zero-TypeAdapter pattern as [CommandAuditLog]), capped at
/// [AppConstants.kMaxCrashReportEntries] entries with FIFO eviction. All
/// reads are served from an in-memory snapshot updated on every mutation.
///
/// `record` is safe to call from any error handler: persistence failures
/// (including an uninitialised box in tests) are swallowed so capturing an
/// error can never itself throw.
class CrashReportService {
  CrashReportService({HiveStorageService? hive})
      : _hive = hive ?? HiveStorageService.instance;

  /// Process-wide singleton, preloaded during app bootstrap so the handler
  /// in `main.dart` and the diagnostic page observe the same snapshot.
  static final CrashReportService instance = CrashReportService();

  final HiveStorageService _hive;

  static const String _box = AppConstants.hiveBoxMeta;
  static const String _key = AppConstants.hiveKeyCrashReports;

  List<CrashReportEntry> _cache = const <CrashReportEntry>[];
  int _counter = 0;

  /// Environment metadata captured at bootstrap; filled in by [configure].
  String _appVersion = AppConstants.appVersion;
  String _platform = '';
  String _locale = '';

  /// Current snapshot, newest first. Empty until [preload] or a mutation.
  List<CrashReportEntry> get all => _cache;

  /// Device-info strings recorded alongside every new entry.
  String get currentAppVersion => _appVersion;
  String get currentPlatform => _platform;
  String get currentLocale => _locale;

  /// Captures environment metadata once during bootstrap so every recorded
  /// entry carries consistent device info. [platformLabel] should come from
  /// `Platform.operatingSystem`; [localeTag] from the resolved locale.
  void configure({
    required String platformLabel,
    required String localeTag,
    String? appVersion,
  }) {
    _platform = platformLabel;
    _locale = localeTag;
    if (appVersion != null && appVersion.isNotEmpty) {
      _appVersion = appVersion;
    }
  }

  /// Loads the persisted list into the in-memory snapshot. Call after
  /// `HiveStorageService.init()` during app bootstrap.
  Future<void> preload() async {
    _cache = _readAllFromBox();
  }

  /// Generates a fresh unique entry id.
  String newEntryId() {
    _counter++;
    return '${DateTime.now().microsecondsSinceEpoch}_$_counter';
  }

  /// Records [entry], evicting the oldest entries beyond the cap, persists
  /// the list and refreshes the snapshot. Never rethrows: error capture
  /// must be fail-safe.
  Future<CrashReportEntry> record(CrashReportEntry entry) async {
    final List<CrashReportEntry> next = <CrashReportEntry>[
      entry,
      ..._cache,
    ];
    if (next.length > AppConstants.kMaxCrashReportEntries) {
      next.removeRange(AppConstants.kMaxCrashReportEntries, next.length);
    }
    // Publish first — the caller (an error handler) must never block on I/O.
    _cache = List<CrashReportEntry>.unmodifiable(next);
    try {
      await _writeAll(next);
    } catch (_) {
      // Ignore persistence errors.
    }
    return entry;
  }

  /// Convenience wrapper: redacts and caps [message]/[stack] automatically.
  Future<CrashReportEntry> recordError({
    required String source,
    required Object? error,
    StackTrace? stack,
    DateTime? occurredAt,
    String? appVersion,
    String? platform,
    String? locale,
  }) {
    return record(CrashReportEntry(
      id: newEntryId(),
      source: source,
      message: CrashReportEntry.summarize(error),
      stackTrace: CrashReportEntry.stackToString(stack),
      appVersion: appVersion ?? _appVersion,
      platform: platform ?? _platform,
      locale: locale ?? _locale,
      occurredAt: occurredAt ?? DateTime.now(),
    ));
  }

  /// Clears every entry (in memory and on disk).
  Future<void> clear() async {
    await _hive.delete(_box, _key);
    _cache = const <CrashReportEntry>[];
  }

  // ─── Internals ──────────────────────────────────────────────────────────

  List<CrashReportEntry> _readAllFromBox() {
    final Object? raw = _hive.get<Object>(_box, _key);
    if (raw is! String || raw.isEmpty) return const <CrashReportEntry>[];
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return const <CrashReportEntry>[];
      final List<CrashReportEntry> parsed = <CrashReportEntry>[
        for (final Object? frame in decoded)
          if (CrashReportEntry.fromJsonMap(frame) case final CrashReportEntry e) e,
      ];
      // Newest first, matching the in-memory layout.
      parsed.sort((CrashReportEntry a, CrashReportEntry b) =>
          b.occurredAt.compareTo(a.occurredAt));
      return parsed;
    } on FormatException {
      // Corrupt frame — start over rather than crash.
      return const <CrashReportEntry>[];
    }
  }

  Future<void> _writeAll(List<CrashReportEntry> entries) {
    final String encoded = jsonEncode(<Object?>[
      for (final CrashReportEntry e in entries) e.toJsonMap(),
    ]);
    return _hive.put(_box, _key, encoded);
  }
}

/// Riverpod provider for the singleton crash report service.
final Provider<CrashReportService> crashReportServiceProvider =
    Provider<CrashReportService>((Ref ref) => CrashReportService.instance);

/// Reactive snapshot of captured errors for the diagnostics UI, newest first.
///
/// Not autoDispose: the list must survive navigation away from the
/// diagnostics page so a just-caught error is still visible.
class CrashReportNotifier extends Notifier<List<CrashReportEntry>> {
  @override
  List<CrashReportEntry> build() =>
      List<CrashReportEntry>.unmodifiable(
          ref.watch(crashReportServiceProvider).all);

  /// Records an entry through the backing service and refreshes the state.
  Future<void> record(CrashReportEntry entry) async {
    await ref.read(crashReportServiceProvider).record(entry);
    state = List<CrashReportEntry>.unmodifiable(
        ref.read(crashReportServiceProvider).all);
  }

  /// Clears every entry and refreshes the state.
  Future<void> clearAll() async {
    await ref.read(crashReportServiceProvider).clear();
    state = const <CrashReportEntry>[];
  }
}

final NotifierProvider<CrashReportNotifier, List<CrashReportEntry>>
    crashReportNotifierProvider =
    NotifierProvider<CrashReportNotifier, List<CrashReportEntry>>(
        CrashReportNotifier.new);
