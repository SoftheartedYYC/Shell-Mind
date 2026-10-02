import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/result.dart';
import '../../features/ssh_terminal/data/ssh_client_manager.dart';
import 'ssh_session_registry.dart';

/// Outcome of running one command on one server through [SshCommandExecutor].
///
/// Carries everything a caller (typically the AI assistant) needs to reason
/// about and present the result: which server ran it, the exact command, the
/// split stdout/stderr, the remote exit code, wall-clock duration, and a
/// convenience [success] flag.
class CommandResult {
  const CommandResult({
    required this.serverId,
    required this.serverName,
    required this.command,
    required this.stdout,
    required this.stderr,
    required this.exitCode,
    required this.elapsed,
    required this.executedAt,
  });

  /// UUID of the server that executed [command].
  final String serverId;

  /// Human-readable server label at execution time.
  final String serverName;

  /// The exact command string sent to the remote host.
  final String command;

  /// Captured standard output (decoded UTF-8).
  final String stdout;

  /// Captured standard error (decoded UTF-8).
  final String stderr;

  /// Remote exit code; `-1` when the server did not report one.
  final int exitCode;

  /// Wall-clock time the execution took.
  final Duration elapsed;

  /// When execution completed.
  final DateTime executedAt;

  /// True when the remote process exited cleanly (`exitCode == 0`).
  bool get success => exitCode == 0;

  @override
  String toString() =>
      'CommandResult(server: "$serverName", command: "$command", '
      'exitCode: $exitCode, ${elapsed.inMilliseconds}ms, '
      'stdout: ${stdout.length} chars, stderr: ${stderr.length} chars)';
}

/// Executes shell commands over the `exec` channel of already-connected SSH
/// sessions tracked by the [SshSessionRegistry].
///
/// Every call is non-interactive and independent of the terminal's PTY shell,
/// so running a command never disturbs what the user sees on screen. Results
/// are wrapped in the project's [Result] / [AppFailure] taxonomy — callers
/// never have to catch raw SSH exceptions.
class SshCommandExecutor {
  const SshCommandExecutor(this._ref);

  final Ref _ref;

  /// Default per-command timeout when the caller doesn't supply one.
  static const Duration defaultTimeout = Duration(seconds: 30);

  /// Runs [command] on the server identified by [serverId].
  ///
  /// Fails with [FailureKind.notFound] when that server has no live session,
  /// [FailureKind.timeout] when it exceeds [timeout], and [FailureKind.ssh]
  /// for any transport/protocol error.
  Future<Result<CommandResult>> execute({
    required String serverId,
    required String command,
    Duration timeout = defaultTimeout,
  }) async {
    final RegisteredSession? session =
        _ref.read(sshSessionRegistryProvider.notifier).getSession(serverId);
    if (session == null) {
      return Result<CommandResult>.failure(
        AppFailure.notFound(
          message: 'No active SSH session for server "$serverId".',
        ),
      );
    }
    return _runOnSession(session, command, timeout);
  }

  /// Runs the same [command] across [serverIds].
  ///
  /// When [parallel] is true the commands fan out concurrently via
  /// `Future.wait`; otherwise they run one after another. The returned list is
  /// positionally aligned with [serverIds], and each entry independently
  /// reports success or failure so one bad server doesn't abort the batch.
  Future<List<Result<CommandResult>>> executeOnMultiple({
    required List<String> serverIds,
    required String command,
    bool parallel = true,
    Duration timeout = defaultTimeout,
  }) async {
    if (serverIds.isEmpty) return const <Result<CommandResult>>[];

    if (parallel) {
      return Future.wait<Result<CommandResult>>(
        serverIds.map(
          (String id) => execute(serverId: id, command: command, timeout: timeout),
        ),
      );
    }

    final List<Result<CommandResult>> results = <Result<CommandResult>>[];
    for (final String id in serverIds) {
      results.add(await execute(serverId: id, command: command, timeout: timeout));
    }
    return results;
  }

  /// Runs [command] on the implicit default server — the most recently
  /// connected session in the registry.
  ///
  /// Fails with [FailureKind.notFound] when no server is online.
  Future<Result<CommandResult>> executeOnDefault({
    required String command,
    Duration timeout = defaultTimeout,
  }) async {
    final RegisteredSession? session =
        _ref.read(sshSessionRegistryProvider.notifier).defaultSession;
    if (session == null) {
      return Result<CommandResult>.failure(
        AppFailure.notFound(
          message: 'No active SSH session to run the command on.',
        ),
      );
    }
    return _runOnSession(session, command, timeout);
  }

  // ─── Internals ─────────────────────────────────────────────────────────

  /// Shared execution path: delegates to the manager's exec channel, times
  /// the run, and normalises every thrown error into an [AppFailure].
  Future<Result<CommandResult>> _runOnSession(
    RegisteredSession session,
    String command,
    Duration timeout,
  ) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    final Result<CommandResult> result =
        await Result.guard<CommandResult>(() async {
      final CommandExecutionResult exec =
          await session.manager.runCommand(command, timeout: timeout);
      stopwatch.stop();
      return CommandResult(
        serverId: session.serverId,
        serverName: session.serverName,
        command: command,
        stdout: exec.stdout,
        stderr: exec.stderr,
        exitCode: exec.exitCode,
        elapsed: stopwatch.elapsed,
        executedAt: DateTime.now(),
      );
    }, onError: (Object error, StackTrace stack) {
      stopwatch.stop();
      // runCommand already maps to AppFailure inside AppFailureException;
      // reuse that when present, otherwise fall back to SshClientManager's
      // mapper so transport errors stay categorised.
      if (error is AppFailureException) return error.failure;
      return SshClientManager.mapError(error);
    });
    return result;
  }

  /// Heuristic screen for commands that could cause destructive or
  /// irreversible damage on a remote host. Callers (e.g. the AI assistant)
  /// should surface a confirmation prompt when this returns `true`.
  static bool isDangerous(String command) {
    const List<String> patterns = <String>[
      r'rm\s+(-[a-zA-Z]*f[a-zA-Z]*\s+)?/', // rm -rf /
      r'mkfs\.', // filesystem format
      r'dd\s+if=', // raw disk write
      r'>\s*/dev/sd', // overwrite a block device
      r'shutdown',
      r'reboot',
      r'halt',
      r'init\s+0',
      r':\(\)\s*\{.*\};\s*:', // fork bomb
      r'chmod\s+-R\s+777\s+/', // recursive world-writable root
    ];
    return patterns.any((String p) => RegExp(p).hasMatch(command));
  }
}

/// Provider exposing the [SshCommandExecutor].
///
/// Cheap, stateless helper bound to the container's [Ref]; not `autoDispose`
/// so it can be read from anywhere without churning instances.
final Provider<SshCommandExecutor> sshCommandExecutorProvider =
    Provider<SshCommandExecutor>(SshCommandExecutor.new);
