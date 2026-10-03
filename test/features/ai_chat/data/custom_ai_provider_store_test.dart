import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:shell_mind/core/constants/app_constants.dart';
import 'package:shell_mind/core/storage/hive_storage_service.dart';
import 'package:shell_mind/features/ai_chat/data/custom_ai_provider_store.dart';

/// Test-friendly HiveStorageService backed by a pre-initialised Hive in a
/// temp directory (avoids path_provider, mirrors the server-config tests).
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

void main() {
  late Directory tempDir;
  late CustomAiProviderStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('custom_provider_test_');
    Hive.init(tempDir.path);
    await Hive.openBox<dynamic>(AppConstants.hiveBoxMeta);
    store = CustomAiProviderStore(hive: _TestHiveStorageService());
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  CustomAiProvider makeProvider({
    String? id,
    String name = 'SiliconFlow',
    String baseUrl = 'https://api.siliconflow.cn/v1',
    String? model,
  }) =>
      CustomAiProvider(
        id: id ?? store.newProviderId(),
        name: name,
        baseUrl: baseUrl,
        defaultModelId: model,
      );

  group('CustomAiProvider JSON round-trip', () {
    test('toJsonMap/fromJsonMap preserves all fields', () {
      final CustomAiProvider p = makeProvider(model: 'deepseek-chat');
      final CustomAiProvider decoded =
          CustomAiProvider.fromJsonMap(p.toJsonMap())!;

      expect(decoded.id, p.id);
      expect(decoded.name, p.name);
      expect(decoded.baseUrl, p.baseUrl);
      expect(decoded.defaultModelId, 'deepseek-chat');
    });

    test('omits null defaultModelId and restores it as null', () {
      final CustomAiProvider p = makeProvider();
      expect(p.toJsonMap().containsKey('defaultModelId'), isFalse);
      expect(CustomAiProvider.fromJsonMap(p.toJsonMap())!.defaultModelId,
          isNull);
    });

    test('fromJsonMap returns null for malformed frames', () {
      expect(CustomAiProvider.fromJsonMap(null), isNull);
      expect(CustomAiProvider.fromJsonMap('not-a-map'), isNull);
      expect(CustomAiProvider.fromJsonMap(<String, dynamic>{}), isNull);
      expect(
        CustomAiProvider.fromJsonMap(
            <String, dynamic>{'id': 'x', 'name': '', 'baseUrl': 'https://a'}),
        isNull,
      );
      expect(
        CustomAiProvider.fromJsonMap(<String, dynamic>{
          'id': 'x',
          'name': 'n',
          'baseUrl': 42,
        }),
        isNull,
      );
    });
  });

  group('CustomAiProviderStore CRUD', () {
    test('starts empty, add persists and is visible via all/getById',
        () async {
      await store.preload();
      expect(store.all, isEmpty);

      final CustomAiProvider p = makeProvider(model: 'deepseek-chat');
      await store.add(p);

      expect(store.all, hasLength(1));
      expect(store.getById(p.id), p);
      // Persisted as a JSON string in the meta box.
      final Object? raw =
          Hive.box<dynamic>(AppConstants.hiveBoxMeta).get(
        AppConstants.hiveKeyAiCustomProviders,
      );
      expect(raw, isA<String>());
      expect(
        jsonDecode(raw! as String),
        isA<List<dynamic>>().having((List<dynamic> l) => l.length, 'len', 1),
      );
    });

    test('preload re-reads persisted entries from the box', () async {
      await store.add(makeProvider(name: 'A'));
      await store.add(makeProvider(name: 'B'));

      final CustomAiProviderStore fresh = CustomAiProviderStore(
        hive: _TestHiveStorageService(),
      );
      await fresh.preload();

      expect(fresh.all.map((CustomAiProvider p) => p.name),
          <String>['A', 'B']);
    });

    test('update replaces in place and persists', () async {
      final CustomAiProvider p = makeProvider(name: 'A');
      await store.add(p);

      await store.update(
        CustomAiProvider(
          id: p.id,
          name: 'A2',
          baseUrl: p.baseUrl,
          defaultModelId: 'm',
        ),
      );

      expect(store.all, hasLength(1));
      expect(store.getById(p.id)!.name, 'A2');
      expect(store.getById(p.id)!.defaultModelId, 'm');
    });

    test('remove deletes by id and is a no-op for unknown ids', () async {
      final CustomAiProvider p = makeProvider();
      await store.add(p);

      await store.remove('nope');
      expect(store.all, hasLength(1));

      await store.remove(p.id);
      expect(store.all, isEmpty);
      expect(store.getById(p.id), isNull);
    });

    test('add rejects duplicate ids with a StateError', () async {
      final CustomAiProvider p = makeProvider();
      await store.add(p);
      await expectLater(
        store.add(makeProvider(id: p.id, name: 'Clone')),
        throwsStateError,
      );
      expect(store.all, hasLength(1));
    });

    test('newProviderId yields unique sequential custom_ ids', () async {
      await store.preload();
      final String a = store.newProviderId();
      await store.add(makeProvider(id: a));
      final String b = store.newProviderId();

      expect(a, startsWith(AppConstants.customAiProviderIdPrefix));
      expect(b, startsWith(AppConstants.customAiProviderIdPrefix));
      expect(a, isNot(b));
    });

    test('isCustomId only matches the custom_ prefix', () {
      expect(CustomAiProviderStore.isCustomId('custom_1'), isTrue);
      expect(CustomAiProviderStore.isCustomId('custom_'), isTrue);
      expect(CustomAiProviderStore.isCustomId('openai'), isFalse);
      expect(CustomAiProviderStore.isCustomId('deepseek'), isFalse);
    });

    test('corrupt JSON frame degrades to an empty list', () async {
      await Hive.box<dynamic>(AppConstants.hiveBoxMeta)
          .put(AppConstants.hiveKeyAiCustomProviders, '{not json');
      await store.preload();
      expect(store.all, isEmpty);
    });
  });
}
