import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/storage/hive_storage_service.dart';
import '../domain/entities/chat_message.dart';
import '../domain/entities/chat_session.dart';

/// Hive-backed persistence for the multi-session conversation history.
///
/// The entire session list lives under a single key in the `chat_history` box
/// as an ordered JSON array (mirroring `ChatHistoryStore`'s JSON approach — no
/// `TypeAdapter`). A legacy single-transcript key (`chat_history_messages`)
/// written by older builds is migrated into one session on first load so
/// existing conversations survive the upgrade.
class ChatSessionsStore {
  ChatSessionsStore({HiveStorageService? hive})
      : _hive = hive ?? HiveStorageService.instance;

  static final ChatSessionsStore instance = ChatSessionsStore();

  final HiveStorageService _hive;

  static const String _box = AppConstants.hiveBoxChatHistory;
  static const String _key = 'chat_sessions';
  static const String _legacyKey = 'chat_history_messages';

  static const int maxMessages = AppConstants.kMaxChatHistoryMessages;
  static const int maxSessions = AppConstants.kMaxChatSessions;

  static const Duration debounceInterval = Duration(milliseconds: 800);

  /// Case-insensitive search across session titles and message bodies.
  /// An empty/blank [query] returns [sessions] unchanged.
  static List<ChatSession> search(List<ChatSession> sessions, String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return sessions;
    return sessions
        .where((ChatSession s) =>
            s.title.toLowerCase().contains(q) ||
            s.messages.any((ChatMessage m) => m.content.toLowerCase().contains(q)))
        .toList(growable: false);
  }

  Timer? _debounce;
  Future<void> _pendingWrite = Future<void>.value();
  ChatSession? _lastScheduled;

  /// Loads every session, most-recently-updated first. Migrates a legacy
  /// single-transcript entry into a session when present.
  Future<List<ChatSession>> loadAll() async {
    final List<ChatSession> sessions = _readAll();
    if (sessions.isNotEmpty) return sessions;
    return _migrateLegacy();
  }

  /// Reads the persisted list synchronously (empty when unset/corrupt).
  List<ChatSession> _readAll() {
    try {
      final Object? raw = _hive.get<Object>(_box, _key);
      if (raw is! String || raw.isEmpty) return <ChatSession>[];
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return <ChatSession>[];
      return <ChatSession>[
        for (final Object? entry in decoded)
          if (_sessionFromJson(entry) case final ChatSession s) s,
      ];
    } catch (error) {
      debugPrint('[ChatSessionsStore] load failed: $error');
      return <ChatSession>[];
    }
  }

  Future<List<ChatSession>> _migrateLegacy() async {
    try {
      final Object? raw = _hive.get<Object>(_box, _legacyKey);
      if (raw is! String || raw.isEmpty) return const <ChatSession>[];
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return const <ChatSession>[];
      final List<ChatMessage> messages = <ChatMessage>[
        for (final Object? entry in decoded)
          if (_messageFromJson(entry) case final ChatMessage m) m,
      ];
      messages.sort(
          (ChatMessage a, ChatMessage b) => a.timestamp.compareTo(b.timestamp));
      if (messages.isEmpty) return const <ChatSession>[];
      final ChatSession session = ChatSession(
        id: 'session-${DateTime.now().microsecondsSinceEpoch}',
        title: ChatSession.deriveTitle(messages),
        messages: messages,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await saveSession(session);
      await _hive.delete(_box, _legacyKey);
      return <ChatSession>[session];
    } catch (error) {
      debugPrint('[ChatSessionsStore] migration failed: $error');
      return const <ChatSession>[];
    }
  }

  /// Looks up a single session by id, or `null`.
  Future<ChatSession?> getSession(String id) async {
    for (final ChatSession s in _readAll()) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Debounced upsert of [session] — coalesces streaming bursts.
  void scheduleSave(ChatSession session) {
    _lastScheduled = session;
    _debounce?.cancel();
    _debounce = Timer(debounceInterval, () {
      _pendingWrite = _writeSession(session);
    });
  }

  /// Immediate upsert of [session] (cancels any pending debounced write).
  Future<void> saveSession(ChatSession session) {
    _debounce?.cancel();
    _debounce = null;
    return _pendingWrite = _writeSession(session);
  }

  /// Removes the session with [id] (no-op when unknown).
  Future<void> deleteSession(String id) {
    _debounce?.cancel();
    _debounce = null;
    return _pendingWrite = _pendingWrite.then((_) async {
      try {
        final List<ChatSession> sessions = _readAll()
          ..removeWhere((ChatSession s) => s.id == id);
        await _writeAll(sessions);
      } catch (error) {
        debugPrint('[ChatSessionsStore] delete failed: $error');
      }
    });
  }

  /// Renames the session with [id].
  Future<void> renameSession(String id, String title) {
    _debounce?.cancel();
    _debounce = null;
    return _pendingWrite = _pendingWrite.then((_) async {
      try {
        final List<ChatSession> sessions = _readAll();
        for (int i = 0; i < sessions.length; i++) {
          if (sessions[i].id == id) {
            sessions[i] =
                sessions[i].copyWith(title: title, updatedAt: DateTime.now());
          }
        }
        await _writeAll(sessions);
      } catch (error) {
        debugPrint('[ChatSessionsStore] rename failed: $error');
      }
    });
  }

  /// Wipes every session.
  Future<void> clearAll() {
    _debounce?.cancel();
    _debounce = null;
    return _pendingWrite = _pendingWrite.then((_) async {
      try {
        await _hive.delete(_box, _key);
      } catch (error) {
        debugPrint('[ChatSessionsStore] clearAll failed: $error');
      }
    });
  }

  /// True when a debounced write is queued (test convenience).
  @visibleForTesting
  bool get hasPendingWrite => _debounce != null && _debounce!.isActive;

  /// Flushes any queued debounced write (test convenience).
  @visibleForTesting
  Future<void> settleForTest() {
    final ChatSession? pending = _lastScheduled;
    if (_debounce != null && _debounce!.isActive && pending != null) {
      _debounce?.cancel();
      _debounce = null;
      _pendingWrite = _pendingWrite.then((_) => _writeSession(pending));
    }
    return _pendingWrite;
  }

  // ─── Internals ──────────────────────────────────────────────────────────

  Future<void> _writeSession(ChatSession session) async {
    try {
      final List<ChatSession> sessions = _readAll();
      final int idx = sessions.indexWhere((ChatSession s) => s.id == session.id);
      if (idx >= 0) {
        sessions[idx] = session;
      } else {
        sessions.insert(0, session);
      }
      await _writeAll(sessions);
    } catch (error) {
      debugPrint('[ChatSessionsStore] save failed: $error');
    }
  }

  Future<void> _writeAll(List<ChatSession> sessions) async {
    sessions.sort(
        (ChatSession a, ChatSession b) => b.updatedAt.compareTo(a.updatedAt));
    final List<ChatSession> trimmed =
        sessions.length > maxSessions ? sessions.sublist(0, maxSessions) : sessions;
    final String encoded = jsonEncode(<Object?>[
      for (final ChatSession s in trimmed) _sessionToJson(s),
    ]);
    await _hive.put(_box, _key, encoded);
  }

  static Map<String, dynamic> _sessionToJson(ChatSession s) {
    final List<ChatMessage> msgs = s.messages.length > maxMessages
        ? s.messages.sublist(s.messages.length - maxMessages)
        : s.messages;
    return <String, dynamic>{
      'id': s.id,
      'title': s.title,
      'createdAt': s.createdAt.toIso8601String(),
      'updatedAt': s.updatedAt.toIso8601String(),
      'messages': <Map<String, dynamic>>[
        for (final ChatMessage m in msgs)
          m.isStreaming ? m.finish().toJson() : m.toJson(),
      ],
    };
  }

  static ChatSession? _sessionFromJson(Object? raw) {
    if (raw is! Map) return null;
    try {
      final Map<String, dynamic> map = Map<String, dynamic>.from(raw);
      final String id = map['id'] as String? ?? '';
      if (id.isEmpty) return null;
      return ChatSession(
        id: id,
        title: map['title'] as String? ?? 'New session',
        createdAt:
            DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt:
            DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now(),
        messages: <ChatMessage>[
          for (final Object? entry in (map['messages'] as List<dynamic>? ?? const <dynamic>[]))
            if (_messageFromJson(entry) case final ChatMessage m) m,
        ],
      );
    } catch (error) {
      debugPrint('[ChatSessionsStore] corrupt session skipped: $error');
      return null;
    }
  }

  static ChatMessage? _messageFromJson(Object? raw) {
    if (raw is! Map) return null;
    try {
      final ChatMessage message =
          ChatMessage.fromJson(Map<String, dynamic>.from(raw));
      if (message.id.isEmpty) return null;
      if (message.isStreaming) return message.finish();
      if (message.role == MessageRole.assistant &&
          message.content.trim().isEmpty &&
          message.toolPayload == null) {
        return null;
      }
      return message;
    } catch (error) {
      debugPrint('[ChatSessionsStore] corrupt entry skipped: $error');
      return null;
    }
  }
}
