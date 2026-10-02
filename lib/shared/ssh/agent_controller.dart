import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/result.dart';
import '../../features/ai_chat/presentation/providers/chat_providers.dart';
import './command_block_parser.dart';
import 'ssh_command_executor.dart';
import 'ssh_session_registry.dart';

/// Current status of the AI Agent loop.
enum AgentStatus {
  /// No active operation.
  idle,

  /// Currently executing commands (user confirmed or auto mode).
  executing,

  /// Waiting for user confirmation on a dangerous command.
  waitingConfirm,

  /// User manually stopped the loop.
  stopped,

  /// An error occurred.
  error,
}

/// Agent execution state with immutability guarantees.
@immutable
class AgentState {
  const AgentState({
    this.status = AgentStatus.idle,
    this.isAutoMode = false,
    this.executingServerId,
    this.executingServerName,
    this.executingCommand,
    this.autoLoopCount = 0,
    this.maxAutoLoops = 5,
    this.errorMessage,
  });

  final AgentStatus status;
  final bool isAutoMode;
  final String? executingServerId;
  final String? executingServerName;
  final String? executingCommand;
  final int autoLoopCount;
  final int maxAutoLoops;
  final String? errorMessage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          isAutoMode == other.isAutoMode &&
          executingServerId == other.executingServerId &&
          executingServerName == other.executingServerName &&
          executingCommand == other.executingCommand &&
          autoLoopCount == other.autoLoopCount &&
          maxAutoLoops == other.maxAutoLoops &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(
        status,
        isAutoMode,
        executingServerId,
        executingServerName,
        executingCommand,
        autoLoopCount,
        maxAutoLoops,
        errorMessage,
      );

  AgentState copyWith({
    AgentStatus? status,
    bool? isAutoMode,
    String? executingServerId,
    String? executingServerName,
    String? executingCommand,
    int? autoLoopCount,
    int? maxAutoLoops,
    String? errorMessage,
    bool clearExecuting = false,
    bool clearError = false,
  }) {
    return AgentState(
      status: status ?? this.status,
      isAutoMode: isAutoMode ?? this.isAutoMode,
      executingServerId:
          clearExecuting ? null : (executingServerId ?? this.executingServerId),
      executingServerName:
          clearExecuting ? null : (executingServerName ?? this.executingServerName),
      executingCommand:
          clearExecuting ? null : (executingCommand ?? this.executingCommand),
      autoLoopCount: autoLoopCount ?? this.autoLoopCount,
      maxAutoLoops: maxAutoLoops ?? this.maxAutoLoops,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  String toString() =>
      'AgentState(status: $status, autoMode: $isAutoMode, '
      'loops: $autoLoopCount/$maxAutoLoops)';
}

/// AI Agent controller managing both confirmed execution and auto-loop modes.
///
/// Two entry points:
/// - [executeConfirmed] — the user tapped "run" on a code block and confirmed;
///   executes once and feeds the result back into the conversation.
/// - [startAutoMode] + [onAssistantResponseComplete] — a hands-off loop where
///   every finished AI reply is scanned for command blocks, executed, and the
///   results are sent back so the model can continue, up to [AgentState.maxAutoLoops].
class AgentController extends Notifier<AgentState> {
  @override
  AgentState build() => const AgentState();

  /// Confirmed mode: execute a single command (already confirmed by the user)
  /// on one or more servers, then append the results to the conversation.
  Future<Result<CommandResult>> executeConfirmed({
    required String command,
    required List<String> serverIds,
  }) async {
    if (serverIds.isEmpty) {
      return Result<CommandResult>.failure(
        AppFailure.validation('没有选择目标服务器'),
      );
    }

    final SshSessionRegistry registry =
        ref.read(sshSessionRegistryProvider.notifier);
    final RegisteredSession? first = registry.getSession(serverIds.first);

    state = state.copyWith(
      status: AgentStatus.executing,
      executingServerId: serverIds.first,
      executingServerName: first?.serverName,
      executingCommand: _truncate(command),
      isAutoMode: false,
      clearError: true,
    );

    try {
      final SshCommandExecutor executor = ref.read(sshCommandExecutorProvider);
      final List<Result<CommandResult>> raw =
          await executor.executeOnMultiple(
        serverIds: serverIds,
        command: command,
        parallel: serverIds.length > 1,
      );

      final List<CommandResult> results = <CommandResult>[];
      String? lastError;
      for (final Result<CommandResult> r in raw) {
        if (r.isSuccess) {
          results.add(r.valueOrNull!);
        } else {
          lastError = r.failureOrNull!.failure.message;
        }
      }

      if (results.isEmpty) {
        state = state.copyWith(
          status: AgentStatus.error,
          errorMessage: lastError ?? '命令执行失败',
          clearExecuting: true,
        );
        return Result<CommandResult>.failure(
          AppFailure.ssh(lastError ?? '命令执行失败'),
        );
      }

      // Feed results back into the chat (triggers a single AI follow-up).
      await ref.read(chatMessagesProvider.notifier).sendToolResults(results);

      state = state.copyWith(
        status: AgentStatus.idle,
        clearExecuting: true,
        errorMessage: lastError,
      );
      return Result<CommandResult>.success(results.first);
    } catch (e) {
      state = state.copyWith(
        status: AgentStatus.error,
        errorMessage: e.toString(),
        clearExecuting: true,
      );
      return Result<CommandResult>.failure(AppFailure.unexpected(e));
    }
  }

  /// Starts auto-execution mode. Subsequent AI replies will be scanned for
  /// command blocks and executed automatically until [stopAutoMode] or the
  /// loop limit is reached.
  void startAutoMode({String? defaultServerId, int maxLoops = 5}) {
    state = state.copyWith(
      status: AgentStatus.idle,
      isAutoMode: true,
      autoLoopCount: 0,
      maxAutoLoops: maxLoops,
      clearError: true,
    );
  }

  /// Stops auto-loop mode immediately.
  void stopAutoMode() {
    state = state.copyWith(
      status: AgentStatus.stopped,
      isAutoMode: false,
      clearExecuting: true,
    );
  }

  /// Called by the chat page when the AI finishes streaming a reply.
  ///
  /// In auto mode, parses [responseContent] for executable command blocks and,
  /// when any are found, executes them and feeds the results back — which in
  /// turn produces the next AI reply and re-enters this method.
  void onAssistantResponseComplete(String responseContent) {
    if (!state.isAutoMode) return;
    if (state.status == AgentStatus.executing) return;
    if (state.autoLoopCount >= state.maxAutoLoops) {
      state = state.copyWith(status: AgentStatus.idle, isAutoMode: false);
      return;
    }

    final List<CommandBlock> blocks = CommandBlockParser.parse(responseContent);
    if (blocks.isEmpty) {
      // Nothing to run — the loop naturally terminates.
      state = state.copyWith(status: AgentStatus.idle, isAutoMode: false);
      return;
    }

    final SshSessionRegistry registry =
        ref.read(sshSessionRegistryProvider.notifier);
    unawaited(_executeAndFeedback(blocks, registry.defaultSession?.serverId));
  }

  /// Resets the controller to its initial state.
  void reset() {
    state = const AgentState();
  }

  // ─── Internals ─────────────────────────────────────────────────────────

  /// Executes [blocks] in order, collecting successful results, then sends
  /// them back to the conversation in a single batch.
  Future<void> _executeAndFeedback(
    List<CommandBlock> blocks,
    String? fallbackServerId,
  ) async {
    state = state.copyWith(status: AgentStatus.executing, clearError: true);

    final SshSessionRegistry registry =
        ref.read(sshSessionRegistryProvider.notifier);
    final SshCommandExecutor executor = ref.read(sshCommandExecutorProvider);
    final List<CommandResult> results = <CommandResult>[];

    try {
      for (final CommandBlock block in blocks) {
        if (!state.isAutoMode || state.status == AgentStatus.stopped) break;

        // Dangerous commands are never auto-executed — skip and surface a note.
        if (SshCommandExecutor.isDangerous(block.command)) {
          state = state.copyWith(
            errorMessage: '已跳过危险命令：${_truncate(block.command)}',
          );
          continue;
        }

        final String? serverId = _resolveServerId(
          block.targetServer,
          fallbackServerId,
          registry,
        );
        if (serverId == null || serverId.isEmpty) {
          state = state.copyWith(
            status: AgentStatus.error,
            errorMessage: '没有可用的目标服务器',
            clearExecuting: true,
          );
          break;
        }

        final RegisteredSession? session = registry.getSession(serverId);
        state = state.copyWith(
          executingServerId: serverId,
          executingServerName: session?.serverName,
          executingCommand: _truncate(block.command),
        );

        final Result<CommandResult> result = await executor.execute(
          serverId: serverId,
          command: block.command,
        );
        if (result.isSuccess) {
          results.add(result.valueOrNull!);
        } else {
          state = state.copyWith(
            errorMessage: result.failureOrNull!.failure.message,
          );
        }
      }

      state = state.copyWith(
        status: AgentStatus.idle,
        autoLoopCount: state.autoLoopCount + 1,
        clearExecuting: true,
      );

      if (results.isNotEmpty) {
        // Triggers one AI continuation; when it finishes streaming the chat
        // page calls onAssistantResponseComplete again for the next loop.
        await ref.read(chatMessagesProvider.notifier).sendToolResults(results);
      }
    } catch (e) {
      state = state.copyWith(
        status: AgentStatus.error,
        errorMessage: e.toString(),
        clearExecuting: true,
      );
    }
  }

  /// Resolves the target server for a block: an explicit `# server:` tag wins,
  /// then the caller's fallback, then the registry default.
  String? _resolveServerId(
    String? targetServer,
    String? fallbackServerId,
    SshSessionRegistry registry,
  ) {
    if (targetServer != null && targetServer.isNotEmpty) {
      for (final RegisteredSession s in registry.activeSessions) {
        if (s.serverName == targetServer) return s.serverId;
      }
    }
    if (fallbackServerId != null && fallbackServerId.isNotEmpty) {
      return fallbackServerId;
    }
    return registry.defaultSession?.serverId;
  }

  String _truncate(String command) =>
      command.length > 40 ? '${command.substring(0, 40)}…' : command;
}

/// Provider for the [AgentController].
final NotifierProvider<AgentController, AgentState> agentControllerProvider =
    NotifierProvider<AgentController, AgentState>(AgentController.new);
