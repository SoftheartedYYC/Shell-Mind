import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:shell_mind/core/constants/app_constants.dart';
import 'package:shell_mind/core/services/command_audit_log.dart';
import 'package:shell_mind/core/services/crash_report_service.dart';
import 'package:shell_mind/core/storage/hive_storage_service.dart';

/// Test-friendly HiveStorageService backed by a pre-initialised Hive in a
/// temp directory (avoids path_provider, mirrors the audit-log tests).
class _TestHiveStorageService implements HiveStorageService {
  @override
  bool get isInitialised => true;

  @override
  Box<dynamic> box(String name) => Hive.box<dynamic>(name);

  @override
  Future<Box<dynamic>> openBox(String name) async {
    if (Hive.isBoxOpen(name)) return Hive.box<dynamic>(name);
    return Hive.openBox<dynamic>(name);
  }

  @override
  Future<void> closeBox(String name) async {
    if (Hive.isBoxOpen(name)) {
      await Hive.box<dynamic>(name).close();
    }
  }

  @override
  Future<void> clearBox(String name) async => box(name).clear();

  @override
  Future<void> deleteBox(String name) async => Hive.deleteBoxFromDisk(name);

  @override
  T? get<T>(String boxName, String key, {T? defaultValue}) {
    final dynamic v = box(boxName).get(key, defaultValue: defaultValue);
    return v is T ? v : defaultValue;
  }

  @override
  List<T> getAll<T>(String boxName) =>
      box(boxName).values.whereType<T>().toList();

  @override
  Map<String, dynamic> toMap(String boxName) =>
      box(boxName).toMap().cast<String, dynamic>();

  @override
  Future<void> put(String boxName, String key, dynamic value) =>
      box(boxName).put(key, value);

  @override
  Future<void> putAll(String boxName, Map<String, dynamic> entries) =>
      box(boxName).putAll(entries);

  @override
  Future<void> delete(String boxName, String key) => box(boxName).delete(key);

  @override
  Future<void> deleteAllKeys(String boxName, Iterable<String> keys) =>
      box(boxName).deleteAll(keys);

  @override
  Future<int> add(String boxName, dynamic value) => box(boxName).add(value);

  @override
  bool hasKey(String boxName, String key) => box(boxName).containsKey(key);

  @override
  int length(String boxName) => box(boxName).length;

  @override
  Stream<BoxEvent> watch(String boxName, {String? key}) =>
      box(boxName).watch(key: key);

  @override
  void registerAdapter<T>(TypeAdapter<T> adapter, {bool internal = false}) {
    if (!Hive.isAdapterRegistered(adapter.typeId) || internal) {
      Hive.registerAdapter<T>(adapter, internal: internal);
    }
  }

  @override
  Future<void> init({String? subDirectory}) async {}

  @override
  Future<void> close() async => Hive.close();

  @override
  Future<void> wipeEverything() async {}
}

CrashReportEntry _entry({
  String id = 'id-1',
  String source = 'flutter',
  String message = 'Boom',
  String stackTrace = '#0 main (main.dart:1)',
  DateTime? occurredAt,
}) =>
    CrashReportEntry(
      id: id,
      source: source,
      message: message,
      stackTrace: stackTrace,
      appVersion: '1.4.1',
      platform: 'android',
      locale: 'zh_CN',
      occurredAt: occurredAt ?? DateTime(2026, 1, 2, 3, 4, 5),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late _TestHiveStorageService hive;
  late CrashReportService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('crash_report_test_');
    Hive.init(tempDir.path);
    await Hive.openBox<dynamic>(AppConstants.hiveBoxMeta);
    hive = _TestHiveStorageService();
    service = CrashReportService(hive: hive);
    await service.preload();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(AppConstants.hiveBoxMeta);
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  group('CrashReportService ring buffer', () {
    test('evicts oldest entries beyond the 50-entry FIFO cap', () async {
      final DateTime base = DateTime(2026, 1, 1);
      for (int i = 0; i < AppConstants.kMaxCrashReportEntries + 10; i++) {
        await service.record(_entry(
          id: 'e$i',
          occurredAt: base.add(Duration(minutes: i)),
        ));
      }

      expect(service.all.length, AppConstants.kMaxCrashReportEntries);
      // Newest kept, oldest dropped (e0..e9 evicted, e10..e59 kept).
      expect(service.all.first.id,
          'e${AppConstants.kMaxCrashReportEntries + 9}');
      expect(service.all.last.id, 'e10');
    });

    test('recordError redacts message and stack and stamps device info',
        () async {
      service.configure(
        platformLabel: 'android',
        localeTag: 'zh_CN',
        appVersion: '9.9.9',
      );
      await service.recordError(
        source: 'flutter',
        error: Exception('call failed: sk-abcdef1234567890'),
        stack: StackTrace.current,
      );

      final CrashReportEntry stored = service.all.single;
      expect(stored.message, contains('[REDACTED]'));
      expect(stored.message, isNot(contains('sk-abcdef1234567890')));
      expect(stored.appVersion, '9.9.9');
      expect(stored.platform, 'android');
      expect(stored.locale, 'zh_CN');
    });
  });

  group('CrashReportService persistence', () {
    test('round-trips through the single JSON-array key in app_meta',
        () async {
      await service.record(_entry(id: 'a', occurredAt: DateTime(2026, 1, 1)));
      await service.record(_entry(id: 'b', occurredAt: DateTime(2026, 1, 3)));

      // Shape: one key holding a JSON array, newest first.
      final Object? raw = hive.get<Object>(
          AppConstants.hiveBoxMeta, AppConstants.hiveKeyCrashReports);
      expect(raw, isA<String>());
      final List<Object?> frames =
          (jsonDecode(raw! as String) as List<Object?>);
      expect(frames.length, 2);
      expect(CrashReportEntry.fromJsonMap(frames.first)?.id, 'b');

      // A fresh instance reloaded from the same box sees the same entries.
      final CrashReportService reloaded = CrashReportService(hive: hive);
      await reloaded.preload();
      expect(reloaded.all.map((CrashReportEntry e) => e.id).toList(),
          <String>['b', 'a']);
    });

    test('clear removes the snapshot and the persisted key', () async {
      await service.record(_entry(id: 'a'));
      expect(service.all, isNotEmpty);

      await service.clear();

      expect(service.all, isEmpty);
      expect(
        hive.hasKey(
            AppConstants.hiveBoxMeta, AppConstants.hiveKeyCrashReports),
        isFalse,
      );
    });

    test('tolerates corrupt frames instead of throwing', () async {
      await hive.put(AppConstants.hiveBoxMeta,
          AppConstants.hiveKeyCrashReports, '{not json');

      final CrashReportService reloaded = CrashReportService(hive: hive);
      await reloaded.preload();
      expect(reloaded.all, isEmpty);
    });
  });

  group('CrashReportEntry.redact', () {
    test('masks sk- style API keys', () {
      final String out =
          CrashReportEntry.redact('OpenAI error for key sk-proj-abcd1234EFgh');
      expect(out, contains('[REDACTED]'));
      expect(out, isNot(contains('sk-proj-abcd1234EFgh')));
      // Ordinary prose containing a hyphenated token must not be masked.
      expect(CrashReportEntry.redact('task-sk-1 was queued'), 'task-sk-1 was queued');
    });

    test('masks PEM private-key blocks and dangling BEGIN lines', () {
      const String pem = '-----BEGIN PRIVATE KEY-----\nMIIEvQIBADAN\n'
          '-----END PRIVATE KEY-----';
      expect(CrashReportEntry.redact('key: $pem'), isNot(contains('MIIEvQ')));
      expect(CrashReportEntry.redact('-----BEGIN RSA PRIVATE KEY----- lost')
          .contains('[REDACTED]'), isTrue);
    });

    test('masks Bearer and Authorization headers', () {
      expect(CrashReportEntry.redact('Authorization: Bearer abc.def_ghi+jk'),
          contains('[REDACTED]'));
      expect(CrashReportEntry.redact('bearer AbcDef123456789'),
          contains('[REDACTED]'));
    });

    test('keeps the label but masks the value of api_key=/token= pairs',
        () {
      final String out = CrashReportEntry.redact(
          'GET /v1/x?api_key=supersecret123&id=1');
      expect(out, contains('api_key='));
      expect(out, contains('[REDACTED]'));
      expect(out, isNot(contains('supersecret123')));

      expect(CrashReportEntry.redact('token = myTokenValue42'),
          isNot(contains('myTokenValue42')));
    });

    test('leaves ordinary text untouched', () {
      const String plain = 'FormatException: bad state (no element)';
      expect(CrashReportEntry.redact(plain), plain);
    });
  });

  group('CrashReportEntry summarise & cap', () {
    test('summarize flattens newlines and caps at 300 chars', () {
      final String out = CrashReportEntry.summarize(
          StateError('line1\nline2\nsk-abcdef1234567890'));
      expect(out, contains('⏎'));
      expect(out, contains('[REDACTED]'));
      expect(out.length, lessThanOrEqualTo(301));
    });

    test('stackToString caps at 2000 chars', () {
      final String out = CrashReportEntry.stackToString(
          StackTrace.fromString('frame x\n' * 400));
      expect(out.length, lessThanOrEqualTo(2001));
      expect(out.endsWith('…'), isTrue);
    });

    test('JSON round-trip preserves every field', () {
      final CrashReportEntry original = _entry(
        id: 'x-9',
        source: 'platform',
        stackTrace: '#0 main\n#1 run',
        occurredAt: DateTime.utc(2026, 5, 6, 7, 8, 9),
      );

      final CrashReportEntry? decoded =
          CrashReportEntry.fromJsonMap(original.toJsonMap());
      expect(decoded, isNotNull);
      expect(decoded!.id, original.id);
      expect(decoded.source, original.source);
      expect(decoded.message, original.message);
      expect(decoded.stackTrace, original.stackTrace);
      expect(decoded.appVersion, original.appVersion);
      expect(decoded.platform, original.platform);
      expect(decoded.locale, original.locale);
      expect(decoded.occurredAt, original.occurredAt);
    });

    test('malformed frames decode to null instead of throwing', () {
      expect(CrashReportEntry.fromJsonMap(null), isNull);
      expect(CrashReportEntry.fromJsonMap('nope'), isNull);
      expect(CrashReportEntry.fromJsonMap(<String, Object?>{}), isNull);
      expect(
        CrashReportEntry.fromJsonMap(<String, Object?>{
          'id': 'a', 'source': 'flutter', 'message': 'm',
          'stackTrace': '', 'appVersion': '1', 'platform': 'android',
          'locale': 'zh', 'occurredAt': 'not-a-date',
        }),
        isNull,
      );
    });
  });

  group('CrashReportNotifier', () {
    test('mirrors the service snapshot through record and clearAll',
        () async {
      final ProviderContainer container =
          ProviderContainer(overrides: <Override>[
        crashReportServiceProvider
            .overrideWithValue(CrashReportService(hive: hive)),
      ]);
      addTearDown(container.dispose);

      final CrashReportNotifier notifier =
          container.read(crashReportNotifierProvider.notifier);
      await notifier.record(_entry(id: 'n1'));
      expect(container.read(crashReportNotifierProvider).single.id, 'n1');

      await notifier.clearAll();
      expect(container.read(crashReportNotifierProvider), isEmpty);
    });
  });

  // Ensure the audit import stays referenced (exporter dependency sanity).
  test('audit log and crash service keys do not collide', () {
    expect(AppConstants.hiveKeyCrashReports,
        isNot(AppConstants.hiveKeyCommandAuditLog));
    expect(CommandAuditLog, isNotNull);
  });
}
