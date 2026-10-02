import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shell_mind/core/network/dio_client.dart';
import 'package:shell_mind/core/storage/preferences_service.dart';
import 'package:shell_mind/core/utils/result.dart';
import 'package:shell_mind/features/ai_chat/data/ai_service.dart';
import 'package:shell_mind/features/ai_chat/domain/entities/ai_provider.dart';
import 'package:shell_mind/features/ai_chat/domain/entities/chat_message.dart';
import 'package:shell_mind/features/ai_chat/presentation/providers/chat_providers.dart';
import 'package:shell_mind/features/server_config/domain/entities/server_config.dart';
import 'package:shell_mind/features/ssh_terminal/data/ssh_client_manager.dart';
import 'package:shell_mind/shared/ssh/ssh_session_registry.dart';

/// A [HttpClientAdapter] that never touches the network. It hands back a
/// caller-supplied [ResponseBody] (or throws), letting the test drive the
/// real Dio -> AiService -> ChatRepositoryImpl -> ChatNotifier chain.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions options) _handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      _handler(options);
}

ResponseBody _sseBody(String sse) => ResponseBody(
      Stream<Uint8List>.fromIterable(<Uint8List>[utf8.encode(sse)]),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['text/event-stream'],
      },
    );

/// Decodes the outgoing request body regardless of whether Dio's transformer
/// already serialised it to a String/bytes.
Map<String, dynamic> _decodeRequest(RequestOptions o) {
  final Object? data = o.data;
  try {
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      final Object? d = jsonDecode(data);
      return d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};
    }
    if (data is Uint8List) {
      final Object? d = jsonDecode(utf8.decode(data));
      return d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};
    }
  } catch (_) {
    return <String, dynamic>{};
  }
  return <String, dynamic>{};
}

/// Integration test that exercises the REAL chat send path end-to-end:
///
///   chatMessagesProvider (ChatNotifier.sendMessage)
///     -> chatRepositoryProvider (real ChatRepositoryImpl + activeServersGetter)
///       -> _buildMessages / _buildSystemPrompt
///       -> aiServiceProvider (real AiService)
///         -> real Dio (fake transport adapter)
///
/// Unlike `chat_providers_test.dart` (which overrides `chatRepositoryProvider`
/// with a mock), the whole wire path is real, so any raw exception that would
/// surface to the user as "UNEXPECTED Unexpected error" is reproduced here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  const AiProvider testProvider = AiProvider(
    id: 'test',
    name: 'Test',
    baseUrl: 'http://test.local/v1',
    models: <AiModel>[AiModel(id: 'test-model', name: 'Test Model')],
  );

  /// Builds a container whose Dio uses [adapter] as its transport.
  ProviderContainer buildContainer(HttpClientAdapter adapter) {
    final Dio dio = Dio()..httpClientAdapter = adapter;
    return ProviderContainer(
      overrides: <Override>[
        dioProvider.overrideWithValue(dio),
        selectedProviderProvider.overrideWithValue(testProvider),
        apiKeyProvider.overrideWith((Ref ref) async => 'test-key'),
      ],
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PreferencesService.instance.init();
  });

  tearDown(() => container.dispose());

  /// Waits until the notifier stops streaming (or [timeout] elapses).
  Future<void> waitIdle(
    ProviderContainer c, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final DateTime deadline = DateTime.now().add(timeout);
    while (c.read(chatMessagesProvider).isStreaming &&
        DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  test('happy path: streams deltas into the assistant message, no failure',
      () async {
    container = buildContainer(
      _FakeAdapter((RequestOptions o) async => _sseBody(
            'data: {"choices":[{"delta":{"content":"Hello"}}]}\n\n'
            'data: {"choices":[{"delta":{"content":" World"}}]}\n\n'
            'data: [DONE]\n\n',
          )),
    );
    await container.read(apiKeyProvider.future);

    await container.read(chatMessagesProvider.notifier).sendMessage('hello');
    await waitIdle(container);

    final ChatState state = container.read(chatMessagesProvider);
    if (state.failure != null) {
      // ignore: avoid_print
      print('CAUSE: ${state.failure!.cause}\nSTACK: ${state.failure!.stackTrace}');
    }
    expect(state.failure, isNull, reason: 'happy path must not fail');
    expect(state.isStreaming, isFalse);
    final List<ChatMessage> assistant = state.messages
        .where((ChatMessage m) => m.role == MessageRole.assistant)
        .toList();
    expect(assistant, isNotEmpty);
    expect(assistant.last.content, 'Hello World');
  });

  test('system prompt carries the connected-server roster from the registry',
      () async {
    String? capturedSystem;
    container = buildContainer(
      _FakeAdapter((RequestOptions o) async {
        final Map<String, dynamic> body = _decodeRequest(o);
        final List<dynamic> messages =
            (body['messages'] as List<dynamic>?) ?? const <dynamic>[];
        for (final dynamic m in messages) {
          if (m is Map && m['role'] == 'system') {
            capturedSystem = m['content'] as String?;
          }
        }
        return _sseBody(
          'data: {"choices":[{"delta":{"content":"ok"}}]}\n\ndata: [DONE]\n\n',
        );
      }),
    );
    await container.read(apiKeyProvider.future);

    // Register a live session so the getter has something to report.
    final SshClientManager manager = SshClientManager();
    addTearDown(manager.dispose);
    final ServerConfig cfg = ServerConfig(
      id: 'srv-1',
      name: 'prod-web',
      host: '10.0.0.5',
      port: 22,
      username: 'root',
      createdAt: DateTime(2024),
    );
    container
        .read(sshSessionRegistryProvider.notifier)
        .register('srv-1', manager, cfg);

    await container.read(chatMessagesProvider.notifier).sendMessage('hi');
    await waitIdle(container);

    expect(container.read(chatMessagesProvider).failure, isNull);
    expect(capturedSystem, isNotNull);
    expect(capturedSystem, contains('prod-web'));
    expect(capturedSystem, contains('root@10.0.0.5:22'));
  });

  test('mid-stream SocketException is categorised as network, not UNEXPECTED',
      () async {
    container = buildContainer(
      _FakeAdapter((RequestOptions o) async {
        final StreamController<Uint8List> ctrl = StreamController<Uint8List>();
        ctrl.add(utf8.encode('data: {"choices":[{"delta":{"content":"par"}}]}\n\n'));
        ctrl.addError(const SocketException('connection reset by peer'));
        unawaited(ctrl.close());
        return ResponseBody(
          ctrl.stream,
          200,
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>['text/event-stream'],
          },
        );
      }),
    );
    await container.read(apiKeyProvider.future);

    await container.read(chatMessagesProvider.notifier).sendMessage('hi');
    await waitIdle(container);

    final ChatState state = container.read(chatMessagesProvider);
    expect(state.failure, isNotNull);
    expect(state.failure!.kind, isNot(FailureKind.unexpected),
        reason: 'a SocketException must be categorised as network');
    expect(state.failure!.kind, FailureKind.network);
  });

  test('transport error opening the stream is categorised, not UNEXPECTED',
      () async {
    container = buildContainer(
      _FakeAdapter((RequestOptions o) async {
        throw const SocketException('no route to host');
      }),
    );
    await container.read(apiKeyProvider.future);

    await container.read(chatMessagesProvider.notifier).sendMessage('hi');
    await waitIdle(container);

    final ChatState state = container.read(chatMessagesProvider);
    expect(state.failure, isNotNull);
    expect(state.failure!.kind, isNot(FailureKind.unexpected),
        reason: 'raw transport errors must be categorised');
  });

  test('AiServiceException carries its failure for downstream mapping', () {
    expect(
      AiServiceException(AppFailure.auth(message: 'x')).failure.kind,
      FailureKind.auth,
    );
  });
}
