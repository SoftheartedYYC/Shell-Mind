import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../storage/hive_storage_service.dart';

/// How an audited command was executed by the AI agent.
enum CommandAuditMode {
  /// The user explicitly confirmed this command in the agent bar.
  confirmed,

  /// The command ran inside the hands-off auto-execution loop.
  auto,
}

/// One persisted audit record for an AI-executed command.
///
/// Privacy contract: the full command output is never stored — only a boolean
/// [hasOutput] and a truncated [outputSummary] (first 200 characters of
/// stdout, or stderr when stdout is empty). No credentials or host identities
/// beyond the display name are recorded.
@immutable
class CommandAuditEntry {
  const CommandAuditEntry({
    required this.id,
    required this.command,
    required this.serverId,
    required this.serverName,
    required this.exitCode,
    required this.success,
    required this.mode,
    required this.executedAt,
    required this.elapsed,
    required this.hasDangerous,
    required this.hasOutput,
    this.outputSummary = '',
  });

  /// Stable unique id (monotonic counter + timestamp so JSON round-trips keep
  /// distinct entries even within the same millisecond).
  final String id;

  /// The exact command string that was sent to the remote host.
  final String command;

  /// Server the command ran on (uuid, may be empty when unknown).
  final String serverId;

  /// Human-readable server label at execution time.
  final String serverName;

  /// Remote exit code; `-1` when the run failed before reporting one.
  final int exitCode;

  /// Whether the command completed successfully.
  final bool success;

  /// Whether it ran in confirmed or auto mode.
  final CommandAuditMode mode;

  /// When execution completed.
  final DateTime executedAt;

  /// Wall-clock duration of the execution.
  final Duration elapsed;

  /// Whether [command] matched the dangerous-command heuristic.
  final bool hasDangerous;

  /// Whether the command produced any output at all (stdout or stderr).
  final bool hasOutput;

  /// First 200 characters of the output (stdout preferred, stderr fallback).
  /// Empty string when there was no output.
  final String outputSummary;

  /// Maximum stored length of [outputSummary].
  static const int outputSummaryMaxLength = 200;

  /// Builds a privacy-safe output summary from raw streams.
  ///
  /// Keeps at most [outputSummaryMaxLength] characters, preferring stdout and
  /// falling back to stderr when stdout is blank.
  static String summarizeOutput(String stdout, String stderr) {
    final String source = stdout.trim().isNotEmpty ? stdout : stderr;
    final String flattened =
        source.replaceAll('\r', '').trim().replaceAll('\n', ' ⏎ ');
    if (flattened.isEmpty) return '';
    if (flattened.length <= outputSummaryMaxLength) return flattened;
    return '${flattened.substring(0, outputSummaryMaxLength)}…';
  }

  /// Decodes a persisted JSON map produced by [toJsonMap]. Returns `null`
  /// for malformed frames so a corrupt entry can never crash startup.
  static CommandAuditEntry? fromJsonMap(Object? raw) {
    if (raw is! Map) return null;
    final Object? id = raw['id'];
    final Object? command = raw['command'];
    final Object? serverId = raw['serverId'];
    final Object? serverName = raw['serverName'];
    final Object? exitCode = raw['exitCode'];
    final Object? success = raw['success'];
    final Object? mode = raw['mode'];
    final Object? executedAt = raw['executedAt'];
    final Object? elapsedMs = raw['elapsedMs'];
    final Object? hasDangerous = raw['hasDangerous'];
    final Object? hasOutput = raw['hasOutput'];
    if (id is! String ||
        command is! String ||
        serverId is! String ||
        serverName is! String ||
        exitCode is! int ||
        success is! bool ||
        mode is! String ||
        executedAt is! String ||
        elapsedMs is! int ||
        hasDangerous is! bool ||
        hasOutput is! bool) {
      return null;
    }
    final DateTime? when = DateTime.tryParse(executedAt);
    if (when == null) return null;
    final Object? summary = raw['outputSummary'];
    return CommandAuditEntry(
      id: id,
      command: command,
      serverId: serverId,
      serverName: serverName,
      exitCode: exitCode,
      success: success,
      mode: mode == 'auto' ? CommandAuditMode.auto : CommandAuditMode.confirmed,
      executedAt: when,
      elapsed: Duration(milliseconds: elapsedMs),
      hasDangerous: hasDangerous,
      hasOutput: hasOutput,
      outputSummary: summary is String ? summary : '',
    );
  }

  /// Encodes this entry for Hive persistence (a JSON map).
  Map<String, Object?> toJsonMap() => <String, Object?>{
        'id': id,
        'command': command,
        'serverId': serverId,
        'serverName': serverName,
        'exitCode': exitCode,
        'success': success,
        'mode': mode == CommandAuditMode.auto ? 'auto' : 'confirmed',
        'executedAt': executedAt.toIso8601String(),
        'elapsedMs': elapsed.inMilliseconds,
        'hasDangerous': hasDangerous,
        'hasOutput': hasOutput,
        'outputSummary': outputSummary,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommandAuditEntry &&
          other.id == id &&
          other.command == command &&
          other.serverId == serverId &&
          other.serverName == serverName &&
          other.exitCode == exitCode &&
          other.success == success &&
          other.mode == mode &&
          other.executedAt == executedAt &&
          other.elapsed == elapsed &&
          other.hasDangerous == hasDangerous &&
          other.hasOutput == hasOutput &&
          other.outputSummary == outputSummary;

  @override
  int get hashCode => Object.hash(id, command, serverId, serverName, exitCode,
      success, mode, executedAt, elapsed, hasDangerous, hasOutput, outputSummary);

  @override
  String toString() =>
      'CommandAuditEntry($id, "$command", $serverName, exit=$exitCode, '
      '$mode, ${elapsed.inMilliseconds}ms)';
}

/// AI command execution audit trail.
///
/// Backed by a single JSON-array key inside the `app_meta` Hive box (same
/// zero-TypeAdapter pattern as `CustomAiProviderStore`), capped at
/// [AppConstants.kMaxCommandAuditEntries] entries with FIFO eviction. All
/// reads are served from an in-memory snapshot updated on every mutation.
class CommandAuditLog {
  CommandAuditLog({HiveStorageService? hive})
      : _hive = hive ?? HiveStorageService.instance;

  /// Process-wide singleton, preloaded during app bootstrap so the provider
  /// below and any fire-and-forget recorder observe the same snapshot.
  static final CommandAuditLog instance = CommandAuditLog();

  final HiveStorageService _hive;

  static const String _box = AppConstants.hiveBoxMeta;
  static const String _key = AppConstants.hiveKeyCommandAuditLog;

  List<CommandAuditEntry> _cache = const <CommandAuditEntry>[];
  int _counter = 0;

  /// Current snapshot, newest first. Empty until [preload] or a mutation.
  List<CommandAuditEntry> get all => _cache;

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
  /// the list and refreshes the snapshot. Returns the stored entry.
  Future<CommandAuditEntry> record(CommandAuditEntry entry) async {
    final List<CommandAuditEntry> next = <CommandAuditEntry>[
      entry,
      ..._cache,
    ];
    if (next.length > AppConstants.kMaxCommandAuditEntries) {
      next.removeRange(AppConstants.kMaxCommandAuditEntries, next.length);
    }
    // Publish first so fire-and-forget recorders (the agent loop never awaits
    // this) always observe the newest state immediately.
    _cache = List<CommandAuditEntry>.unmodifiable(next);
    // Best-effort persistence: auditing must never break command execution,
    // so storage failures (including an uninitialised box in tests) are
    // swallowed and the in-memory snapshot remains the source of truth.
    try {
      await _writeAll(next);
    } catch (_) {
      // Ignore persistence errors.
    }
    return entry;
  }

  /// Convenience wrapper: builds an entry from a command + execution facts
  /// and records it. Output is summarised, never stored in full.
  Future<CommandAuditEntry> recordExecution({
    required String command,
    required String serverId,
    required String serverName,
    required int exitCode,
    required bool success,
    required CommandAuditMode mode,
    required DateTime executedAt,
    required Duration elapsed,
    required bool hasDangerous,
    String stdout = '',
    String stderr = '',
  }) {
    final String summary = CommandAuditEntry.summarizeOutput(stdout, stderr);
    return record(CommandAuditEntry(
      id: newEntryId(),
      command: command,
      serverId: serverId,
      serverName: serverName,
      exitCode: exitCode,
      success: success,
      mode: mode,
      executedAt: executedAt,
      elapsed: elapsed,
      hasDangerous: hasDangerous,
      hasOutput: summary.isNotEmpty,
      outputSummary: summary,
    ));
  }

  /// Clears every entry (in memory and on disk).
  Future<void> clear() async {
    await _hive.delete(_box, _key);
    _cache = const <CommandAuditEntry>[];
  }

  /// Filters the snapshot.
  ///
  /// `null` criteria mean "any"; [serverId] matches exactly, [mode] matches
  /// the execution mode, [success] matches the outcome flag.
  List<CommandAuditEntry> query({
    String? serverId,
    CommandAuditMode? mode,
    bool? success,
  }) {
    return _cache
        .where((CommandAuditEntry e) =>
            (serverId == null || e.serverId == serverId) &&
            (mode == null || e.mode == mode) &&
            (success == null || e.success == success))
        .toList(growable: false);
  }

  // ─── Internals ──────────────────────────────────────────────────────────

  List<CommandAuditEntry> _readAllFromBox() {
    final Object? raw = _hive.get<Object>(_box, _key);
    if (raw is! String || raw.isEmpty) return const <CommandAuditEntry>[];
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return const <CommandAuditEntry>[];
      final List<CommandAuditEntry> parsed = <CommandAuditEntry>[
        for (final Object? frame in decoded)
          if (CommandAuditEntry.fromJsonMap(frame) case final CommandAuditEntry e) e,
      ];
      // Newest first, matching the in-memory layout.
      parsed.sort(
          (CommandAuditEntry a, CommandAuditEntry b) => b.executedAt.compareTo(a.executedAt));
      return parsed;
    } on FormatException {
      // Corrupt frame — start over rather than crash.
      return const <CommandAuditEntry>[];
    }
  }

  Future<void> _writeAll(List<CommandAuditEntry> entries) {
    final String encoded = jsonEncode(<Object?>[
      for (final CommandAuditEntry e in entries) e.toJsonMap(),
    ]);
    return _hive.put(_box, _key, encoded);
  }
}

/// Riverpod provider for the singleton audit log service.
final Provider<CommandAuditLog> commandAuditLogProvider =
    Provider<CommandAuditLog>((Ref ref) => CommandAuditLog.instance);

/// Reactive snapshot of the audit trail for the UI, newest first.
///
/// Not autoDispose: the trail must survive navigation away from the audit
/// page (and the settings screen) so a just-recorded command is still visible.
class CommandAuditNotifier extends Notifier<List<CommandAuditEntry>> {
  @override
  List<CommandAuditEntry> build() =>
      List<CommandAuditEntry>.unmodifiable(
          ref.watch(commandAuditLogProvider).all);

  /// Records an entry through the backing service and refreshes the state.
  Future<void> record(CommandAuditEntry entry) async {
    await ref.read(commandAuditLogProvider).record(entry);
    state = List<CommandAuditEntry>.unmodifiable(
        ref.read(commandAuditLogProvider).all);
  }

  /// Clears every entry and refreshes the state.
  Future<void> clearAll() async {
    await ref.read(commandAuditLogProvider).clear();
    state = const <CommandAuditEntry>[];
  }
}

final NotifierProvider<CommandAuditNotifier, List<CommandAuditEntry>>
    commandAuditNotifierProvider =
    NotifierProvider<CommandAuditNotifier, List<CommandAuditEntry>>(
        CommandAuditNotifier.new);
