import 'package:flutter/foundation.dart';

import 'chat_message.dart';

/// A conversation thread — an ordered list of [ChatMessage]s plus metadata.
///
/// Sessions are immutable value objects; editing produces a new instance.
/// Persistence (Hive) can serialise via [toJson]/[fromJson] when session
/// history is wired up in a later milestone.
@immutable
class ChatSession {
  const ChatSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Empty session used as the initial state of the active conversation.
  factory ChatSession.empty({String? id, DateTime? now}) {
    final DateTime ts = now ?? DateTime.now();
    return ChatSession(
      id: id ?? 'session-${ts.microsecondsSinceEpoch}',
      title: 'New session',
      messages: const <ChatMessage>[],
      createdAt: ts,
      updatedAt: ts,
    );
  }

  final String id;

  /// Human-facing title. Auto-derived from the first user message when the
  /// session is created interactively (see [deriveTitle]).
  final String title;

  final List<ChatMessage> messages;

  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isEmpty => messages.isEmpty;
  bool get isNotEmpty => messages.isNotEmpty;

  /// Number of turns, excluding system messages.
  int get turnCount => messages.where((ChatMessage m) => !m.isSystem).length;

  ChatSession copyWith({
    String? id,
    String? title,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      ChatSession(
        id: id ?? this.id,
        title: title ?? this.title,
        messages: messages ?? this.messages,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Returns a new session with [message] appended and [updatedAt] bumped.
  ChatSession withMessage(ChatMessage message) => copyWith(
        messages: <ChatMessage>[...messages, message],
        updatedAt: DateTime.now(),
      );

  /// Replaces the message sharing [message]'s id (used for streaming updates).
  ChatSession withUpdatedMessage(ChatMessage message) {
    final List<ChatMessage> next = messages
        .map((ChatMessage m) => m.id == message.id ? message : m)
        .toList(growable: false);
    return copyWith(messages: next, updatedAt: DateTime.now());
  }

  /// Builds a title from the first user prompt, trimmed and clamped.
  static String deriveTitle(List<ChatMessage> messages) {
    for (final ChatMessage m in messages) {
      if (m.isUser && m.content.trim().isNotEmpty) {
        final String line = m.content.trim().replaceAll('\n', ' ');
        return line.length <= 40 ? line : '${line.substring(0, 40)}…';
      }
    }
    return 'New session';
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'messages': messages.map((ChatMessage m) => m.toJson()).toList(),
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? 'New session',
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
                DateTime.now(),
        updatedAt:
            DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
                DateTime.now(),
        messages: (json['messages'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(ChatMessage.fromJson)
            .toList(growable: false),
      );

  @override
  bool operator ==(Object other) =>
      other is ChatSession &&
      other.id == id &&
      other.title == title &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      listEquals(other.messages, messages);

  @override
  int get hashCode => Object.hash(id, title, createdAt, updatedAt, messages.length);

  @override
  String toString() =>
      'ChatSession($id, "$title", ${messages.length} messages)';
}
