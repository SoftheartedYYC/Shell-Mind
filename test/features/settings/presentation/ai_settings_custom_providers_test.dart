import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shell_mind/core/constants/app_constants.dart';
import 'package:shell_mind/core/storage/hive_storage_service.dart';
import 'package:shell_mind/core/storage/preferences_service.dart';
import 'package:shell_mind/core/storage/secure_storage_service.dart';
import 'package:shell_mind/features/ai_chat/data/custom_ai_provider_store.dart';
import 'package:shell_mind/features/ai_chat/domain/entities/ai_provider.dart';
import 'package:shell_mind/features/ai_chat/presentation/providers/chat_providers.dart';
import 'package:shell_mind/features/settings/presentation/providers/ai_settings_provider.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

/// Test-friendly [HiveStorageService] backed by a pre-initialised Hive
/// (temp dir) — avoids the path_provider dependency of the real init().
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
    if (Hive.isBoxOpen(name)) await Hive.box<dynamic>(name).close();
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
  Future<void> delete(String boxName, String key) =>
      box(boxName).delete(key);

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
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSecureStorageService mockSecure;
  late Directory tempDir;
  late CustomAiProviderStore store;

  setUpAll(() {
    // getProviderApiKey/deleteProviderApiKey are stubbed per test; fall back
    // to null reads so unconfigured probes succeed silently.
    registerFallbackValue(<String>[]);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PreferencesService.instance.init();

    mockSecure = MockSecureStorageService();
    when(() => mockSecure.getProviderApiKey(any()))
        .thenAnswer((_) async => null);
    when(() => mockSecure.deleteProviderApiKey(any()))
        .thenAnswer((_) async {});

    // Real Hive instance pointed at a temp dir so the store round-trips.
    tempDir = await Directory.systemTemp.createTemp('ai_provider_test_');
    Hive.init(tempDir.path);
    await Hive.openBox<dynamic>(AppConstants.hiveBoxMeta);
    store = CustomAiProviderStore(hive: _TestHiveStorageService());
    await store.preload();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  ProviderContainer createContainer({
    List<CustomAiProvider> providers = const <CustomAiProvider>[],
  }) {
    return ProviderContainer(
      overrides: <Override>[
        preferencesServiceProvider
            .overrideWithValue(PreferencesService.instance),
        secureStorageServiceProvider.overrideWithValue(mockSecure),
        customAiProviderStoreProvider.overrideWithValue(store),
      ],
    );
  }

  group('addCustomProvider', () {
    test('persists the provider, selects it and mirrors it in providers',
        () async {
      final ProviderContainer container = createContainer();
      addTearDown(container.dispose);
      await container.read(aiSettingsProvider.notifier).addCustomProvider(
            name: 'SiliconFlow',
            baseUrl: 'https://api.siliconflow.cn/v1',
            defaultModelId: 'deepseek-ai/DeepSeek-V3',
          );

      expect(store.all, hasLength(1));
      final CustomAiProvider saved = store.all.single;
      expect(saved.name, 'SiliconFlow');
      expect(saved.baseUrl, 'https://api.siliconflow.cn/v1');
      expect(saved.defaultModelId, 'deepseek-ai/DeepSeek-V3');

      // Selected in preferences and resolved by the chat-side provider.
      expect(PreferencesService.instance.selectedProviderId, saved.id);
      final AiProvider selected = container.read(selectedProviderProvider);
      expect(selected.id, saved.id);
      expect(selected.name, 'SiliconFlow');
      expect(selected.isCustom, isTrue);
      expect(selected.baseUrl, 'https://api.siliconflow.cn/v1');
      expect(selected.defaultModel.id, 'deepseek-ai/DeepSeek-V3');

      // Settings state follows the selection; no key probed for the fresh
      // provider yet, so it isn't in the configured set.
      final AiSettingsState s = container.read(aiSettingsProvider);
      expect(s.effectiveProvider.id, saved.id);
      expect(s.configuredProviderIds, isNot(contains(saved.id)));
    });

    test('trims inputs and drops a blank default model', () async {
      final ProviderContainer container = createContainer();
      addTearDown(container.dispose);
      await container.read(aiSettingsProvider.notifier).addCustomProvider(
            name: '  My Provider  ',
            baseUrl: ' https://api.example.com/v1 ',
            defaultModelId: '   ',
          );

      expect(store.all.single.name, 'My Provider');
      expect(store.all.single.baseUrl, 'https://api.example.com/v1');
      expect(store.all.single.defaultModelId, isNull);
    });

    test('rejects blank names and URLs', () async {
      final ProviderContainer container = createContainer();
      addTearDown(container.dispose);

      expect(
        await container.read(aiSettingsProvider.notifier).addCustomProvider(
              name: '   ',
              baseUrl: 'https://api.example.com/v1',
            ),
        isNull,
      );
      expect(
        await container.read(aiSettingsProvider.notifier).addCustomProvider(
              name: 'Blank URL',
              baseUrl: '   ',
            ),
        isNull,
      );
      // Early-returning controller calls leave the notifier's initial _load()
      // (fired from build) still draining microtasks; flush the event loop so
      // it finishes before addTearDown disposes the container.
      await Future<void>.delayed(Duration.zero);
      expect(store.all, isEmpty);
    });

    test('rejects non-http(s) base URLs', () async {
      final ProviderContainer container = createContainer();
      addTearDown(container.dispose);

      expect(
        await container.read(aiSettingsProvider.notifier).addCustomProvider(
              name: 'Ftp',
              baseUrl: 'ftp://api.example.com',
            ),
        isNull,
      );
      // Flush pending microtasks so the notifier's initial _load() finishes
      // before the container is disposed.
      await Future<void>.delayed(Duration.zero);
      expect(store.all, isEmpty);
    });

    test('rejects duplicate names case-insensitively', () async {
      final ProviderContainer container = createContainer();
      addTearDown(container.dispose);
      final AiSettingsController controller =
          container.read(aiSettingsProvider.notifier);

      expect(
        await controller.addCustomProvider(
            name: 'SiliconFlow', baseUrl: 'https://a.example.com/v1'),
        isNotNull,
      );
      expect(
        await controller.addCustomProvider(
            name: 'siliconflow', baseUrl: 'https://b.example.com/v1'),
        isNull,
      );
      expect(store.all, hasLength(1));
    });
  });

  group('deleteCustomProvider', () {
    test('removes the provider, its key and selection state', () async {
      final ProviderContainer container = createContainer();
      addTearDown(container.dispose);
      final AiSettingsController controller =
          container.read(aiSettingsProvider.notifier);

      final String? id = await controller.addCustomProvider(
          name: 'Gone', baseUrl: 'https://api.gone.example/v1');
      expect(id, isNotNull);
      expect(store.all, hasLength(1));

      await controller.deleteCustomProvider(id!);

      expect(store.all, isEmpty);
      verify(() => mockSecure.deleteProviderApiKey(id)).called(1);
      // Selection falls back to the default built-in.
      expect(
        PreferencesService.instance.selectedProviderId,
        AppConstants.defaultAiProviderId,
      );
      expect(container.read(selectedProviderProvider).id,
          AppConstants.defaultAiProviderId);
      expect(container.read(aiSettingsProvider).effectiveProvider.id,
          AppConstants.defaultAiProviderId);
    });

    test('deleting a non-selected provider keeps the current selection',
        () async {
      final ProviderContainer container = createContainer();
      addTearDown(container.dispose);
      final AiSettingsController controller =
          container.read(aiSettingsProvider.notifier);

      final String? first = await controller.addCustomProvider(
          name: 'One', baseUrl: 'https://one.example.com/v1');
      await controller.addCustomProvider(
          name: 'Two', baseUrl: 'https://two.example.com/v1');

      // Select the second one, then delete the first.
      await controller.selectProvider(store.all[1].id);
      final String secondId = store.all[1].id;
      await controller.deleteCustomProvider(first!);

      expect(store.all, hasLength(1));
      expect(container.read(aiSettingsProvider).effectiveProvider.id,
          secondId);
    });

    test('ignores built-in ids and unknown ids', () async {
      final ProviderContainer container = createContainer();
      addTearDown(container.dispose);
      final AiSettingsController controller =
          container.read(aiSettingsProvider.notifier);

      await controller.deleteCustomProvider('openai');
      await controller.deleteCustomProvider('custom_999');
      verifyNever(() => mockSecure.deleteProviderApiKey(any()));
      // Flush pending microtasks so the notifier's initial _load() finishes
      // before the container is disposed.
      await Future<void>.delayed(Duration.zero);
      expect(store.all, isEmpty);
    });

    test('purges the remembered model and custom model list', () async {
      final ProviderContainer container = createContainer();
      addTearDown(container.dispose);
      final AiSettingsController controller =
          container.read(aiSettingsProvider.notifier);
      final PreferencesService prefs = PreferencesService.instance;

      final String? id = await controller.addCustomProvider(
          name: 'Wipe', baseUrl: 'https://wipe.example.com/v1');
      await prefs.setSelectedModel(id!, 'some-model');
      await prefs.setCustomModels(id, <String>['m1', 'm2']);

      await controller.deleteCustomProvider(id);

      expect(prefs.getSelectedModel(id), isNull);
      expect(prefs.getCustomModels(id), isEmpty);
    });
  });

  group('selectedProviderProvider with custom providers', () {
    test('resolves a stored custom provider id across restarts', () async {
      // Seed the store as if persisted from a previous session.
      await store.add(const CustomAiProvider(
        id: 'custom_42',
        name: 'Relay',
        baseUrl: 'https://relay.example.com/v1',
      ));
      PreferencesService.instance.setSelectedProviderId('custom_42');

      final ProviderContainer container = createContainer();
      addTearDown(container.dispose);

      final AiProvider resolved = container.read(selectedProviderProvider);
      expect(resolved.id, 'custom_42');
      expect(resolved.name, 'Relay');
      expect(resolved.isCustom, isTrue);
    });

    test('falls back to the default when a custom provider was deleted',
        () async {
      // Preference points at a provider that no longer exists in the store.
      PreferencesService.instance.setSelectedProviderId('custom_404');

      final ProviderContainer container = createContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedProviderProvider).id,
          AppConstants.defaultAiProviderId);
    });
  });
}
