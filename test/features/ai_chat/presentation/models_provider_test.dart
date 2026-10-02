import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shell_mind/core/network/dio_client.dart';
import 'package:shell_mind/core/storage/preferences_service.dart';
import 'package:shell_mind/features/ai_chat/domain/entities/ai_provider.dart';
import 'package:shell_mind/features/ai_chat/presentation/providers/chat_providers.dart';
import 'package:shell_mind/features/ai_chat/presentation/providers/models_provider.dart';

class MockDioClient extends Mock implements DioClient {}

class MockPreferencesService extends Mock implements PreferencesService {}

void main() {
  late MockDioClient mockClient;
  late MockPreferencesService mockPrefs;

  setUpAll(() {
    registerFallbackValue(Options());
  });

  setUp(() {
    mockClient = MockDioClient();
    mockPrefs = MockPreferencesService();
  });

  ProviderContainer createContainer({
    AiProvider provider = AiProviders.deepseek,
    String? apiKey,
    List<String> custom = const <String>[],
  }) {
    when(() => mockPrefs.getCustomModels(provider.id)).thenReturn(custom);
    return ProviderContainer(
      overrides: <Override>[
        selectedProviderProvider.overrideWithValue(provider),
        preferencesServiceProvider.overrideWithValue(mockPrefs),
        apiKeyProvider.overrideWith((Ref ref) async => apiKey),
        dioClientProvider.overrideWithValue(mockClient),
      ],
    );
  }

  group('mergeAvailableModels', () {
    test('orders fetched first, then remaining built-in, then custom', () {
      final List<AiModel> merged = mergeAvailableModels(
        AiProviders.deepseek,
        <String>['fetched-a', 'deepseek-chat'],
        <String>['custom-x'],
      );
      final List<String> ids =
          merged.map((AiModel m) => m.id).toList(growable: false);
      expect(ids, <String>[
        'fetched-a',
        'deepseek-chat',
        'deepseek-reasoner',
        'custom-x',
      ]);
    });

    test('reuses the built-in AiModel (name/description) for a known id', () {
      final List<AiModel> merged = mergeAvailableModels(
        AiProviders.deepseek,
        <String>['deepseek-chat'],
        const <String>[],
      );
      final AiModel chat =
          merged.firstWhere((AiModel m) => m.id == 'deepseek-chat');
      expect(chat.name, 'DeepSeek Chat');
      expect(chat.description, 'General conversation');
    });

    test('synthesises a bare AiModel for unknown fetched ids', () {
      final List<AiModel> merged = mergeAvailableModels(
        AiProviders.deepseek,
        <String>['brand-new-model'],
        const <String>[],
      );
      final AiModel m =
          merged.firstWhere((AiModel x) => x.id == 'brand-new-model');
      expect(m.name, 'brand-new-model');
      expect(m.description, isNull);
    });

    test('de-duplicates across all three sources', () {
      final List<AiModel> merged = mergeAvailableModels(
        AiProviders.deepseek,
        <String>['deepseek-chat', 'deepseek-chat'],
        <String>['deepseek-chat', 'custom-x', 'custom-x'],
      );
      final List<String> ids =
          merged.map((AiModel m) => m.id).toList(growable: false);
      expect(ids.where((String id) => id == 'deepseek-chat').length, 1);
      expect(ids.where((String id) => id == 'custom-x').length, 1);
    });

    test('falls back to built-in + custom when fetched is empty', () {
      final List<AiModel> merged = mergeAvailableModels(
        AiProviders.deepseek,
        const <String>[],
        <String>['custom-x'],
      );
      final List<String> ids =
          merged.map((AiModel m) => m.id).toList(growable: false);
      expect(ids, <String>[
        'deepseek-chat',
        'deepseek-reasoner',
        'custom-x',
      ]);
    });

    test('ignores blank ids', () {
      final List<AiModel> merged = mergeAvailableModels(
        AiProviders.deepseek,
        <String>['', '   '],
        <String>['  '],
      );
      expect(merged.any((AiModel m) => m.id.trim().isEmpty), isFalse);
    });
  });

  group('CustomModelsController', () {
    test('loads the persisted list for the selected provider', () {
      final ProviderContainer container =
          createContainer(custom: <String>['a', 'b']);
      addTearDown(container.dispose);
      expect(container.read(customModelsProvider), <String>['a', 'b']);
    });

    test('addCustomModel appends, persists and updates state', () async {
      final ProviderContainer container = createContainer(custom: <String>['a']);
      addTearDown(container.dispose);
      when(() => mockPrefs.setCustomModels(any(), any()))
          .thenAnswer((_) async {});

      await container
          .read(customModelsProvider.notifier)
          .addCustomModel('deepseek', 'b');

      verify(() => mockPrefs.setCustomModels('deepseek', <String>['a', 'b']))
          .called(1);
      expect(container.read(customModelsProvider), <String>['a', 'b']);
    });

    test('addCustomModel trims whitespace', () async {
      final ProviderContainer container = createContainer();
      addTearDown(container.dispose);
      when(() => mockPrefs.setCustomModels(any(), any()))
          .thenAnswer((_) async {});

      await container
          .read(customModelsProvider.notifier)
          .addCustomModel('deepseek', '  my-model  ');

      verify(() =>
              mockPrefs.setCustomModels('deepseek', <String>['my-model']))
          .called(1);
    });

    test('addCustomModel ignores duplicates', () async {
      final ProviderContainer container = createContainer(custom: <String>['a']);
      addTearDown(container.dispose);

      await container
          .read(customModelsProvider.notifier)
          .addCustomModel('deepseek', 'a');

      verifyNever(() => mockPrefs.setCustomModels(any(), any()));
      expect(container.read(customModelsProvider), <String>['a']);
    });

    test('addCustomModel ignores blank input', () async {
      final ProviderContainer container = createContainer();
      addTearDown(container.dispose);

      await container
          .read(customModelsProvider.notifier)
          .addCustomModel('deepseek', '   ');

      verifyNever(() => mockPrefs.setCustomModels(any(), any()));
    });

    test('removeCustomModel removes and persists', () async {
      final ProviderContainer container =
          createContainer(custom: <String>['a', 'b']);
      addTearDown(container.dispose);
      when(() => mockPrefs.setCustomModels(any(), any()))
          .thenAnswer((_) async {});

      await container
          .read(customModelsProvider.notifier)
          .removeCustomModel('deepseek', 'a');

      verify(() => mockPrefs.setCustomModels('deepseek', <String>['b']))
          .called(1);
      expect(container.read(customModelsProvider), <String>['b']);
    });

    test('removeCustomModel is a no-op for an unknown id', () async {
      final ProviderContainer container = createContainer(custom: <String>['a']);
      addTearDown(container.dispose);

      await container
          .read(customModelsProvider.notifier)
          .removeCustomModel('deepseek', 'zzz');

      verifyNever(() => mockPrefs.setCustomModels(any(), any()));
    });
  });

  group('availableModelsProvider', () {
    test('without a key falls back to built-in + custom, no error', () async {
      final ProviderContainer container =
          createContainer(apiKey: null, custom: <String>['custom-x']);
      addTearDown(container.dispose);

      final AvailableModelsState state =
          await container.read(availableModelsProvider.future);

      expect(state.fetchError, isNull);
      expect(state.customIds, <String>{'custom-x'});
      expect(
        state.models.map((AiModel m) => m.id),
        containsAllInOrder(<String>[
          'deepseek-chat',
          'deepseek-reasoner',
          'custom-x',
        ]),
      );
      verifyNever(() => mockClient.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          ));
    });

    test('with a key merges the fetched catalogue ahead of built-ins',
        () async {
      when(() => mockClient.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => Response<dynamic>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: {
              'data': <Map<String, dynamic>>[
                <String, dynamic>{'id': 'fetched-1'},
                <String, dynamic>{'id': 'deepseek-chat'},
              ],
            },
          ));

      final ProviderContainer container = createContainer(apiKey: 'sk-key');
      addTearDown(container.dispose);

      final AvailableModelsState state =
          await container.read(availableModelsProvider.future);

      expect(state.fetchError, isNull);
      expect(state.models.first.id, 'fetched-1');
      expect(
        state.models.map((AiModel m) => m.id),
        containsAllInOrder(<String>[
          'fetched-1',
          'deepseek-chat',
          'deepseek-reasoner',
        ]),
      );
    });

    test('a fetch failure surfaces fetchError but keeps the fallback list',
        () async {
      when(() => mockClient.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenThrow(DioException(
            requestOptions: RequestOptions(path: '/models'),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 401,
            ),
          ));

      final ProviderContainer container =
          createContainer(apiKey: 'bad-key', custom: <String>['custom-x']);
      addTearDown(container.dispose);

      final AvailableModelsState state =
          await container.read(availableModelsProvider.future);

      expect(state.fetchError, isNotNull);
      expect(state.models, isNotEmpty);
      expect(
        state.models.map((AiModel m) => m.id),
        containsAllInOrder(<String>[
          'deepseek-chat',
          'deepseek-reasoner',
          'custom-x',
        ]),
      );
    });
  });
}
