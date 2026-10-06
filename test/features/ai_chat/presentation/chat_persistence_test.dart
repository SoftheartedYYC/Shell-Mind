import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shell_mind/core/constants/app_constants.dart';
import 'package:shell_mind/core/storage/hive_storage_service.dart';
import 'package:shell_mind/features/ai_chat/data/chat_history_store.dart';
import 'package:shell_mind/features/ai_chat/domain/entities/chat_message.dart';
import 'package:shell_mind/features/ai_chat/domain/repositories/chat_repository.dart';
import 'package:shell_mind/features/ai_chat/presentation/providers/chat_providers.dart';
import 'package:shell_mind/shared/ssh/ssh_command_executor.dart';

class MockChatRepository extends Mock implements ChatRepository {}

/// Test-friendly HiveStorageService backed by a pre-initialised Hive in a
/// temp directory (avoids path_provider, mirrors the custom-provider tests).
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
  late ChatHistoryStore store;
  late MockChatRepository mockRepo;
  late ProviderContainer container;
  late StreamController<String> streamController;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('chat_persist_test_');
    Hive.init(tempDir.path);
    await Hive.openBox<dynamic>(AppConstants.hiveBoxChatHistory);

    store = ChatHistoryStore(hive: _TestHiveStorageService());
    mockRepo = MockChatRepository();
    streamController = StreamController<String>();
    when(() => mockRepo.sendMessageStream(
          history: any(named: 'history'),
          userMessage: any(named: 'userMessage'),
        )).thenAnswer((_) => streamController.stream);

    container = ProviderContainer(overrides: <Override>[
      chatRepositoryProvider.overrideWithValue(mockRepo),
      chatHistoryStoreProvider.overrideWithValue(store),
    ]);
  });

  tearDown(() async {
    container.dispose();
    // A single-subscription controller that never had a listener buffers its
    // done event forever, so awaiting close() would hang the test. Only the
    // send-path tests (which listen) need the awaited close.
    if (streamController.hasListener) {
      await streamController.close();
    }
    await Hive.deleteBoxFromDisk(AppConstants.hiveBoxChatHistory);
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  /// Waits until the transcript has been persisted to Hive (the write path is
  /// debounced for scheduled saves; flush paths settle immediately).
  Future<void> waitPersisted() async {
    await store.settleForTest();
  }

  group('ChatNotifier persistence wiring', () {
    test('sendMessage persists the user turn and the streamed reply',
        () async {
      final ChatNotifier notifier =
          container.read(chatMessagesProvider.notifier);
      // sendMessage returns as soon as the stream is wired; completion is
      // observed via the notifier state + Hive, not via this future.
      final Future<void> sending = notifier.sendMessage('Hello AI');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      streamController.add('streamed answer');
      streamController.add(' part two');
      await streamController.close();
      await sending;
      // Give onDone a microtask turnaround to flush the transcript.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await waitPersisted();

      final List<ChatMessage> persisted = await store.load();
      expect(persisted, hasLength(2));
      expect(persisted[0].isUser, isTrue);
      expect(persisted[0].content, 'Hello AI');
      expect(persisted[1].isAssistant, isTrue);
      expect(persisted[1].content, 'streamed answer part two');
      expect(persisted[1].isStreaming, isFalse);
    });

    test('restoreFromHistory loads the last transcript once', () async {
      // Seed the box as a previous session would have left it.
      await store.flush(<ChatMessage>[
        ChatMessage.user(id: 'u-old', content: 'previous question'),
        ChatMessage.assistantStreaming(id: 'a-old', content: 'previous answer')
            .finish(),
      ]);

      // New container = fresh notifier, as after an app restart.
      final List<ChatMessage> before =
          container.read(chatMessagesProvider).messages;
      expect(before, isEmpty);

      await container
          .read(chatMessagesProvider.notifier)
          .restoreFromHistory(store);
      final List<ChatMessage> restored =
          container.read(chatMessagesProvider).messages;
      expect(restored, hasLength(2));
      expect(restored[0].content, 'previous question');
      expect(restored[1].content, 'previous answer');
      expect(restored[1].isStreaming, isFalse,
          reason: 'restored transcript must not show a dangling cursor');

      // A second restore must not duplicate history.
      await container
          .read(chatMessagesProvider.notifier)
          .restoreFromHistory(store);
      expect(container.read(chatMessagesProvider).messages, hasLength(2));
    });

    test('clearChat wipes both state and the Hive transcript', () async {
      final ChatNotifier notifier =
          container.read(chatMessagesProvider.notifier);
      await notifier.sendMessage('to be cleared');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await streamController.close();

      notifier.clearChat();

      expect(container.read(chatMessagesProvider).messages, isEmpty);
      // The debounced save scheduled by sendMessage must not resurrect the
      // cleared history.
      await waitPersisted();
      expect(await store.load(), isEmpty);
    });

    test('stopStreaming keeps the partial reply and persists it', () async {
      final ChatNotifier notifier =
          container.read(chatMessagesProvider.notifier);
      await notifier.sendMessage('tell me about ssh');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      streamController.add('partial ans');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      notifier.stopStreaming();

      final ChatState state = container.read(chatMessagesProvider);
      expect(state.isStreaming, isFalse);
      expect(state.messages.last.content, 'partial ans');

      await waitPersisted();
      final List<ChatMessage> persisted = await store.load();
      expect(persisted, hasLength(2));
      expect(persisted.last.content, 'partial ans');
      expect(persisted.last.isStreaming, isFalse);
    });

    test('sendToolResult persists the tool turn', () async {
      final ChatNotifier notifier =
          container.read(chatMessagesProvider.notifier);
      // When the follow-up stream is never closed, the tool turn is still
      // persisted by the debounced save scheduled on append.
      streamController.close();

      await notifier.sendToolResult(CommandResult(
        command: 'df -h',
        serverId: 'srv-1',
        serverName: 'prod-web',
        stdout: '/dev/sda1 40G',
        stderr: '',
        exitCode: 0,
        elapsed: const Duration(milliseconds: 300),
        executedAt: DateTime(2024, 1, 2),
      ));

      await waitPersisted();

      final List<ChatMessage> persisted = await store.load();
      expect(persisted.first.isTool, isTrue);
      expect(persisted.first.toolPayload!.command, 'df -h');
    });
  });
}
