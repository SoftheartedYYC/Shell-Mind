import 'package:flutter/foundation.dart';

/// Role of a message participant in a chat exchange.
///
/// Mirrors the `role` field expected by the OpenAI Chat Completions API so
/// it can be serialised 1:1 without a mapping table.
enum MessageRole {
  system,
  user,
  assistant,

  /// Result of a tool execution (e.g. an SSH command run on a server).
  /// Downgraded to `user` on the wire — see `ChatRepositoryImpl`.
  tool;

  /// Wire value sent in the `role` field of an OpenAI request payload.
  String get wire => name;

  static MessageRole fromWire(String value) => MessageRole.values.firstWhere(
        (MessageRole r) => r.name == value,
        orElse: () => MessageRole.user,
      );
}

/// Payload attached to a [MessageRole.tool] message describing the outcome
/// of an SSH command execution.
///
/// [toWireContent] renders a stable `[tool-output]` envelope that is fed back
/// to the model as a user turn, since most OpenAI-compatible endpoints do not
/// accept a standalone `tool` role outside function-calling flows.
@immutable
class ToolPayload {
  const ToolPayload({
    required this.toolType,
    required this.command,
    required this.serverId,
    required this.serverName,
    required this.stdout,
    required this.stderr,
    required this.exitCode,
    required this.elapsed,
  });

  /// Identifier of the tool that produced this result, e.g. `ssh_exec`.
  final String toolType;

  /// The command that was executed.
  final String command;

  /// ID of the server the command ran on.
  final String serverId;

  /// Human-readable server name, safe to show to the model.
  final String serverName;

  final String stdout;
  final String stderr;
  final int exitCode;

  /// Wall-clock duration of the execution.
  final Duration elapsed;

  /// True when the command exited cleanly (`exitCode == 0`).
  bool get success => exitCode == 0;

  /// Formats the result as the text sent back to the AI model.
  String toWireContent() {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('[tool-output]');
    buffer.writeln('server: $serverName');
    buffer.writeln('command: $command');
    buffer.writeln('exit_code: $exitCode');
    if (stdout.isNotEmpty) {
      buffer.writeln('stdout:');
      buffer.writeln(stdout);
    }
    if (stderr.isNotEmpty) {
      buffer.writeln('stderr:');
      buffer.writeln(stderr);
    }
    buffer.write('[/tool-output]');
    return buffer.toString();
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'toolType': toolType,
        'command': command,
        'serverId': serverId,
        'serverName': serverName,
        'stdout': stdout,
        'stderr': stderr,
        'exitCode': exitCode,
        'elapsedMs': elapsed.inMilliseconds,
      };

  factory ToolPayload.fromJson(Map<String, dynamic> json) => ToolPayload(
        toolType: json['toolType'] as String? ?? 'ssh_exec',
        command: json['command'] as String? ?? '',
        serverId: json['serverId'] as String? ?? '',
        serverName: json['serverName'] as String? ?? '',
        stdout: json['stdout'] as String? ?? '',
        stderr: json['stderr'] as String? ?? '',
        exitCode: json['exitCode'] as int? ?? -1,
        elapsed: Duration(milliseconds: json['elapsedMs'] as int? ?? 0),
      );

  @override
  bool operator ==(Object other) =>
      other is ToolPayload &&
      other.toolType == toolType &&
      other.command == command &&
      other.serverId == serverId &&
      other.serverName == serverName &&
      other.stdout == stdout &&
      other.stderr == stderr &&
      other.exitCode == exitCode &&
      other.elapsed == elapsed;

  @override
  int get hashCode => Object.hash(
        toolType,
        command,
        serverId,
        serverName,
        stdout,
        stderr,
        exitCode,
        elapsed,
      );

  @override
  String toString() =>
      'ToolPayload($toolType, $serverName, exit: $exitCode, ${elapsed.inMilliseconds}ms)';
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
    this.toolPayload,
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

  /// Execution result attached to [MessageRole.tool] messages; `null` for all
  /// other roles.
  final ToolPayload? toolPayload;

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
  bool get isSystem => role == MessageRole.system;
  bool get isTool => role == MessageRole.tool;

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

  /// Convenience factory for a tool execution result. The message content is
  /// the wire envelope rendered from [payload] so it can be replayed to the
  /// model verbatim.
  factory ChatMessage.toolResult({
    required String id,
    required ToolPayload payload,
    DateTime? timestamp,
  }) =>
      ChatMessage(
        id: id,
        role: MessageRole.tool,
        content: payload.toWireContent(),
        timestamp: timestamp ?? DateTime.now(),
        toolPayload: payload,
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
    ToolPayload? toolPayload,
  }) =>
      ChatMessage(
        id: id ?? this.id,
        role: role ?? this.role,
        content: content ?? this.content,
        timestamp: timestamp ?? this.timestamp,
        isStreaming: isStreaming ?? this.isStreaming,
        error: error ?? this.error,
        toolPayload: toolPayload ?? this.toolPayload,
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
        if (toolPayload != null) 'toolPayload': toolPayload!.toJson(),
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
        toolPayload: json['toolPayload'] is Map<String, dynamic>
            ? ToolPayload.fromJson(json['toolPayload'] as Map<String, dynamic>)
            : null,
      );

  @override
  bool operator ==(Object other) =>
      other is ChatMessage &&
      other.id == id &&
      other.role == role &&
      other.content == content &&
      other.timestamp == timestamp &&
      other.isStreaming == isStreaming &&
      other.error == error &&
      other.toolPayload == toolPayload;

  @override
  int get hashCode => Object.hash(
        id,
        role,
        content,
        timestamp,
        isStreaming,
        error,
        toolPayload,
      );

  @override
  String toString() =>
      'ChatMessage(${role.name}, ${content.length} chars, streaming: $isStreaming)';
}
