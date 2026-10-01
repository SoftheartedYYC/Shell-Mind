import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shell_mind/core/constants/app_constants.dart';
import 'package:shell_mind/core/storage/hive_storage_service.dart';
import 'package:shell_mind/core/storage/secure_storage_service.dart';
import 'package:shell_mind/features/server_config/data/models/server_config_model.dart';
import 'package:shell_mind/features/server_config/data/server_config_repository_impl.dart';
import 'package:shell_mind/features/server_config/domain/entities/server_config.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late Directory tempDir;
  late ServerConfigRepositoryImpl repository;
  late MockFlutterSecureStorage mockSecureStorage;
  late SecureStorageService secureService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(ServerConfigModelAdapter.kTypeId)) {
      Hive.registerAdapter(ServerConfigModelAdapter());
    }
    await Hive.openBox<dynamic>(AppConstants.hiveBoxServers);

    mockSecureStorage = MockFlutterSecureStorage();
    secureService = SecureStorageService(storage: mockSecureStorage);

    // We need to get HiveStorageService to recognise our test Hive as "initialised".
    // Since HiveStorageService.init() calls Hive.initFlutter() which needs path_provider,
    // we'll use a workaround: the _assertInit() checks _initialised flag.
    // For testing, we create a mock-like wrapper that bypasses the init check.
    // Actually, HiveStorageService uses Hive.box() under the hood after init.
    // Since we already opened the box with Hive.init + Hive.openBox,
    // we need to make HiveStorageService think it's initialized.
    // The simplest approach: use reflection or create the repo with a test-friendly hive service.
    // Since we can't modify lib/, let's use a TestHiveStorageService approach.
    // Actually looking at the code, HiveStorageService.init() does:
    //   1. Hive.initFlutter(subDirectory)
    //   2. Opens eager boxes
    //   3. Sets _initialised = true
    // Since we already did Hive.init + Hive.openBox, we just need _initialised = true.
    // We can't easily set private fields. Let's use a different approach:
    // Call init() which will call Hive.initFlutter() - that uses path_provider plugin.
    // In tests, we can set up the path_provider mock.
    // Actually, since we already called Hive.init(tempDir.path), and Hive.initFlutter
    // also calls Hive.init under the hood, calling init() should be safe as Hive.init
    // can be called multiple times. Let's try using the singleton.

    // We work directly with a test-friendly Hive service backed by tempDir,
    // avoiding path_provider (which HiveStorageService.init() would require).
    repository = ServerConfigRepositoryImpl(
      _TestHiveStorageService(),
      secureService,
    );
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  ServerConfig makeConfig({
    String id = 'test-1',
    String name = 'Test Server',
    String host = '192.168.1.1',
    int port = 22,
    String username = 'root',
    AuthType authType = AuthType.password,
    String? group,
  }) {
    return ServerConfig(
      id: id,
      name: name,
      host: host,
      port: port,
      username: username,
      authType: authType,
      group: group,
      createdAt: DateTime(2024, 1, 1),
    );
  }

  group('ServerConfigRepositoryImpl', () {
    test('getAll returns empty list initially', () async {
      final configs = await repository.getAll();
      expect(configs, isEmpty);
    });

    test('save and getAll retrieves the config', () async {
      final config = makeConfig();
      await repository.save(config);

      final configs = await repository.getAll();
      expect(configs.length, 1);
      expect(configs.first.id, 'test-1');
      expect(configs.first.name, 'Test Server');
      expect(configs.first.host, '192.168.1.1');
    });

    test('save and getById retrieves specific config', () async {
      final config = makeConfig(id: 'find-me');
      await repository.save(config);

      final found = await repository.getById('find-me');
      expect(found, isNotNull);
      expect(found!.id, 'find-me');
    });

    test('getById returns null for unknown id', () async {
      final found = await repository.getById('nonexistent');
      expect(found, isNull);
    });

    test('save overwrites existing config with same id', () async {
      final original = makeConfig(id: 'dup', name: 'Original');
      await repository.save(original);

      final updated = makeConfig(id: 'dup', name: 'Updated');
      await repository.save(updated);

      final configs = await repository.getAll();
      expect(configs.length, 1);
      expect(configs.first.name, 'Updated');
    });

    test('delete removes config from storage', () async {
      when(() => mockSecureStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      final config = makeConfig(id: 'del-me');
      await repository.save(config);

      await repository.delete('del-me');

      final found = await repository.getById('del-me');
      expect(found, isNull);
    });

    test('delete purges secure storage credentials', () async {
      when(() => mockSecureStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      final config = makeConfig(id: 'purge-test');
      await repository.save(config);
      await repository.delete('purge-test');

      // purgeServer calls delete for password, privateKey, passphrase
      verify(() => mockSecureStorage.delete(
            key: AppConstants.passwordKey('purge-test'),
          )).called(1);
      verify(() => mockSecureStorage.delete(
            key: AppConstants.privateKeyKey('purge-test'),
          )).called(1);
      verify(() => mockSecureStorage.delete(
            key: AppConstants.passphraseKey('purge-test'),
          )).called(1);
    });

    test('updateLastConnected sets timestamp', () async {
      final config = makeConfig(id: 'lc-test');
      await repository.save(config);

      // Subtract 1ms to account for millisecond truncation in Hive serialization
      final before = DateTime.now().subtract(const Duration(milliseconds: 1));
      await repository.updateLastConnected('lc-test');
      final after = DateTime.now().add(const Duration(milliseconds: 1));

      final updated = await repository.getById('lc-test');
      expect(updated!.lastConnectedAt, isNotNull);
      expect(
        updated.lastConnectedAt!.isAfter(before) ||
            updated.lastConnectedAt!.isAtSameMomentAs(before),
        isTrue,
      );
      expect(
        updated.lastConnectedAt!.isBefore(after) ||
            updated.lastConnectedAt!.isAtSameMomentAs(after),
        isTrue,
      );
    });

    test('updateLastConnected does nothing for unknown id', () async {
      // Should not throw
      await repository.updateLastConnected('nonexistent');
    });

    test('getAll returns configs sorted by display order', () async {
      // Grouped servers come first, then ungrouped; within bucket, alphabetical
      await repository.save(makeConfig(id: '1', name: 'Zebra', group: null));
      await repository.save(makeConfig(id: '2', name: 'Alpha', group: 'prod'));
      await repository.save(makeConfig(id: '3', name: 'Beta', group: null));
      await repository.save(makeConfig(id: '4', name: 'Gamma', group: 'dev'));

      final configs = await repository.getAll();
      expect(configs.length, 4);
      // Grouped first (dev < prod alphabetically), then ungrouped (Beta < Zebra)
      expect(configs[0].name, 'Gamma'); // group: dev
      expect(configs[1].name, 'Alpha'); // group: prod
      expect(configs[2].name, 'Beta'); // no group
      expect(configs[3].name, 'Zebra'); // no group
    });

    test('watchAll emits initial list and updates on change', () async {
      final emissions = <List<ServerConfig>>[];
      final sub = repository.watchAll().listen(emissions.add);

      // Give time for initial emission
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emissions.length, 1);
      expect(emissions.first, isEmpty);

      // Save triggers a new emission
      await repository.save(makeConfig(id: 'stream-test'));
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(emissions.length, greaterThanOrEqualTo(2));
      expect(emissions.last.length, 1);
      expect(emissions.last.first.id, 'stream-test');

      await sub.cancel();
    });
  });
}

/// Test-friendly HiveStorageService that uses a pre-initialized Hive directory.
/// This avoids needing path_provider plugin in unit tests.
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

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
