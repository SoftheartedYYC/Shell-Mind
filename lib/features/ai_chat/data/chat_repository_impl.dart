import 'dart:async';

import 'package:dio/dio.dart';

import '../../../core/utils/result.dart';
import '../domain/entities/chat_message.dart';
import '../domain/repositories/chat_repository.dart';
import 'ai_service.dart';

/// Agent-protocol system prompt injected as the leading `system` message.
///
/// Defines Shell-Mind AI as an autonomous agent capable of executing commands
/// on connected servers, orchestrating multi-server operations, and following
/// a structured execution protocol for tool-use loops.
const String kShellMindSystemPrompt = '''
You are Shell-Mind AI, an expert Linux/Unix system administrator agent with direct SSH access to remote servers.

## Capabilities
- Execute shell commands on connected servers via SSH
- Analyze command output and diagnose issues
- Orchestrate operations across multiple servers
- Provide security and performance recommendations

## Execution Protocol
When you need to run commands on a server:
1. Output EXACTLY ONE \u0060\u0060\u0060bash code block per response
2. To target a specific server, add a comment as the FIRST line inside the block: # server: <ServerName>
3. If no server tag is specified, the command runs on the default/only active server
4. After receiving [tool-output], analyze the results and decide the next action
5. When the task is complete, respond WITHOUT any code block and summarize what was done

## Multi-Server Operations
- You can orchestrate across multiple servers (deploy, sync, verify connectivity)
- Use scp/rsync for file transfer between servers when needed
- Always verify operations on the target server after cross-server actions
- When operating on multiple servers, execute ONE command at a time per response

## Safety Rules
- Never execute destructive commands (rm -rf /, mkfs, dd if=) without explaining risks first
- Prefer dry-run/preview flags when available (--dry-run, -n, --check)
- Always check current state before making changes (ls, cat, systemctl status)
- If a command fails, analyze the error before retrying

## Response Format
- Explanations and analysis in natural language
- Commands in \u0060\u0060\u0060bash code blocks (will be auto-detected for execution)
- After [tool-output] injection, provide analysis of the results
''';

/// How many trailing messages are forwarded to the model. Bounds cost and
/// latency while preserving enough context for coherent follow-ups.
const int kMaxHistoryMessages = 20;

/// Default [ChatRepository] backed by [AiService].
///
/// Owns prompt assembly: prepends the system persona (dynamically enriched
/// with the list of currently connected servers), trims history to the most
/// recent [kMaxHistoryMessages] turns, and appends the live user message.
class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._service, {this._activeServersGetter});

  final AiService _service;

  /// Callback that returns descriptions of currently online servers.
  /// Injected from the provider layer to avoid coupling to Riverpod here.
  final List<String> Function()? _activeServersGetter;

  /// Converts domain messages into the `[{role, content}]` wire format,
  /// dropping empty/system-noise and enforcing the history window.
  ///
  /// [activeServers] is resolved dynamically via [_activeServersGetter] and
  /// appended to the system prompt so the model knows which servers are online.
  List<Map<String, String>> _buildMessages(
    List<ChatMessage> history,
    String userMessage,
  ) {
    // Build dynamic system prompt with connected server info.
    final String systemPrompt = _buildSystemPrompt();

    final List<Map<String, String>> wire = <Map<String, String>>[
      <String, String>{
        'role': MessageRole.system.wire,
        'content': systemPrompt,
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
      final ChatMessage msg = turns[i];
      if (msg.role == MessageRole.tool && msg.toolPayload != null) {
        // Tool results travel as `user` turns: most OpenAI-compatible
        // endpoints reject a standalone `tool` role outside function-calling.
        // The [tool-output] envelope keeps them distinguishable for the model.
        wire.add(<String, String>{
          'role': MessageRole.user.wire,
          'content': msg.toolPayload!.toWireContent(),
        });
      } else {
        wire.add(<String, String>{
          'role': msg.role.wire,
          'content': msg.content,
        });
      }
    }

    // Skip the trailing user turn when empty — tool-result continuations
    // call with `userMessage: ''` because the [tool-output] turns in
    // [history] already carry the prompt; an empty user message would
    // violate the alternation some providers enforce.
    if (userMessage.trim().isNotEmpty) {
      wire.add(<String, String>{
        'role': MessageRole.user.wire,
        'content': userMessage,
      });
    }

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

  /// Assembles the full system prompt by appending the live server roster.
  String _buildSystemPrompt() {
    final StringBuffer sb = StringBuffer(kShellMindSystemPrompt.trim());
    final List<String>? servers = _activeServersGetter?.call();
    if (servers != null && servers.isNotEmpty) {
      sb.write('\n\n## Currently Connected Servers\n');
      for (final String server in servers) {
        sb.write('- $server\n');
      }
      sb.write('\nUse "# server: <name>" in code blocks to target a specific server.');
    } else {
      sb.write('\n\n## Currently Connected Servers\n');
      sb.write('No servers connected. Commands cannot be executed until '
          'the user connects to a server via the Terminal page.');
    }
    return sb.toString();
  }

  /// Normalises thrown objects into an [AppFailure].
  AppFailure _toFailure(Object error, StackTrace stack) {
    if (error is AiServiceException) return error.failure;
    if (error is AppFailureException) return error.failure;
    return AppFailure.unexpected(error, stackTrace: stack);
  }
}
