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
  ///
  /// Deliberately conservative: patterns aim at *obvious* destruction only
  /// (wiping the home directory, deleting via `find -delete`, truncating a
  /// file to zero) while avoiding false positives where these tokens appear
  /// merely as substrings of paths or other flags.
  ///
  /// GNU-style long options are normalised to their short forms *before*
  /// matching (`--recursive` → `-r`, `--force` → `-f`), so variants like
  /// `rm --recursive --force ~` hit the same detectors as `rm -rf ~`. The
  /// rewrite is guarded on both sides (lookbehind/lookahead) so flag-looking
  /// words such as `--recursive-dir` or `x--force` are left untouched.
  static bool isDangerous(String command) {
    final String normalized = command
        .replaceAllMapped(
          RegExp(r'(?<![\w-])--recursive(?![\w=-])'),
          (_) => '-r',
        )
        .replaceAllMapped(
          RegExp(r'(?<![\w-])--force(?![\w=-])'),
          (_) => '-f',
        );
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
      // Recursive world-writable root. `-r` is not a real chmod flag (the
      // tool uses `-R`), but normalisation rewrites `chmod --recursive`
      // to `-r`, so both spellings are accepted here — the false-positive
      // cost (an invalid command being skipped with a warning) is far below
      // the leak cost of missing the real thing.
      r'chmod\s+-(?:R|r)\s+777\s+/', // recursive world-writable root
      // `rm -rf ~` & variants (`-fr`, `-r -f`, `$HOME`, `${HOME}`, `~/sub`,
      // `~user`). Two scanning lookaheads require *some* flag token carrying
      // `r` AND *some* flag carrying `f` (combined or separate), so
      // `rm -r dir`, `rm -f file` and absolute paths stay out of scope. The
      // word-boundary lookbehind keeps `myrm`/`xrm` from matching.
      // Same detector for multi-flag clusters and the bare-root target:
      // covers `rm -r -f ~`, and — after normalisation — the long-option
      // forms (`rm --recursive --force ~`). The `/` alternative extends the
      // reach to `rm -r -f /` / `rm --recursive --force /` where the single
      // cluster pattern above cannot see two separate flags.
      r'(?<![\w/.~-])(?:sudo\s+)?rm\s+'
      r'(?=(?:\s*-[a-zA-Z]+)+\s)'
      r'(?=(?:\s*-[a-zA-Z]+)*\s*-[a-zA-Z]*r[a-zA-Z]*\b)'
      r'(?=(?:\s*-[a-zA-Z]+)*\s*-[a-zA-Z]*f[a-zA-Z]*\b)'
      r'(?:\s*-[a-zA-Z]+)+\s+'
      r'(?:~[A-Za-z0-9_.+-]*(?:/\S*)?|\$HOME(?:/\S*)?|\$\{HOME\}(?:/\S*)?|/)'
      r'(?:\s|$)',
      // `find ... -delete` — mass deletion through find's own action flag.
      // The `[^;|&]*` span may not cross command separators, and the
      // lookbehind rejects `-delete` glued to a longer word (`-delete-me`).
      r'(?<![\w/.-])find\s+[^;|&]*(?<![\w-])-delete(?:\s|$)',
      // `truncate -s 0 <file>` (`-s0`, `--size=0`, `--size 0`, extra flags
      // and an optional `sudo` prefix) — empty a file in place. The `0` must
      // be a standalone word so `-s 100` never matches.
      r'(?<![\w/.-])(?:sudo\s+)?truncate\s+(?:-\w+\s+)*'
      r'(?:-s0(?=\s|$)|-s\s+0(?=\s|$)|--size(?:=|\s+)0(?=\s|$))',
    ];
    return patterns.any((String p) => RegExp(p).hasMatch(normalized));
  }
}

/// Provider exposing the [SshCommandExecutor].
///
/// Cheap, stateless helper bound to the container's [Ref]; not `autoDispose`
/// so it can be read from anywhere without churning instances.
final Provider<SshCommandExecutor> sshCommandExecutorProvider =
    Provider<SshCommandExecutor>(SshCommandExecutor.new);
