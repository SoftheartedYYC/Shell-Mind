import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/storage/hive_storage_service.dart';
import '../domain/entities/chat_message.dart';

/// Hive-backed persistence for the AI conversation transcript.
///
/// The whole message list lives under a single key in the `chat_history` box
/// as an ordered JSON array — no TypeAdapter registration required (mirrors
/// `CustomAiProviderStore`). Writes are debounced so a streaming reply that
/// mutates the transcript hundreds of times per second coalesces into a
/// single disk write once the stream settles.
class ChatHistoryStore {
  ChatHistoryStore({HiveStorageService? hive})
      : _hive = hive ?? HiveStorageService.instance;

  static final ChatHistoryStore instance = ChatHistoryStore();

  final HiveStorageService _hive;

  static const String _box = AppConstants.hiveBoxChatHistory;
  static const String _key = 'chat_history_messages';

  /// Hard cap on persisted turns — the transcript is truncated to the most
  /// recent [AppConstants.kMaxChatHistoryMessages] entries on every write.
  static const int maxMessages = AppConstants.kMaxChatHistoryMessages;

  /// How long dirty writes wait before hitting the disk.
  static const Duration debounceInterval = Duration(milliseconds: 800);

  Timer? _debounce;
  Future<void> _pendingWrite = Future<void>.value();
  bool _clearedWhilePending = false;
  List<ChatMessage> _lastRequested = const <ChatMessage>[];

  /// Persists [messages] (JSON array) with an [debounceInterval] debounce.
  ///
  /// Multiple calls inside the window collapse into one write of the latest
  /// list. Never throws: persistence failures are logged and swallowed so a
  /// storage hiccup cannot break an ongoing conversation.
  void saveMessages(List<ChatMessage> messages) {
    _clearedWhilePending = false;
    _lastRequested = messages;
    _debounce?.cancel();
    _debounce = Timer(debounceInterval, () {
      _pendingWrite = _writeNow(messages);
    });
  }

  /// Persists [messages] immediately, cancelling any pending debounced write.
  /// Used when the app should not lose the tail of a transcript (e.g. clearing
  /// or lifecycle events).
  Future<void> flush(List<ChatMessage> messages) {
    _debounce?.cancel();
    _debounce = null;
    _clearedWhilePending = false;
    return _pendingWrite = _writeNow(messages);
  }

  /// Removes the persisted transcript. Any pending debounced write is
  /// cancelled so it cannot resurrect cleared history.
  Future<void> clear() {
    _debounce?.cancel();
    _debounce = null;
    _clearedWhilePending = true;
    return _pendingWrite = _pendingWrite.then((_) async {
      if (!_clearedWhilePending) return;
      try {
        await _hive.delete(_box, _key);
      } catch (error) {
        debugPrint('[ChatHistoryStore] clear failed: $error');
      }
    });
  }

  /// Loads the persisted transcript, or an empty list when none exists.
  ///
  /// Messages that were mid-stream when the app was killed come back as
  /// finished turns ([ChatMessage.finish]) so the restored transcript never
  /// shows a dangling typing cursor. Malformed frames are dropped silently.
  Future<List<ChatMessage>> load() async {
    try {
      final Object? raw = _hive.get<Object>(_box, _key);
      if (raw is! String || raw.isEmpty) return const <ChatMessage>[];
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return const <ChatMessage>[];
      final List<ChatMessage> messages = <ChatMessage>[
        for (final Object? entry in decoded)
          if (_messageFromJson(entry) case final ChatMessage m) m,
      ];
      // Chronological order is the contract: oldest turn first, so a
      // transcript restored after a restart replays exactly as it was written.
      messages.sort((ChatMessage a, ChatMessage b) =>
          a.timestamp.compareTo(b.timestamp));
      return messages;
    } catch (error) {
      debugPrint('[ChatHistoryStore] load failed: $error');
      return const <ChatMessage>[];
    }
  }

  /// True when something is queued to be written (test convenience).
  @visibleForTesting
  bool get hasPendingWrite => _debounce != null && _debounce!.isActive;

  /// Waits for any in-flight or queued write to settle (test convenience).
  ///
  /// A still-scheduled debounce never fires under test (no 800 ms wait), so
  /// the pending write is executed synchronously here first.
  @visibleForTesting
  Future<void> settleForTest() {
    if (_debounce != null && _debounce!.isActive) {
      final List<ChatMessage> pending = _lastRequested;
      _debounce?.cancel();
      _debounce = null;
      _pendingWrite = _pendingWrite.then((_) => _writeNow(pending));
    }
    return _pendingWrite;
  }

  // ─── Internals ──────────────────────────────────────────────────────────

  Future<void> _writeNow(List<ChatMessage> messages) async {
    try {
      final List<ChatMessage> trimmed = messages.length > maxMessages
          ? messages.sublist(messages.length - maxMessages)
          : messages;
      final String encoded = jsonEncode(<Object?>[
        for (final ChatMessage m in trimmed)
          m.isStreaming ? m.finish().toJson() : m.toJson(),
      ]);
      await _hive.put(_box, _key, encoded);
    } catch (error) {
      debugPrint('[ChatHistoryStore] save failed: $error');
    }
  }

  static ChatMessage? _messageFromJson(Object? raw) {
    if (raw is! Map) return null;
    try {
      final ChatMessage message =
          ChatMessage.fromJson(Map<String, dynamic>.from(raw));
      // fromJson is lenient (every field has a fallback), so a foreign map
      // silently decodes to an all-defaults frame — reject it by id.
      if (message.id.isEmpty) return null;
      // A message persisted mid-stream is a turn that never completed —
      // restore it as a finished turn instead of a dangling cursor.
      if (message.isStreaming) return message.finish();
      // Legacy dirty frames: a finished assistant turn with no text and no
      // tool payload renders as a blank bubble — drop it so transcripts
      // restored from an older build are cleaned up on load.
      if (message.role == MessageRole.assistant &&
          message.content.trim().isEmpty &&
          message.toolPayload == null) {
        return null;
      }
      return message;
    } catch (error) {
      debugPrint('[ChatHistoryStore] corrupt entry skipped: $error');
      return null;
    }
  }
}
