import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:shell_mind/core/constants/app_constants.dart';
import 'package:shell_mind/core/services/command_audit_log.dart';
import 'package:shell_mind/core/storage/hive_storage_service.dart';

/// Test-friendly HiveStorageService backed by a pre-initialised Hive in a
/// temp directory (avoids path_provider, mirrors the snippet tests).
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

/// Minimal JSON-frame builder covering every [CommandAuditEntry] field.
Map<String, Object?> _frame({
  String id = 'id-1',
  String command = 'echo hi',
  String serverId = 'srv-1',
  String serverName = 'web-1',
  int exitCode = 0,
  bool success = true,
  String mode = 'confirmed',
  String executedAt = '2026-01-02T03:04:05.000Z',
  int elapsedMs = 120,
  bool hasDangerous = false,
  bool hasOutput = true,
  String outputSummary = 'hi',
}) =>
    <String, Object?>{
      'id': id,
      'command': command,
      'serverId': serverId,
      'serverName': serverName,
      'exitCode': exitCode,
      'success': success,
      'mode': mode,
      'executedAt': executedAt,
      'elapsedMs': elapsedMs,
      'hasDangerous': hasDangerous,
      'hasOutput': hasOutput,
      'outputSummary': outputSummary,
    };

CommandAuditEntry _entry({
  String id = 'id-1',
  String command = 'echo hi',
  String serverId = 'srv-1',
  String serverName = 'web-1',
  int exitCode = 0,
  CommandAuditMode mode = CommandAuditMode.confirmed,
  DateTime? executedAt,
  bool hasDangerous = false,
  String outputSummary = 'hi',
}) =>
    CommandAuditEntry(
      id: id,
      command: command,
      serverId: serverId,
      serverName: serverName,
      exitCode: exitCode,
      success: exitCode == 0,
      mode: mode,
      executedAt: executedAt ?? DateTime(2026, 1, 2, 3, 4, 5),
      elapsed: const Duration(milliseconds: 120),
      hasDangerous: hasDangerous,
      hasOutput: outputSummary.isNotEmpty,
      outputSummary: outputSummary,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late _TestHiveStorageService hive;
  late CommandAuditLog log;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('audit_test_');
    Hive.init(tempDir.path);
    await Hive.openBox<dynamic>(AppConstants.hiveBoxMeta);
    hive = _TestHiveStorageService();
    log = CommandAuditLog(hive: hive);
    await log.preload();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(AppConstants.hiveBoxMeta);
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  group('CommandAuditLog.record', () {
    test('appends newest-first and persists as a single JSON key', () async {
      await log.record(_entry(id: 'a', executedAt: DateTime(2026, 1, 1)));
      await log.record(_entry(id: 'b', executedAt: DateTime(2026, 1, 3)));

      expect(log.all.map((CommandAuditEntry e) => e.id).toList(),
          <String>['b', 'a']);

      // Persistence shape: one key in app_meta holding a JSON array whose
      // frames round-trip through CommandAuditEntry.fromJsonMap.
      final Object? raw = hive.get<Object>(
          AppConstants.hiveBoxMeta, AppConstants.hiveKeyCommandAuditLog);
      expect(raw, isA<String>());
      final Object? decoded = jsonDecode(raw! as String);
      expect(decoded, isA<List>());
      final List<Object?> frames = decoded! as List<Object?>;
      expect(frames.length, 2);
      expect(CommandAuditEntry.fromJsonMap(frames.first)?.id, 'b');
    });

    test('evicts oldest entries beyond the 500-entry FIFO cap', () async {
      final DateTime base = DateTime(2026, 1, 1);
      for (int i = 0; i < AppConstants.kMaxCommandAuditEntries + 25; i++) {
        await log.record(_entry(
          id: 'e$i',
          executedAt: base.add(Duration(minutes: i)),
        ));
      }

      expect(log.all.length, AppConstants.kMaxCommandAuditEntries);
      // Newest kept, oldest dropped (e0..e24 evicted, e25..e524 kept).
      expect(log.all.first.id, 'e${AppConstants.kMaxCommandAuditEntries + 24}');
      expect(log.all.last.id, 'e25');

      // And the persisted frame count matches the cap too.
      final Object? raw = hive.get<Object>(
          AppConstants.hiveBoxMeta, AppConstants.hiveKeyCommandAuditLog);
      final List<Object?> frames =
          (jsonDecode(raw! as String) as List<Object?>);
      expect(frames.length, AppConstants.kMaxCommandAuditEntries);
    });
  });

  group('CommandAuditLog.query', () {
    test('filters by serverId, mode and success independently', () async {
      await log.record(_entry(id: 'a',
          serverId: 'srv-1',
          serverName: 'web-1',
          mode: CommandAuditMode.confirmed,
          exitCode: 0));
      await log.record(_entry(id: 'b',
          serverId: 'srv-2',
          serverName: 'db-1',
          mode: CommandAuditMode.auto,
          exitCode: 1));
      await log.record(_entry(id: 'c',
          serverId: 'srv-1',
          serverName: 'web-1',
          mode: CommandAuditMode.auto,
          exitCode: 0,
          hasDangerous: true));

      expect(
          log.query(serverId: 'srv-1').map((CommandAuditEntry e) => e.id),
          <String>['c', 'a']);
      expect(log.query(mode: CommandAuditMode.auto).map((CommandAuditEntry e) => e.id),
          <String>['c', 'b']);
      expect(log.query(success: false).map((CommandAuditEntry e) => e.id),
          <String>['b']);
      expect(
        log.query(serverId: 'srv-1', mode: CommandAuditMode.auto, success: true)
            .map((CommandAuditEntry e) => e.id),
        <String>['c'],
      );
      // No criteria -> everything, newest first.
      expect(log.query().length, 3);
    });
  });

  group('CommandAuditLog.clear', () {
    test('empties the snapshot and removes the persisted key', () async {
      await log.record(_entry(id: 'a'));
      expect(log.all, isNotEmpty);

      await log.clear();

      expect(log.all, isEmpty);
      expect(
        hive.hasKey(AppConstants.hiveBoxMeta,
            AppConstants.hiveKeyCommandAuditLog),
        isFalse,
      );
      // A fresh instance reloaded from the same box sees nothing either.
      final CommandAuditLog reloaded = CommandAuditLog(hive: hive);
      await reloaded.preload();
      expect(reloaded.all, isEmpty);
    });
  });

  group('CommandAuditEntry JSON round-trip', () {
    test('toJsonMap -> fromJsonMap preserves every field', () {
      final CommandAuditEntry original = CommandAuditEntry(
        id: 'x-42',
        command: 'df -h /',
        serverId: 'srv-9',
        serverName: 'edge-7',
        exitCode: 1,
        success: false,
        mode: CommandAuditMode.auto,
        executedAt: DateTime.utc(2026, 3, 4, 5, 6, 7),
        elapsed: const Duration(milliseconds: 2345),
        hasDangerous: true,
        hasOutput: true,
        outputSummary: 'Filesystem … 78%',
      );

      final CommandAuditEntry? decoded =
          CommandAuditEntry.fromJsonMap(original.toJsonMap());

      expect(decoded, isNotNull);
      expect(decoded!.id, original.id);
      expect(decoded.command, original.command);
      expect(decoded.serverId, original.serverId);
      expect(decoded.serverName, original.serverName);
      expect(decoded.exitCode, original.exitCode);
      expect(decoded.success, original.success);
      expect(decoded.mode, original.mode);
      expect(decoded.executedAt, original.executedAt);
      expect(decoded.elapsed, original.elapsed);
      expect(decoded.hasDangerous, original.hasDangerous);
      expect(decoded.hasOutput, original.hasOutput);
      expect(decoded.outputSummary, original.outputSummary);
    });

    test('malformed frames decode to null instead of throwing', () {
      expect(CommandAuditEntry.fromJsonMap(null), isNull);
      expect(CommandAuditEntry.fromJsonMap('not a map'), isNull);
      expect(CommandAuditEntry.fromJsonMap(<String, Object?>{}), isNull);
      expect(
        CommandAuditEntry.fromJsonMap(_frame()..remove('command')),
        isNull,
      );
      expect(
        CommandAuditEntry.fromJsonMap(_frame()..['exitCode'] = 'zero'),
        isNull,
      );
      expect(
        CommandAuditEntry.fromJsonMap(
          _frame(executedAt: 'not-a-timestamp'),
        ),
        isNull,
      );
    });
  });

  group('CommandAuditEntry.summarizeOutput', () {
    test('caps at 200 chars, prefers stdout and flags output presence', () {
      final String long = 'x' * 500;
      final String summary =
          CommandAuditEntry.summarizeOutput(long, 'ignored-stderr');
      expect(summary.length, CommandAuditEntry.outputSummaryMaxLength + 1);
      expect(summary.endsWith('…'), isTrue);
      expect(summary.startsWith('x'), isTrue);

      // Empty stdout falls back to stderr; both empty -> no output.
      expect(CommandAuditEntry.summarizeOutput('', 'err text'), 'err text');
      expect(CommandAuditEntry.summarizeOutput('   ', '  '), isEmpty);
    });
  });

  group('CommandAuditNotifier', () {
    test('mirrors the service snapshot through record and clearAll',
        () async {
      final ProviderContainer container = ProviderContainer(overrides: <Override>[
        commandAuditLogProvider.overrideWithValue(CommandAuditLog(hive: hive)),
      ]);
      addTearDown(container.dispose);

      final CommandAuditNotifier notifier =
          container.read(commandAuditNotifierProvider.notifier);
      await notifier.record(_entry(id: 'n1'));
      expect(container.read(commandAuditNotifierProvider).single.id, 'n1');

      await notifier.clearAll();
      expect(container.read(commandAuditNotifierProvider), isEmpty);
    });
  });
}
