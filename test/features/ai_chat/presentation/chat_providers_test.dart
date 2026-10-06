import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shell_mind/core/utils/result.dart';
import 'package:shell_mind/features/ai_chat/data/ai_service.dart';
import 'package:shell_mind/features/ai_chat/data/chat_history_store.dart';
import 'package:shell_mind/features/ai_chat/domain/entities/chat_message.dart';
import 'package:shell_mind/features/ai_chat/domain/repositories/chat_repository.dart';
import 'package:shell_mind/features/ai_chat/presentation/providers/chat_providers.dart';

class MockChatRepository extends Mock implements ChatRepository {}

class MockChatHistoryStore extends Mock implements ChatHistoryStore {}

void main() {
  late MockChatRepository mockRepo;
  late MockChatHistoryStore mockStore;

  setUp(() {
    mockRepo = MockChatRepository();
    // The notifier persists the transcript on every mutation; these tests only
    // exercise in-memory state, so point it at a silent no-op store instead of
    // the real Hive-backed singleton (which logs noisy "init() must be awaited"
    // errors when run without Hive initialised).
    mockStore = MockChatHistoryStore();
    when(() => mockStore.flush(any())).thenAnswer((_) async {});
    when(() => mockStore.clear()).thenAnswer((_) async {});
    when(() => mockStore.load()).thenAnswer((_) async => <ChatMessage>[]);
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(mockRepo),
        chatHistoryStoreProvider.overrideWithValue(mockStore),
      ],
    );
  }

  group('ChatState', () {
    test('default state has empty messages and is not streaming', () {
      const state = ChatState();
      expect(state.messages, isEmpty);
      expect(state.isStreaming, isFalse);
      expect(state.isConnecting, isFalse);
      expect(state.failure, isNull);
      expect(state.isEmpty, isTrue);
    });

    test('copyWith preserves unchanged fields', () {
      const state = ChatState(isStreaming: true, isConnecting: false);
      final copy = state.copyWith(isConnecting: true);
      expect(copy.isStreaming, isTrue);
      expect(copy.isConnecting, isTrue);
    });

    test('copyWith clearFailure removes failure', () {
      final state = ChatState(failure: AppFailure.auth(message: 'bad'));
      final copy = state.copyWith(clearFailure: true);
      expect(copy.failure, isNull);
    });

    test('equality compares messages and flags', () {
      final msg = ChatMessage.user(id: '1', content: 'hi');
      final a = ChatState(messages: [msg]);
      final b = ChatState(messages: [msg]);
      expect(a, equals(b));
    });

    test('isEmpty returns false with messages', () {
      final msg = ChatMessage.user(id: '1', content: 'hi');
      final state = ChatState(messages: [msg]);
      expect(state.isEmpty, isFalse);
    });
  });

  group('ChatNotifier', () {
    test('initial state is empty ChatState', () {
      final container = createContainer();
      addTearDown(container.dispose);

      final state = container.read(chatMessagesProvider);
      expect(state.messages, isEmpty);
      expect(state.isStreaming, isFalse);
    });

    test('sendMessage adds user and assistant messages', () async {
      final streamController = StreamController<String>();
      when(() => mockRepo.sendMessageStream(
            history: any(named: 'history'),
            userMessage: any(named: 'userMessage'),
          )).thenAnswer((_) => streamController.stream);

      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatMessagesProvider.notifier);
      // Start sending (don't await - it's a long-running operation)
      final future = notifier.sendMessage('Hello AI');

      // Wait for state to update
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(chatMessagesProvider);
      expect(state.messages.length, 2); // user + assistant placeholder
      expect(state.messages[0].role, MessageRole.user);
      expect(state.messages[0].content, 'Hello AI');
      expect(state.messages[1].role, MessageRole.assistant);
      expect(state.messages[1].isStreaming, isTrue);
      expect(state.isStreaming, isTrue);
      expect(state.isConnecting, isTrue);

      // Complete the stream
      await streamController.close();
      await future;
    });

    test('sendMessage ignores empty text', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatMessagesProvider.notifier);
      await notifier.sendMessage('');
      await notifier.sendMessage('   ');

      final state = container.read(chatMessagesProvider);
      expect(state.messages, isEmpty);
    });

    test('streaming deltas update assistant message content', () async {
      final streamController = StreamController<String>();
      when(() => mockRepo.sendMessageStream(
            history: any(named: 'history'),
            userMessage: any(named: 'userMessage'),
          )).thenAnswer((_) => streamController.stream);

      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatMessagesProvider.notifier);
      final future = notifier.sendMessage('test');

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Emit deltas
      streamController.add('Hello');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      var state = container.read(chatMessagesProvider);
      expect(state.messages[1].content, 'Hello');
      expect(state.isConnecting, isFalse); // No longer connecting after first token

      streamController.add(' World');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      state = container.read(chatMessagesProvider);
      expect(state.messages[1].content, 'Hello World');

      await streamController.close();
      await future;

      // After stream completes, isStreaming should be false
      state = container.read(chatMessagesProvider);
      expect(state.isStreaming, isFalse);
      expect(state.messages[1].isStreaming, isFalse);
    });

    test('stream completion with empty content removes placeholder', () async {
      final streamController = StreamController<String>();
      when(() => mockRepo.sendMessageStream(
            history: any(named: 'history'),
            userMessage: any(named: 'userMessage'),
          )).thenAnswer((_) => streamController.stream);

      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatMessagesProvider.notifier);
      final future = notifier.sendMessage('test');

      await Future<void>.delayed(const Duration(milliseconds: 50));
      // Close without emitting anything
      await streamController.close();
      await future;

      final state = container.read(chatMessagesProvider);
      // Only the user message remains; empty assistant placeholder removed
      expect(state.messages.length, 1);
      expect(state.messages[0].role, MessageRole.user);
      expect(state.isStreaming, isFalse);
    });

    test('stream error surfaces failure and marks state', () async {
      final streamController = StreamController<String>();
      when(() => mockRepo.sendMessageStream(
            history: any(named: 'history'),
            userMessage: any(named: 'userMessage'),
          )).thenAnswer((_) => streamController.stream);

      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatMessagesProvider.notifier);
      final future = notifier.sendMessage('test');

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Emit an error
      streamController.addError(
        AiServiceException(AppFailure.aiProvider('Server overloaded', statusCode: 503)),
        StackTrace.current,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await future;

      final state = container.read(chatMessagesProvider);
      expect(state.isStreaming, isFalse);
      expect(state.failure, isNotNull);
      expect(state.failure!.kind, FailureKind.aiProvider);
    });

    test('stream error with partial content keeps the message', () async {
      final streamController = StreamController<String>();
      when(() => mockRepo.sendMessageStream(
            history: any(named: 'history'),
            userMessage: any(named: 'userMessage'),
          )).thenAnswer((_) => streamController.stream);

      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatMessagesProvider.notifier);
      final future = notifier.sendMessage('test');

      await Future<void>.delayed(const Duration(milliseconds: 50));

      streamController.add('partial response');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      streamController.addError(
        AiServiceException(AppFailure.network('timeout')),
        StackTrace.current,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await future;

      final state = container.read(chatMessagesProvider);
      expect(state.messages.length, 2); // user + assistant (kept)
      expect(state.messages[1].content, 'partial response');
      expect(state.messages[1].error, isTrue);
      expect(state.messages[1].isStreaming, isFalse);
      expect(state.failure, isNotNull);
    });

    test('clearChat resets state', () async {
      final streamController = StreamController<String>();
      when(() => mockRepo.sendMessageStream(
            history: any(named: 'history'),
            userMessage: any(named: 'userMessage'),
          )).thenAnswer((_) => streamController.stream);

      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatMessagesProvider.notifier);
      final future = notifier.sendMessage('hello');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      notifier.clearChat();

      final state = container.read(chatMessagesProvider);
      expect(state.messages, isEmpty);
      expect(state.isStreaming, isFalse);
      expect(state.failure, isNull);

      await streamController.close();
      await future;
    });

    test('stopStreaming finishes current message', () async {
      final streamController = StreamController<String>();
      when(() => mockRepo.sendMessageStream(
            history: any(named: 'history'),
            userMessage: any(named: 'userMessage'),
          )).thenAnswer((_) => streamController.stream);

      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatMessagesProvider.notifier);
      final future = notifier.sendMessage('test');

      await Future<void>.delayed(const Duration(milliseconds: 50));

      streamController.add('partial');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      notifier.stopStreaming();

      final state = container.read(chatMessagesProvider);
      expect(state.isStreaming, isFalse);
      expect(state.messages[1].isStreaming, isFalse);
      expect(state.messages[1].content, 'partial');

      await streamController.close();
      await future;
    });

    test('dismissError clears failure', () async {
      final streamController = StreamController<String>();
      when(() => mockRepo.sendMessageStream(
            history: any(named: 'history'),
            userMessage: any(named: 'userMessage'),
          )).thenAnswer((_) => streamController.stream);

      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatMessagesProvider.notifier);
      final future = notifier.sendMessage('test');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      streamController.addError(
        AiServiceException(AppFailure.auth(message: 'bad key')),
        StackTrace.current,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await future;

      expect(container.read(chatMessagesProvider).failure, isNotNull);

      notifier.dismissError();
      expect(container.read(chatMessagesProvider).failure, isNull);
    });

    test('sendMessage does not fire while streaming', () async {
      final streamController = StreamController<String>();
      when(() => mockRepo.sendMessageStream(
            history: any(named: 'history'),
            userMessage: any(named: 'userMessage'),
          )).thenAnswer((_) => streamController.stream);

      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatMessagesProvider.notifier);
      final future = notifier.sendMessage('first');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Try to send while streaming
      await notifier.sendMessage('second');

      final state = container.read(chatMessagesProvider);
      // Should still only have the first exchange
      expect(state.messages.length, 2);
      expect(state.messages[0].content, 'first');

      await streamController.close();
      await future;
    });

    test('cancellation error does not set failure', () async {
      final streamController = StreamController<String>();
      when(() => mockRepo.sendMessageStream(
            history: any(named: 'history'),
            userMessage: any(named: 'userMessage'),
          )).thenAnswer((_) => streamController.stream);

      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(chatMessagesProvider.notifier);
      final future = notifier.sendMessage('test');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      streamController.add('some content');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Simulate cancellation
      streamController.addError(
        AiServiceException(AppFailure.cancelled()),
        StackTrace.current,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await future;

      final state = container.read(chatMessagesProvider);
      expect(state.failure, isNull); // Cancellation is not an error
      expect(state.isStreaming, isFalse);
    });
  });
}
