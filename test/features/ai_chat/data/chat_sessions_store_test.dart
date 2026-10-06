import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:shell_mind/core/constants/app_constants.dart';
import 'package:shell_mind/core/storage/hive_storage_service.dart';
import 'package:shell_mind/features/ai_chat/data/chat_sessions_store.dart';
import 'package:shell_mind/features/ai_chat/domain/entities/chat_message.dart';
import 'package:shell_mind/features/ai_chat/domain/entities/chat_session.dart';

/// Test-friendly HiveStorageService backed by a pre-initialised Hive in a
/// temp directory (avoids path_provider).
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
  late ChatSessionsStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('chat_sessions_test_');
    Hive.init(tempDir.path);
    await Hive.openBox<dynamic>(AppConstants.hiveBoxChatHistory);
    store = ChatSessionsStore(hive: _TestHiveStorageService());
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(AppConstants.hiveBoxChatHistory);
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });

  ChatMessage user(String id, String content, {DateTime? at}) =>
      ChatMessage.user(id: id, content: content, timestamp: at);

  ChatSession session(
    String id,
    String title,
    List<ChatMessage> messages, {
    DateTime? updatedAt,
  }) =>
      ChatSession(
        id: id,
        title: title,
        messages: messages,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: updatedAt ?? DateTime(2024, 1, 1),
      );

  test('saveSession + loadAll round-trips a session', () async {
    await store.saveSession(session('s1', 'First', <ChatMessage>[
      user('u1', 'hello'),
      ChatMessage.assistantStreaming(id: 'a1', content: 'hi').finish(),
    ]));

    final List<ChatSession> loaded = await store.loadAll();
    expect(loaded, hasLength(1));
    expect(loaded.single.id, 's1');
    expect(loaded.single.title, 'First');
    expect(loaded.single.messages, hasLength(2));
    expect(loaded.single.messages[1].content, 'hi');
  });

  test('loadAll orders sessions by most-recently-updated first', () async {
    await store.saveSession(
      session('old', 'Old', <ChatMessage>[user('a', 'x')],
          updatedAt: DateTime(2024, 1, 1)),
    );
    await store.saveSession(
      session('new', 'New', <ChatMessage>[user('b', 'y')],
          updatedAt: DateTime(2024, 6, 1)),
    );
    final List<ChatSession> loaded = await store.loadAll();
    expect(loaded.map((ChatSession s) => s.id).toList(), <String>['new', 'old']);
  });

  test('upsert replaces an existing session rather than duplicating', () async {
    await store
        .saveSession(session('s1', 'A', <ChatMessage>[user('u1', 'one')]));
    await store.saveSession(
        session('s1', 'B', <ChatMessage>[user('u1', 'one'), user('u2', 'two')]));
    final List<ChatSession> loaded = await store.loadAll();
    expect(loaded, hasLength(1));
    expect(loaded.single.title, 'B');
    expect(loaded.single.messages, hasLength(2));
  });

  test('deleteSession and renameSession mutate the list', () async {
    await store
        .saveSession(session('s1', 'One', <ChatMessage>[user('a', 'x')]));
    await store
        .saveSession(session('s2', 'Two', <ChatMessage>[user('b', 'y')]));

    await store.renameSession('s1', 'Renamed');
    await store.deleteSession('s2');

    final List<ChatSession> loaded = await store.loadAll();
    expect(loaded, hasLength(1));
    expect(loaded.single.id, 's1');
    expect(loaded.single.title, 'Renamed');
  });

  test('clearAll removes every session', () async {
    await store
        .saveSession(session('s1', 'One', <ChatMessage>[user('a', 'x')]));
    await store.clearAll();
    expect(await store.loadAll(), isEmpty);
  });

  test('migrates a legacy single transcript into one session', () async {
    // Simulate an older build's persisted transcript.
    final HiveStorageService hive = _TestHiveStorageService();
    final String legacy = jsonEncode(<Object?>[
      user('u-old', 'previous question', at: DateTime(2024, 1, 1)).toJson(),
      ChatMessage.assistantStreaming(id: 'a-old', content: 'previous answer')
          .finish()
          .toJson(),
    ]);
    await hive.put(AppConstants.hiveBoxChatHistory, 'chat_history_messages',
        legacy);

    final List<ChatSession> loaded = await store.loadAll();
    expect(loaded, hasLength(1));
    expect(loaded.single.messages, hasLength(2));
    expect(loaded.single.messages.first.content, 'previous question');
    expect(loaded.single.title, 'previous question');
    // The legacy key must be removed so the migration never re-runs.
    expect(hive.hasKey(AppConstants.hiveBoxChatHistory, 'chat_history_messages'),
        isFalse);
  });

  test('restores mid-stream turns as finished and drops blank frames',
      () async {
    final HiveStorageService hive = _TestHiveStorageService();
    final String raw = jsonEncode(<Object?>[
      <String, dynamic>{
        'id': 's1',
        'title': 'Seeded',
        'createdAt': DateTime(2024, 1, 1).toIso8601String(),
        'updatedAt': DateTime(2024, 1, 1).toIso8601String(),
        'messages': <Object?>[
          user('u1', 'question').toJson(),
          ChatMessage(
            id: 'blank',
            role: MessageRole.assistant,
            content: '',
            timestamp: DateTime(2024, 1, 1),
          ).toJson(),
          ChatMessage.assistantStreaming(id: 'a1', content: 'partial').toJson(),
        ],
      },
    ]);
    await hive.put(AppConstants.hiveBoxChatHistory, 'chat_sessions', raw);

    final List<ChatSession> loaded = await store.loadAll();
    expect(loaded.single.messages, hasLength(2));
    expect(loaded.single.messages.last.content, 'partial');
    expect(loaded.single.messages.last.isStreaming, isFalse);
  });

  test('search matches titles and message bodies case-insensitively', () {
    final List<ChatSession> sessions = <ChatSession>[
      session('s1', 'Deploy notes', <ChatMessage>[user('a', 'nginx reload')]),
      session('s2', 'Random', <ChatMessage>[user('b', 'unrelated')]),
    ];
    expect(ChatSessionsStore.search(sessions, 'deploy'), hasLength(1));
    expect(ChatSessionsStore.search(sessions, 'NGINX'), hasLength(1));
    expect(ChatSessionsStore.search(sessions, 'nope'), isEmpty);
    expect(ChatSessionsStore.search(sessions, '  '), hasLength(2));
  });
}
