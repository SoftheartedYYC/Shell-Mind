import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shell_mind/core/constants/app_constants.dart';
import 'package:shell_mind/core/network/dio_client.dart';
import 'package:shell_mind/core/utils/result.dart';
import 'package:shell_mind/features/ai_chat/data/ai_service.dart';
import 'package:shell_mind/features/ai_chat/domain/entities/ai_provider.dart';

class MockDioClient extends Mock implements DioClient {}

void main() {
  late MockDioClient mockClient;
  late AiService service;

  setUpAll(() {
    registerFallbackValue(Options());
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(CancelToken());
  });

  AiService buildService({
    AiProvider provider = AiProviders.openai,
    String apiKey = 'sk-test-key',
    String model = 'gpt-4o-mini',
    double temperature = 0.7,
  }) =>
      AiService(
        client: mockClient,
        provider: provider,
        apiKey: apiKey,
        model: model,
        temperature: temperature,
      );

  setUp(() {
    mockClient = MockDioClient();
    service = buildService();
  });

  group('AiService.chatStream - auth errors', () {
    test('emits AiServiceException when API key is empty', () async {
      service = buildService(apiKey: '   ');
      await expectLater(
        service.chatStream([
          {'role': 'user', 'content': 'hello'}
        ]),
        emitsError(
          isA<AiServiceException>().having(
            (AiServiceException e) => e.failure.kind,
            'kind',
            FailureKind.auth,
          ),
        ),
      );
    });
  });

  group('AiService.chatStream - request construction', () {
    test('constructs correct URL for the injected provider', () async {
      when(() => mockClient.postStream(
            any(),
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.cancel,
          ));

      await service
          .chatStream([
            {'role': 'user', 'content': 'test'}
          ])
          .drain()
          .catchError((Object _) {});

      final captured = verify(() => mockClient.postStream(
            captureAny(),
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
            options: any(named: 'options'),
          )).captured;
      expect(
        captured.first,
        '${AiProviders.openai.baseUrl}${AppConstants.aiChatCompletionsPath}',
      );
    });

    test('targets the DeepSeek endpoint when that provider is selected', () async {
      service = buildService(
        provider: AiProviders.deepseek,
        apiKey: 'ds-key',
        model: 'deepseek-chat',
      );
      when(() => mockClient.postStream(
            any(),
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.cancel,
          ));

      await service
          .chatStream([
            {'role': 'user', 'content': 'test'}
          ])
          .drain()
          .catchError((Object _) {});

      final captured = verify(() => mockClient.postStream(
            captureAny(),
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
            options: any(named: 'options'),
          )).captured;
      expect(
        captured.first,
        'https://api.deepseek.com/v1${AppConstants.aiChatCompletionsPath}',
      );
    });

    test('sends correct payload with model and temperature', () async {
      when(() => mockClient.postStream(
            any(),
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.cancel,
          ));

      await service
          .chatStream([
            {'role': 'user', 'content': 'hello'}
          ])
          .drain()
          .catchError((Object _) {});

      final captured = verify(() => mockClient.postStream(
            any(),
            data: captureAny(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
            options: any(named: 'options'),
          )).captured;

      final payload = captured.first as Map<String, dynamic>;
      expect(payload['model'], 'gpt-4o-mini');
      expect(payload['temperature'], 0.7);
      expect(payload['stream'], isTrue);
      expect(payload['messages'], isA<List>());
    });

    test('includes Authorization header', () async {
      when(() => mockClient.postStream(
            any(),
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.cancel,
          ));

      await service
          .chatStream([
            {'role': 'user', 'content': 'hi'}
          ])
          .drain()
          .catchError((Object _) {});

      final captured = verify(() => mockClient.postStream(
            any(),
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
            options: captureAny(named: 'options'),
          )).captured;

      final options = captured.first as Options;
      expect(options.headers!['Authorization'], 'Bearer sk-test-key');
    });
  });

  group('AiService.chatStream - error mapping', () {
    void stubStreamThrow(DioException error) {
      when(() => mockClient.postStream(
            any(),
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
            options: any(named: 'options'),
          )).thenThrow(error);
    }

    test('maps connectionError DioException to network failure', () async {
      stubStreamThrow(DioException(
        requestOptions: RequestOptions(path: '/chat/completions'),
        type: DioExceptionType.connectionError,
      ));

      await expectLater(
        service.chatStream([
          {'role': 'user', 'content': 'hi'}
        ]),
        emitsError(isA<AiServiceException>().having(
          (AiServiceException e) => e.failure.kind,
          'kind',
          FailureKind.network,
        )),
      );
    });

    test('maps 401 DioException to auth failure', () async {
      stubStreamThrow(DioException(
        requestOptions: RequestOptions(path: '/chat/completions'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 401,
          data: {
            'error': {'message': 'Invalid key'}
          },
        ),
      ));

      await expectLater(
        service.chatStream([
          {'role': 'user', 'content': 'hi'}
        ]),
        emitsError(isA<AiServiceException>().having(
          (AiServiceException e) => e.failure.kind,
          'kind',
          FailureKind.auth,
        )),
      );
    });

    test('maps 429 DioException to aiProvider failure', () async {
      stubStreamThrow(DioException(
        requestOptions: RequestOptions(path: '/chat/completions'),
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: RequestOptions(path: ''), statusCode: 429),
      ));

      await expectLater(
        service.chatStream([
          {'role': 'user', 'content': 'hi'}
        ]),
        emitsError(isA<AiServiceException>().having(
          (AiServiceException e) => e.failure.kind,
          'kind',
          FailureKind.aiProvider,
        )),
      );
    });

    test('maps timeout DioException to timeout failure', () async {
      stubStreamThrow(DioException(
        requestOptions: RequestOptions(path: '/chat/completions'),
        type: DioExceptionType.connectionTimeout,
      ));

      await expectLater(
        service.chatStream([
          {'role': 'user', 'content': 'hi'}
        ]),
        emitsError(isA<AiServiceException>().having(
          (AiServiceException e) => e.failure.kind,
          'kind',
          FailureKind.timeout,
        )),
      );
    });

    test('maps cancel DioException to cancelled failure', () async {
      stubStreamThrow(DioException(
        requestOptions: RequestOptions(path: '/chat/completions'),
        type: DioExceptionType.cancel,
      ));

      await expectLater(
        service.chatStream([
          {'role': 'user', 'content': 'hi'}
        ]),
        emitsError(isA<AiServiceException>().having(
          (AiServiceException e) => e.failure.kind,
          'kind',
          FailureKind.cancelled,
        )),
      );
    });

    test('maps 500 DioException to recoverable aiProvider failure', () async {
      stubStreamThrow(DioException(
        requestOptions: RequestOptions(path: '/chat/completions'),
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: RequestOptions(path: ''), statusCode: 500),
      ));

      await expectLater(
        service.chatStream([
          {'role': 'user', 'content': 'hi'}
        ]),
        emitsError(isA<AiServiceException>()
            .having((AiServiceException e) => e.failure.kind, 'kind',
                FailureKind.aiProvider)
            .having((AiServiceException e) => e.failure.recoverable, 'recoverable',
                isTrue)),
      );
    });

    test('emits error on null response body', () async {
      when(() => mockClient.postStream(
            any(),
            data: any(named: 'data'),
            cancelToken: any(named: 'cancelToken'),
            options: any(named: 'options'),
          )).thenAnswer((_) async => Response<ResponseBody>(
            requestOptions: RequestOptions(path: ''),
            data: null,
            statusCode: 200,
          ));

      await expectLater(
        service.chatStream([
          {'role': 'user', 'content': 'hi'}
        ]),
        emitsError(isA<AiServiceException>().having(
          (AiServiceException e) => e.failure.kind,
          'kind',
          FailureKind.aiProvider,
        )),
      );
    });

    test('extracts server error message from response body', () async {
      stubStreamThrow(DioException(
        requestOptions: RequestOptions(path: '/chat/completions'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 401,
          data: {
            'error': {'message': 'Incorrect API key provided'}
          },
        ),
      ));

      await expectLater(
        service.chatStream([
          {'role': 'user', 'content': 'hi'}
        ]),
        emitsError(isA<AiServiceException>().having(
          (AiServiceException e) => e.failure.message,
          'message',
          'Incorrect API key provided',
        )),
      );
    });
  });

  group('AiService.chat (non-streaming)', () {
    void stubPost(Object? data) {
      when(() => mockClient.post<dynamic>(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => Response<dynamic>(
            requestOptions: RequestOptions(path: ''),
            data: data,
            statusCode: 200,
          ));
    }

    test('throws when API key is missing', () async {
      service = buildService(apiKey: '');
      expect(
        () => service.chat([
          {'role': 'user', 'content': 'hello'}
        ]),
        throwsA(isA<AiServiceException>()),
      );
    });

    test('returns content from response (message format)', () async {
      stubPost({
        'choices': [
          {
            'message': {'content': 'Complete response'}
          }
        ],
      });

      final result = await service.chat([
        {'role': 'user', 'content': 'hi'}
      ]);
      expect(result, 'Complete response');
    });

    test('returns content from response (delta format)', () async {
      stubPost({
        'choices': [
          {
            'delta': {'content': 'Delta response'}
          }
        ],
      });

      final result = await service.chat([
        {'role': 'user', 'content': 'hi'}
      ]);
      expect(result, 'Delta response');
    });

    test('returns empty string when choices is empty', () async {
      stubPost({'choices': []});

      final result = await service.chat([
        {'role': 'user', 'content': 'hi'}
      ]);
      expect(result, '');
    });

    test('throws on non-map response data', () async {
      stubPost('not a map');

      expect(
        () => service.chat([
          {'role': 'user', 'content': 'hi'}
        ]),
        throwsA(isA<AiServiceException>()),
      );
    });

    test('sends stream: false in payload', () async {
      stubPost({
        'choices': [
          {
            'message': {'content': 'x'}
          }
        ]
      });

      await service.chat([
        {'role': 'user', 'content': 'hi'}
      ]);

      final captured = verify(() => mockClient.post<dynamic>(
            any(),
            data: captureAny(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).captured;

      final payload = captured.first as Map<String, dynamic>;
      expect(payload['stream'], isFalse);
      expect(payload['model'], 'gpt-4o-mini');
    });

    test('maps DioException to AiServiceException', () async {
      when(() => mockClient.post<dynamic>(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenThrow(DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: ''),
              statusCode: 503,
              data: {
                'error': {'message': 'Service unavailable'}
              },
            ),
          ));

      expect(
        () => service.chat([
          {'role': 'user', 'content': 'hi'}
        ]),
        throwsA(isA<AiServiceException>().having(
          (AiServiceException e) => e.failure.kind,
          'kind',
          FailureKind.aiProvider,
        )),
      );
    });

    test('includes Authorization header in non-streaming request', () async {
      stubPost({
        'choices': [
          {
            'message': {'content': 'ok'}
          }
        ]
      });

      await service.chat([
        {'role': 'user', 'content': 'hi'}
      ]);

      final captured = verify(() => mockClient.post<dynamic>(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: captureAny(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).captured;

      final options = captured.first as Options;
      expect(options.headers!['Authorization'], 'Bearer sk-test-key');
    });
  });

  group('AiProviders registry', () {
    test('getById resolves known providers and falls back to openai', () {
      expect(AiProviders.getById('deepseek'), AiProviders.deepseek);
      expect(AiProviders.getById('qwen'), AiProviders.qwen);
      expect(AiProviders.getById('glm'), AiProviders.glm);
      expect(AiProviders.getById('mimo'), AiProviders.mimo);
      expect(AiProviders.getById('unknown'), AiProviders.openai);
    });

    test('every provider has at least one model and a default', () {
      for (final AiProvider p in AiProviders.all) {
        expect(p.models, isNotEmpty);
        expect(p.defaultModel, p.models.first);
        expect(p.modelById('does-not-exist'), p.defaultModel);
      }
    });
  });

  group('AiServiceException', () {
    test('carries failure and has readable toString', () {
      final failure = AppFailure.auth(message: 'Key expired');
      final ex = AiServiceException(failure);
      expect(ex.failure, same(failure));
      expect(ex.toString(), contains('Key expired'));
    });
  });
}
