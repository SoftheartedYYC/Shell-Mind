import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/command_audit_log.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/result.dart';
import '../../core/storage/preferences_service.dart';
import '../../features/ai_chat/presentation/providers/chat_providers.dart';
import '../../features/server_config/domain/entities/server_config.dart';
import '../../features/server_config/presentation/providers/server_config_providers.dart';
import './command_block_parser.dart';
import 'ssh_command_executor.dart';
import 'ssh_server_connect_controller.dart';
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

/// Machine-readable kind of the last agent error.
///
/// Lets the UI map [AgentState.errorKind] to a localised message instead of
/// rendering the raw (Chinese-only) fallback strings. [unexpected] is the
/// catch-all for genuinely unpredictable exceptions where the raw
/// `e.toString()` text in [AgentState.errorMessage] is shown as-is.
enum AgentErrorKind {
  /// No target server was selected / available for execution.
  noTargetServer,

  /// A confirmed or auto-loop command execution failed.
  execFailed,

  /// A dangerous command was skipped during the auto loop.
  dangerSkipped,

  /// AI auto-connect failed because the server has no usable saved
  /// credential (auth kind).
  connectAuthRequired,

  /// AI auto-connect failed for a non-credential reason (unreachable host,
  /// handshake error, unknown config …).
  connectFailed,

  /// Unpredictable exception — no localised equivalent exists.
  unexpected,
}

/// Outcome of one on-demand connect attempt performed by [AgentController].
enum AgentConnectOutcome {
  /// The session went live.
  success,

  /// The server has no usable saved credential.
  authRequired,

  /// Any other failure (unreachable, handshake, unknown config …).
  failed,

  /// No live session and the auto-connect switch is off — the caller keeps
  /// the legacy noTargetServer behaviour.
  offline,
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
    this.errorKind,
    this.errorArg,
    this.results = const <CommandResult>[],
    this.taskRounds = 0,
    this.taskStartedAt,
  });

  final AgentStatus status;
  final bool isAutoMode;
  final String? executingServerId;
  final String? executingServerName;
  final String? executingCommand;
  final int autoLoopCount;
  final int maxAutoLoops;
  final String? errorMessage;

  /// Machine-readable kind behind [errorMessage]; `null` when the message is
  /// a raw exception (kind [AgentErrorKind.unexpected] keeps it populated).
  final AgentErrorKind? errorKind;

  /// Dynamic interpolation value for the localised message (e.g. the
  /// truncated command for [AgentErrorKind.dangerSkipped]).
  final String? errorArg;

  /// Display-only chain of command results for the current task / session,
  /// in execution order (newest last). Rendered by the agent timeline sheet.
  final List<CommandResult> results;

  /// Display-only count of completed execution rounds (confirmed batches and
  /// auto loops) belonging to the current task / session.
  final int taskRounds;

  /// Display-only moment the current task / session chain started, used by
  /// the timeline header to show a start–end time range.
  final DateTime? taskStartedAt;

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
          errorMessage == other.errorMessage &&
          errorKind == other.errorKind &&
          errorArg == other.errorArg &&
          taskRounds == other.taskRounds &&
          taskStartedAt == other.taskStartedAt &&
          _listEquals(results, other.results);

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
        errorKind,
        errorArg,
        taskRounds,
        taskStartedAt,
        Object.hashAll(results),
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
    AgentErrorKind? errorKind,
    String? errorArg,
    List<CommandResult>? results,
    int? taskRounds,
    DateTime? taskStartedAt,
    bool clearExecuting = false,
    bool clearError = false,
    bool clearTask = false,
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
      // errorKind / errorArg follow errorMessage's lifecycle: [clearError]
      // resets all three; a brand-new message without an explicit kind/arg
      // drops the previous ones so a stale kind can never be mapped onto a
      // different message; when no new message arrives both persist (matching
      // the raw-message fallback behaviour).
      errorKind: clearError
          ? null
          : (errorKind ?? (errorMessage != null ? null : this.errorKind)),
      errorArg: clearError
          ? null
          : (errorArg ?? (errorMessage != null ? null : this.errorArg)),
      results: clearTask ? const <CommandResult>[] : (results ?? this.results),
      taskRounds: clearTask ? 0 : (taskRounds ?? this.taskRounds),
      taskStartedAt: clearTask ? null : (taskStartedAt ?? this.taskStartedAt),
    );
  }

  @override
  String toString() =>
      'AgentState(status: $status, autoMode: $isAutoMode, '
      'loops: $autoLoopCount/$maxAutoLoops, results: ${results.length})';
}

/// Structural comparison for [AgentState.results]. Element-wise `==` is
/// sufficient: results are immutable snapshots appended once and never
/// mutated, so identity-level comparison is stable across state copies.
bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// AI Agent controller managing both confirmed execution and auto-loop modes.
///
/// Entry points:
/// - [executeConfirmed] — the user tapped "run" on a code block and confirmed;
///   executes once and feeds the result back into the conversation.
/// - [startAutoMode] + [onAssistantResponseComplete] — a hands-off loop where
///   every finished AI reply is scanned for command blocks, executed, and the
///   results are sent back so the model can continue, up to [AgentState.maxAutoLoops].
/// - [onAssistantResponseComplete] standalone — when the settings master
///   switch (`aiAutoExecute`) is on, the first reply of a conversation arms
///   the loop automatically; no explicit start call is needed.
class AgentController extends Notifier<AgentState> {
  @override
  AgentState build() {
    // Default connect hook: route through [SshServerConnectController] so the
    // credential resolution and registry registration reuse the exact same
    // in-chat connection path the server picker uses. Overridable in tests
    // (see the existing dialer-injection pattern in SshSessionRegistry).
    connectHook = (String serverId, ServerConfig config) async {
      final SshServerConnectController controller =
          ref.read(sshServerConnectProvider.notifier);
      final bool ok = await controller.connect(config);
      if (ok) return AgentConnectOutcome.success;
      return _connectOutcomeFrom(controller, serverId);
    };
    return const AgentState();
  }

  /// Injectable dial hook for tests: resolves credentials, connects the
  /// server and returns the outcome. Bound to the real controller in build().
  @visibleForTesting
  late Future<AgentConnectOutcome> Function(String serverId, ServerConfig config)
      connectHook;

  /// Maps a failed connect attempt to a machine-readable outcome. Reads the
  /// attempt state published by [SshServerConnectController]: `failureKind`
  /// `'auth'` means no usable stored credential; anything else (or an absent
  /// entry) is a generic connection failure.
  AgentConnectOutcome _connectOutcomeFrom(
    SshServerConnectController controller,
    String serverId,
  ) {
    final SshServerConnectAttempt? attempt =
        controller.state[serverId];
    if (attempt?.failureKind == 'auth') return AgentConnectOutcome.authRequired;
    return AgentConnectOutcome.failed;
  }

  /// Confirmed mode: execute a single command (already confirmed by the user)
  /// on one or more servers, then append the results to the conversation.
  Future<Result<CommandResult>> executeConfirmed({
    required String command,
    required List<String> serverIds,
  }) async {
    if (serverIds.isEmpty) {
      // Defensive: the chat page pre-checks connectivity, so this message is
      // never rendered directly — the UI maps the failure kind instead.
      return Result<CommandResult>.failure(
        AppFailure.validation('No target server selected.'),
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
      // Display-only: anchor the timeline header on the first command.
      taskStartedAt: state.taskStartedAt ?? DateTime.now(),
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

      // Display-only: publish the batch to the timeline (real-time refresh).
      if (results.isNotEmpty) {
        state = state.copyWith(
          results: <CommandResult>[...state.results, ...results],
        );
      }

      if (results.isEmpty) {
        state = state.copyWith(
          status: AgentStatus.error,
          errorMessage: lastError ?? 'Command execution failed.',
          errorKind: AgentErrorKind.execFailed,
          clearExecuting: true,
        );
        return Result<CommandResult>.failure(
          AppFailure.ssh(lastError ?? 'Command execution failed.'),
        );
      }

      for (final CommandResult r in results) {
        unawaited(ref.read(commandAuditNotifierProvider.notifier).record(
              _auditEntryFrom(r, CommandAuditMode.confirmed),
            ));
      }

      // Feed results back into the chat (triggers a single AI follow-up).
      await ref.read(chatMessagesProvider.notifier).sendToolResults(results);

      state = state.copyWith(
        status: AgentStatus.idle,
        clearExecuting: true,
        errorMessage: lastError,
        taskRounds: state.taskRounds + 1,
      );
      return Result<CommandResult>.success(results.first);
    } catch (e) {
      // Genuinely unpredictable failures keep the raw `e.toString()` text
      // (localisation impossible by design); the kind lets the UI render a
      // generic localised prefix when one exists.
      state = state.copyWith(
        status: AgentStatus.error,
        errorMessage: e.toString(),
        errorKind: AgentErrorKind.unexpected,
        clearExecuting: true,
      );
      return Result<CommandResult>.failure(AppFailure.unexpected(e));
    }
  }

  /// Starts auto-execution mode. Subsequent AI replies will be scanned for
  /// command blocks and executed automatically until [stopAutoMode] or the
  /// loop limit is reached.
  ///
  /// The loop cap comes from [maxLoops] when given (tests / callers with an
  /// explicit budget); otherwise it is read live from the user's
  /// [PreferencesService] so a settings change applies without an app restart.
  ///
  /// Master gate: the settings "auto-execute commands" switch
  /// (`aiAutoExecute`) must be on for auto mode to start. When it is off the
  /// request is rejected, the state is left untouched and `false` is
  /// returned. Unreadable preferences (plain unit tests without an
  /// initialised [PreferencesService]) fail open so the loop mechanics stay
  /// observable there. In production this call is a legacy compatibility
  /// path: the chat UI no longer exposes a session toggle, and the settings
  /// switch arms the loop via [onAssistantResponseComplete] directly.
  bool startAutoMode({String? defaultServerId, int? maxLoops}) {
    bool gateOpen;
    try {
      gateOpen = ref.read(preferencesServiceProvider).aiAutoExecute;
    } catch (_) {
      gateOpen = true;
    }
    if (!gateOpen) return false;

    final int effectiveMax =
        maxLoops ?? ref.read(preferencesServiceProvider).aiMaxAutoLoops;
    state = state.copyWith(
      status: AgentStatus.idle,
      isAutoMode: true,
      autoLoopCount: 0,
      maxAutoLoops: effectiveMax,
      clearError: true,
    );
    return true;
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
  ///
  /// The loop arms itself from two sources:
  /// - an explicit [startAutoMode] call (legacy chat-bar entry), or
  /// - the settings master switch (`aiAutoExecute`): when it is on, the very
  ///   first reply of a conversation enters auto mode without any toggle.
  ///
  /// [isContinuation] marks a reply that was triggered by feeding tool results
  /// back (from either the auto loop or a confirmed execution). Continuations
  /// never arm the loop themselves: a user stop must survive in-flight
  /// continuations, and confirmed-execution follow-ups must stay non-automatic.
  void onAssistantResponseComplete(
    String responseContent, {
    bool isContinuation = false,
  }) {
    if (!state.isAutoMode) {
      // Unarmed: only the settings master switch may arm the loop here, and
      // never for a continuation. Unreadable preferences fail closed — the
      // safe default for autonomous command execution.
      if (isContinuation) return;
      bool gateOpen;
      try {
        gateOpen = ref.read(preferencesServiceProvider).aiAutoExecute;
      } catch (_) {
        gateOpen = false;
      }
      if (!gateOpen) return;

      state = state.copyWith(
        status: AgentStatus.idle,
        isAutoMode: true,
        autoLoopCount: 0,
        maxAutoLoops: ref.read(preferencesServiceProvider).aiMaxAutoLoops,
        clearError: true,
      );
    }
    if (state.status == AgentStatus.executing) return;
    if (state.autoLoopCount >= state.maxAutoLoops) {
      state = state.copyWith(status: AgentStatus.idle, isAutoMode: false);
      return;
    }

    final List<CommandBlock> blocks = CommandBlockParser.parse(responseContent);
    if (blocks.isEmpty) {
      // Nothing to run — the loop naturally terminates.
      state = state.copyWith(status: AgentStatus.idle, isAutoMode: false);
      // Surface completion when the app is backgrounded.
      unawaited(NotificationService.instance.notifyAiTaskComplete());
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
    state = state.copyWith(
      status: AgentStatus.executing,
      clearError: true,
      // Display-only: anchor the timeline header on the first auto command.
      taskStartedAt: state.taskStartedAt ?? DateTime.now(),
    );

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
            errorMessage: 'Skipped dangerous command: ${_truncate(block.command)}',
            errorKind: AgentErrorKind.dangerSkipped,
            errorArg: _truncate(block.command),
          );
          continue;
        }

        final String? explicitTarget =
            (block.targetServer != null && block.targetServer!.isNotEmpty)
                ? block.targetServer
                : null;
        String? serverId = _resolveServerId(
          block.targetServer,
          fallbackServerId,
          registry,
        );
        // A target needs dialing when nothing was resolved, when the resolved
        // id has no live session behind it, or when the block names a specific
        // server that is not the live session the fallback produced — an
        // offline explicit target must never silently reroute elsewhere.
        // The entry alone is not enough: a session that dropped unexpectedly
        // (auto-reconnect in progress or the loop already gave up) keeps its
        // registry entry but its manager is disposed, so liveness is checked
        // explicitly — otherwise the command would hit a dead transport.
        final bool needsDial = serverId == null ||
            serverId.isEmpty ||
            registry.getSession(serverId) == null ||
            !registry.getSession(serverId)!.isConnected ||
            (explicitTarget != null &&
                registry.getSession(serverId)!.serverName != explicitTarget);
        if (needsDial) {
          final String? dialledId = await _ensureSessionLive(
            explicitTarget: explicitTarget,
            resolvedServerId: explicitTarget == null ? serverId : null,
          );
          if (dialledId == null) break; // error state already published
          serverId = dialledId;
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
          unawaited(ref.read(commandAuditNotifierProvider.notifier).record(
                _auditEntryFrom(result.valueOrNull!, CommandAuditMode.auto),
              ));
          // Display-only: publish each result to the timeline as it lands so
          // the sheet refreshes in real time while a round is still running.
          state = state.copyWith(
            results: <CommandResult>[...state.results, result.valueOrNull!],
          );
        } else {
          state = state.copyWith(
            errorMessage: result.failureOrNull!.failure.message,
          );
        }
      }

      state = state.copyWith(
        status: AgentStatus.idle,
        autoLoopCount: state.autoLoopCount + 1,
        taskRounds: state.taskRounds + 1,
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
        errorKind: AgentErrorKind.unexpected,
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

  /// Makes sure a live session exists for the resolved target before command
  /// execution — the AI auto-connect path.
  ///
  /// When the user enabled `aiAutoConnect`, an offline-but-configured target
  /// is dialled on demand through the injectable [connectHook] (production
  /// wiring resolves credentials from the secure keystore and registers the
  /// session via [SshServerConnectController], which shares the registry's
  /// TOFU host-key dialog and trust store). Failure outcomes map onto the
  /// machine-readable [AgentErrorKind]s the UI localises; with the switch off
  /// the legacy [AgentErrorKind.noTargetServer] behaviour is preserved.
  ///
  /// Returns the live server id on success, or `null` after publishing the
  /// terminal error state.
  Future<String?> _ensureSessionLive({
    required String? explicitTarget,
    required String? resolvedServerId,
  }) async {
    bool autoConnect;
    try {
      autoConnect = ref.read(preferencesServiceProvider).aiAutoConnect;
    } catch (_) {
      // Preferences not initialised (plain unit tests) — fail closed: the
      // agent must never dial without the user's explicit consent.
      autoConnect = false;
    }
    if (!autoConnect) {
      state = state.copyWith(
        status: AgentStatus.error,
        errorMessage: 'No target server available.',
        errorKind: AgentErrorKind.noTargetServer,
        clearExecuting: true,
      );
      return null;
    }

    // Resolve the offline target against the saved fleet: an explicit
    // `# server:` name wins, then the resolved id (stale fallback/default).
    // Await the async fleet (not valueOrNull) so a not-yet-loaded list still
    // resolves instead of degrading to noTargetServer.
    List<ServerConfig> fleet;
    try {
      fleet = await ref.read(serverConfigListProvider.future);
    } catch (_) {
      fleet = const <ServerConfig>[];
    }
    ServerConfig? config;
    if (explicitTarget != null) {
      for (final ServerConfig c in fleet) {
        if (c.name == explicitTarget) {
          config = c;
          break;
        }
      }
    }
    if (config == null &&
        resolvedServerId != null &&
        resolvedServerId.isNotEmpty) {
      for (final ServerConfig c in fleet) {
        if (c.id == resolvedServerId) {
          config = c;
          break;
        }
      }
    }
    if (config == null) {
      state = state.copyWith(
        status: AgentStatus.error,
        errorMessage: 'No target server available.',
        errorKind: AgentErrorKind.noTargetServer,
        clearExecuting: true,
      );
      return null;
    }

    final AgentConnectOutcome outcome = await connectHook(config.id, config);
    switch (outcome) {
      case AgentConnectOutcome.success:
        return config.id;
      case AgentConnectOutcome.authRequired:
        state = state.copyWith(
          status: AgentStatus.error,
          errorMessage: 'Server has no saved credentials.',
          errorKind: AgentErrorKind.connectAuthRequired,
          clearExecuting: true,
        );
        return null;
      case AgentConnectOutcome.failed:
        state = state.copyWith(
          status: AgentStatus.error,
          errorMessage: 'Failed to connect to the server automatically.',
          errorKind: AgentErrorKind.connectFailed,
          clearExecuting: true,
        );
        return null;
      case AgentConnectOutcome.offline:
        // Documented as "switch off" — keep the legacy behaviour.
        state = state.copyWith(
          status: AgentStatus.error,
          errorMessage: 'No target server available.',
          errorKind: AgentErrorKind.noTargetServer,
          clearExecuting: true,
        );
        return null;
    }
  }

  String _truncate(String command) =>
      command.length > 40 ? '${command.substring(0, 40)}…' : command;

  /// Builds a privacy-safe audit entry from an execution result. The full
  /// output is never stored — only a boolean flag and a 200-char summary.
  CommandAuditEntry _auditEntryFrom(CommandResult r, CommandAuditMode mode) {
    final String summary =
        CommandAuditEntry.summarizeOutput(r.stdout, r.stderr);
    return CommandAuditEntry(
      id: CommandAuditLog.instance.newEntryId(),
      command: r.command,
      serverId: r.serverId,
      serverName: r.serverName,
      exitCode: r.exitCode,
      success: r.success,
      mode: mode,
      executedAt: r.executedAt,
      elapsed: r.elapsed,
      hasDangerous: SshCommandExecutor.isDangerous(r.command),
      hasOutput: summary.isNotEmpty,
      outputSummary: summary,
    );
  }
}

/// Provider for the [AgentController].
final NotifierProvider<AgentController, AgentState> agentControllerProvider =
    NotifierProvider<AgentController, AgentState>(AgentController.new);
