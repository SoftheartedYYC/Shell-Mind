import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:shell_mind/core/constants/app_constants.dart';
import 'package:shell_mind/core/storage/hive_storage_service.dart';
import 'package:shell_mind/features/ai_chat/data/chat_history_store.dart';
import 'package:shell_mind/features/ai_chat/domain/entities/chat_message.dart';

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
  late _TestHiveStorageService hive;
  late ChatHistoryStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('chat_history_test_');
    Hive.init(tempDir.path);
    await Hive.openBox<dynamic>(AppConstants.hiveBoxChatHistory);
    hive = _TestHiveStorageService();
    store = ChatHistoryStore(hive: hive);
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(AppConstants.hiveBoxChatHistory);
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  ChatMessage user(String id, String content, {DateTime? timestamp}) =>
      ChatMessage.user(id: id, content: content, timestamp: timestamp);

  ChatMessage assistant(String id, String content) =>
      ChatMessage.assistantStreaming(id: id, content: content).finish();

  group('ChatHistoryStore round-trip', () {
    test('saveMessages + load returns the same transcript', () async {
      final List<ChatMessage> transcript = <ChatMessage>[
        user('u1', 'hello'),
        assistant('a1', 'hi there'),
      ];

      store.saveMessages(transcript);
      await store.settleForTest();

      final List<ChatMessage> loaded = await store.load();
      expect(loaded.length, 2);
      expect(loaded[0].id, 'u1');
      expect(loaded[0].content, 'hello');
      expect(loaded[0].isUser, isTrue);
      expect(loaded[1].id, 'a1');
      expect(loaded[1].content, 'hi there');
      expect(loaded[1].isAssistant, isTrue);
    });

    test('round-trips tool messages with their payload', () async {
      final ChatMessage tool = ChatMessage.toolResult(
        id: 't1',
        payload: ToolPayload(
          toolType: 'ssh_exec',
          command: 'uptime',
          serverId: 'srv-1',
          serverName: 'prod-web',
          stdout: 'load average',
          stderr: '',
          exitCode: 0,
          elapsed: const Duration(milliseconds: 120),
        ),
      );

      store.saveMessages(<ChatMessage>[tool]);
      await store.settleForTest();

      final List<ChatMessage> loaded = await store.load();
      expect(loaded, hasLength(1));
      expect(loaded[0].isTool, isTrue);
      expect(loaded[0].toolPayload, isNotNull);
      expect(loaded[0].toolPayload!.command, 'uptime');
      expect(loaded[0].toolPayload!.serverName, 'prod-web');
      expect(loaded[0].toolPayload!.success, isTrue);
    });

    test('streaming placeholder is restored as a finished turn', () async {
      final ChatMessage streaming =
          ChatMessage.assistantStreaming(id: 'a1', content: 'partial');

      store.saveMessages(<ChatMessage>[streaming]);
      await store.settleForTest();

      final List<ChatMessage> loaded = await store.load();
      expect(loaded, hasLength(1));
      expect(loaded[0].isStreaming, isFalse);
      expect(loaded[0].content, 'partial');
    });

    test('load returns messages sorted by timestamp', () async {
      // Persisted out of order; load() must replay chronologically.
      final List<ChatMessage> transcript = <ChatMessage>[
        user('u2', 'second',
            timestamp: DateTime(2024, 1, 2, 10)),
        user('u1', 'first', timestamp: DateTime(2024, 1, 2, 9)),
        user('u3', 'third', timestamp: DateTime(2024, 1, 2, 11)),
      ];

      store.saveMessages(transcript);
      await store.settleForTest();

      final List<ChatMessage> loaded = await store.load();
      expect(loaded.map((ChatMessage m) => m.id).toList(),
          <String>['u1', 'u2', 'u3']);
    });

    test('clear removes the persisted transcript', () async {
      store.saveMessages(<ChatMessage>[user('u1', 'bye')]);
      await store.settleForTest();

      await store.clear();
      final List<ChatMessage> loaded = await store.load();
      expect(loaded, isEmpty);
    });

    test('clear cancels a pending debounced write', () async {
      store.saveMessages(<ChatMessage>[user('u1', 'doomed')]);
      expect(store.hasPendingWrite, isTrue);

      await store.clear();
      expect(store.hasPendingWrite, isFalse);

      final List<ChatMessage> loaded = await store.load();
      expect(loaded, isEmpty);
    });

    test('flush writes immediately without waiting for the debounce',
        () async {
      store.saveMessages(<ChatMessage>[user('u1', 'stale')]);
      final List<ChatMessage> next = <ChatMessage>[user('u1', 'fresh')];

      await store.flush(next);

      final List<ChatMessage> loaded = await store.load();
      expect(loaded.single.content, 'fresh');
    });

    test('load on an empty box returns an empty list', () async {
      final List<ChatMessage> loaded = await store.load();
      expect(loaded, isEmpty);
    });

    test('corrupt JSON frame is dropped, not thrown', () async {
      await hive.put(
          AppConstants.hiveBoxChatHistory, 'chat_history_messages', '{not json');
      final List<ChatMessage> loaded = await store.load();
      expect(loaded, isEmpty);
    });

    test('malformed entries inside a valid array are skipped', () async {
      await hive.put(
        AppConstants.hiveBoxChatHistory,
        'chat_history_messages',
        '[{"id":"u1","role":"user","content":"ok","timestamp":"2024-01-02T10:00:00.000"},{"bogus":true},'
        '{"id":"a1","role":"assistant","content":"fine","timestamp":"2024-01-02T10:00:01.000"}]',
      );

      final List<ChatMessage> loaded = await store.load();
      expect(loaded.map((ChatMessage m) => m.id).toList(),
          <String>['u1', 'a1']);
    });

    test('transcript is capped to maxMessages on write', () async {
      final List<ChatMessage> overflow = <ChatMessage>[
        for (int i = 0; i < ChatHistoryStore.maxMessages + 10; i++)
          user('u$i', 'turn $i', timestamp: DateTime(2024, 1, 1).add(Duration(minutes: i))),
      ];

      store.saveMessages(overflow);
      await store.settleForTest();

      final List<ChatMessage> loaded = await store.load();
      expect(loaded.length, ChatHistoryStore.maxMessages);
      // Newest turns survive; the oldest are dropped.
      expect(loaded.first.id, 'u10');
      expect(loaded.last.id, 'u${ChatHistoryStore.maxMessages + 9}');
    });
  });
}
