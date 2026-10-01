import 'dart:async';

import 'package:dio/dio.dart';

import '../../../core/utils/result.dart';
import '../domain/entities/chat_message.dart';
import '../domain/repositories/chat_repository.dart';
import 'openai_service.dart';

/// Persona injected as the leading `system` message on every request.
///
/// Kept here (data layer) rather than in the domain so the wording can evolve
/// with the transport implementation without touching the contract.
const String kShellMindSystemPrompt = '''
You are Shell-Mind AI, an expert Linux/Unix system administrator assistant.
Your role is to help users with:
1. Explaining command outputs and error messages
2. Generating shell commands for specific tasks
3. Diagnosing system issues via SSH terminal output
4. Providing best practices for server management
5. Explaining Linux concepts and tools

Always provide clear, concise answers. When generating commands, explain what each part does.
Format code blocks with proper syntax highlighting hints (\u0060\u0060\u0060bash).
If the user shares terminal output, analyze it carefully and explain what's happening.
''';

/// How many trailing messages are forwarded to the model. Bounds cost and
/// latency while preserving enough context for coherent follow-ups.
const int kMaxHistoryMessages = 20;

/// Default [ChatRepository] backed by [OpenAiService].
///
/// Owns prompt assembly: prepends the system persona, trims history to the
/// most recent [kMaxHistoryMessages] turns, and appends the live user message.
class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._service);

  final OpenAiService _service;

  /// Converts domain messages into the `[{role, content}]` wire format,
  /// dropping empty/system-noise and enforcing the history window.
  List<Map<String, String>> _buildMessages(
    List<ChatMessage> history,
    String userMessage,
  ) {
    final List<Map<String, String>> wire = <Map<String, String>>[
      <String, String>{
        'role': MessageRole.system.wire,
        'content': kShellMindSystemPrompt.trim(),
      },
    ];

    // Only forward real conversation turns (skip empty/placeholder content).
    final List<ChatMessage> turns = history
        .where((ChatMessage m) => !m.isSystem && m.content.trim().isNotEmpty)
        .toList(growable: false);

    final int start = turns.length > kMaxHistoryMessages
        ? turns.length - kMaxHistoryMessages
        : 0;
    for (int i = start; i < turns.length; i++) {
      wire.add(<String, String>{
        'role': turns[i].role.wire,
        'content': turns[i].content,
      });
    }

    wire.add(<String, String>{
      'role': MessageRole.user.wire,
      'content': userMessage,
    });

    return wire;
  }

  @override
  Stream<String> sendMessageStream({
    required List<ChatMessage> history,
    required String userMessage,
    CancelToken? cancelToken,
  }) {
    return _service.chatStream(
      _buildMessages(history, userMessage),
      cancelToken: cancelToken,
    );
  }

  @override
  Future<Result<String>> sendMessage({
    required List<ChatMessage> history,
    required String userMessage,
  }) {
    return Result.guard<String>(
      () => _service.chat(_buildMessages(history, userMessage)),
      onError: (Object error, StackTrace stack) => _toFailure(error, stack),
    );
  }

  /// Normalises thrown objects into an [AppFailure].
  AppFailure _toFailure(Object error, StackTrace stack) {
    if (error is AiServiceException) return error.failure;
    if (error is AppFailureException) return error.failure;
    return AppFailure.unexpected(error, stackTrace: stack);
  }
}
