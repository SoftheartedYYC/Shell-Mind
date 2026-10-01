import 'package:flutter/foundation.dart';

/// Role of a message participant in a chat exchange.
///
/// Mirrors the `role` field expected by the OpenAI Chat Completions API so
/// it can be serialised 1:1 without a mapping table.
enum MessageRole {
  system,
  user,
  assistant;

  /// Wire value sent in the `role` field of an OpenAI request payload.
  String get wire => name;

  static MessageRole fromWire(String value) => MessageRole.values.firstWhere(
        (MessageRole r) => r.name == value,
        orElse: () => MessageRole.user,
      );
}

/// A single turn in a chat conversation.
///
/// Immutable by design — streaming updates replace the message with a new
/// instance carrying the accumulated [content] and [isStreaming] flag rather
/// than mutating in place. This keeps Riverpod state changes referentially
/// transparent.
@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isStreaming = false,
    this.error = false,
  });

  /// Stable identifier — used as a `ValueKey` for list items and to target a
  /// specific message during streaming updates.
  final String id;

  final MessageRole role;

  /// Full text of the message. While [isStreaming] is true this grows as
  /// tokens arrive.
  final String content;

  final DateTime timestamp;

  /// True while the assistant response is still being received token-by-token.
  final bool isStreaming;

  /// True when this message represents a surfaced error rather than model text.
  final bool error;

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
  bool get isSystem => role == MessageRole.system;

  /// Convenience factory for a fresh user message.
  factory ChatMessage.user({
    required String id,
    required String content,
    DateTime? timestamp,
  }) =>
      ChatMessage(
        id: id,
        role: MessageRole.user,
        content: content,
        timestamp: timestamp ?? DateTime.now(),
      );

  /// Convenience factory for an empty assistant placeholder that will be
  /// filled by the incoming stream.
  factory ChatMessage.assistantStreaming({
    required String id,
    String content = '',
    DateTime? timestamp,
  }) =>
      ChatMessage(
        id: id,
        role: MessageRole.assistant,
        content: content,
        timestamp: timestamp ?? DateTime.now(),
        isStreaming: true,
      );

  ChatMessage copyWith({
    String? id,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    bool? isStreaming,
    bool? error,
  }) =>
      ChatMessage(
        id: id ?? this.id,
        role: role ?? this.role,
        content: content ?? this.content,
        timestamp: timestamp ?? this.timestamp,
        isStreaming: isStreaming ?? this.isStreaming,
        error: error ?? this.error,
      );

  /// Marks streaming as complete without altering the content.
  ChatMessage finish() => copyWith(isStreaming: false);

  /// Appends a token to the content, keeping the streaming flag intact.
  ChatMessage append(String chunk) => copyWith(content: content + chunk);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'role': role.wire,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'isStreaming': isStreaming,
        'error': error,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String? ?? '',
        role: MessageRole.fromWire(json['role'] as String? ?? 'user'),
        content: json['content'] as String? ?? '',
        timestamp:
            DateTime.tryParse(json['timestamp'] as String? ?? '') ??
                DateTime.now(),
        isStreaming: json['isStreaming'] as bool? ?? false,
        error: json['error'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      other is ChatMessage &&
      other.id == id &&
      other.role == role &&
      other.content == content &&
      other.timestamp == timestamp &&
      other.isStreaming == isStreaming &&
      other.error == error;

  @override
  int get hashCode =>
      Object.hash(id, role, content, timestamp, isStreaming, error);

  @override
  String toString() =>
      'ChatMessage(${role.name}, ${content.length} chars, streaming: $isStreaming)';
}
