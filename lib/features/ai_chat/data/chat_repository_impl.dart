import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/utils/result.dart';
import '../domain/entities/chat_message.dart';
import '../domain/repositories/chat_repository.dart';
import 'ai_service.dart';
import 'chat_context_compactor.dart';

/// One entry of the server roster injected into the agent system prompt.
///
/// Lists every configured server (not just online ones) so the model can
/// address any of them with a `# server:` tag; the execution layer decides
/// whether an offline target is auto-connected before the command runs.
@immutable
class ServerRosterEntry {
  const ServerRosterEntry({
    required this.name,
    required this.user,
    required this.host,
    required this.port,
    required this.isOnline,
  });

  final String name;
  final String user;
  final String host;
  final int port;
  final bool isOnline;

  @override
  String toString() =>
      '$name ($user@$host:$port) [${isOnline ? 'connected' : 'not connected'}]';
}

/// Agent-protocol system prompt injected as the leading `system` message.
///
/// Defines Shell-Mind AI as an autonomous agent capable of executing commands
/// on configured servers, orchestrating multi-server operations, and following
/// a structured execution protocol for tool-use loops.
const String kShellMindSystemPrompt = '''
You are Shell-Mind AI, an expert Linux/Unix system administrator agent with direct SSH access to remote servers.

## Capabilities
- Execute shell commands on configured servers via SSH
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

## Server Availability
- The server roster below lists ALL configured servers with their online status
- You may target ANY configured server with "# server: <name>", including ones marked [not connected]
- The system will automatically connect to a [not connected] server before executing the command, using the user's saved credentials — but ONLY when the user has enabled auto-connect
- When auto-connect is disabled, only servers marked [connected] can execute commands

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

/// How many trailing messages are forwarded to the model uncompressed.
///
/// Semantics preserved from the previous hard-window behaviour: it is the
/// "keep recent, never compress" count. Older turns are folded into a
/// synthesized summary turn instead of being dropped (see
/// [chat_context_compactor.dart] for the full policy).
const int kMaxHistoryMessages = kDefaultKeepRecentMessages;

/// Default [ChatRepository] backed by [AiService].
///
/// Owns prompt assembly: prepends the system persona (dynamically enriched
/// with the roster of configured servers and their online status), trims
/// history to the most recent [kMaxHistoryMessages] turns, and appends the
/// live user message.
class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._service, {this._rosterGetter});

  final AiService _service;

  /// Callback that returns every configured server with online status.
  /// Injected from the provider layer to avoid coupling to Riverpod here.
  final List<ServerRosterEntry> Function()? _rosterGetter;

  /// Converts domain messages into the `[{role, content}]` wire format,
  /// dropping empty/system-noise and compacting long histories.
  ///
  /// [ServerRosterEntry]s are resolved dynamically via [_rosterGetter] and
  /// appended to the system prompt so the model knows every configured
  /// server and which ones are online.
  ///
  /// History longer than [kMaxHistoryMessages] turns is compacted: older turns
  /// are folded into a single user-role summary message inserted right after
  /// the system prompt, while the trailing [kMaxHistoryMessages] turns are
  /// forwarded verbatim. The token budget keeps the whole context bounded.
  List<Map<String, String>> _buildMessages(
    List<ChatMessage> history,
    String userMessage,
  ) {
    final CompactedContext context = compactChatHistory(
      history,
      config: CompactionConfig(keepRecentMessages: kMaxHistoryMessages),
    );
    return buildWireMessages(
      systemPrompt: _buildSystemPrompt(),
      context: context,
      userMessage: userMessage,
    );
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
    final List<ServerRosterEntry>? servers = _rosterGetter?.call();
    if (servers != null && servers.isNotEmpty) {
      sb.write('\n\n## Configured Servers\n');
      for (final ServerRosterEntry server in servers) {
        sb.write('- $server\n');
      }
      sb.write(
        '\nUse "# server: <name>" in code blocks to target a specific '
        'server, including ones marked [not connected] — the system will '
        'connect them automatically when the user has enabled auto-connect.',
      );
    } else {
      sb.write('\n\n## Configured Servers\n');
      sb.write('No servers are configured yet. The user can add servers in '
          'the Servers page of the app.');
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
