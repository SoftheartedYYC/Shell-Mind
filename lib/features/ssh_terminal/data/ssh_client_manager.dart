import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/result.dart';
import '../../../shared/ssh/host_key_store.dart';
import '../domain/entities/connection_state.dart';

/// Machine-readable marker placed in `AppFailure.details['reason']` when the
/// user declined the first-connect trust prompt. The presentation layer
/// checks this marker to render a localised, host-key-specific error.
const String hostKeyRejectionReason = 'host_key_rejected';

/// Marker for the more severe case: a stored fingerprint does not match the
/// key the server just presented (possible MITM or server reinstall). Kept
/// distinct from [hostKeyRejectionReason] so the UI can escalate the wording.
const String hostKeyMismatchReason = 'host_key_mismatch';

/// Immutable result of a non-interactive `exec` command run over SSH.
///
/// Produced by [SshClientManager.runCommand]; deliberately decoupled from
/// `dartssh2`'s own `SSHRunResult` so callers don't depend on the transport
/// type and receive already-decoded strings.
@immutable
class CommandExecutionResult {
  const CommandExecutionResult({
    required this.stdout,
    required this.stderr,
    required this.exitCode,
  });

  /// Decoded standard output.
  final String stdout;

  /// Decoded standard error.
  final String stderr;

  /// Remote process exit code. `-1` when the server did not report one
  /// (e.g. the command was killed by a signal).
  final int exitCode;

  /// Convenience: exit code == 0.
  bool get isSuccess => exitCode == 0;

  @override
  String toString() =>
      'CommandExecutionResult(exitCode: $exitCode, '
      'stdout: ${stdout.length} chars, stderr: ${stderr.length} chars)';
}

/// Low-level wrapper around a single `dartssh2` interactive shell.
///
/// Owns the full transport stack — [SSHSocket] → [SSHClient] → shell
/// [SSHSession] — and translates its lifecycle into [SshConnectionState]
/// events plus a merged byte stream of remote output. It intentionally manages
/// exactly one connection at a time (the app shows one terminal page), so
/// [connect] tears down any previous link before dialing.
///
/// Errors never escape as raw protocol exceptions: they are funnelled through
/// [mapError] into an [AppFailure] and re-thrown as [AppFailureException] so
/// the repository layer can convert them into a [Failure] result.
class SshClientManager {
  /// Creates the manager.
  ///
  /// [hostKeyStore] persists trusted host-key fingerprints keyed by
  /// `<host>_<port>`; defaults to a non-persisting in-memory store. Without a
  /// store every session would be treated as a first connection.
  ///
  /// [hostKeyApprovalHandler] resolves the user-facing trust prompt for
  /// first-time connections: receives `(host, port, fingerprint)` and returns
  /// `true` when the user chose to trust the host. It is only invoked when no
  /// record exists yet — a stored match skips it, a stored mismatch rejects
  /// outright. Defaults to auto-accept (legacy behaviour) so plain
  /// `SshClientManager()` usages keep working; the app wires a dialog-based
  /// handler at the registry layer.
  SshClientManager({
    HostKeyStore? hostKeyStore,
    this._hostKeyApprovalHandler,
  }) : _hostKeyStore = hostKeyStore ?? InMemoryHostKeyStore();

  final HostKeyStore _hostKeyStore;
  final Future<bool> Function(String host, int port, String fingerprint)?
      _hostKeyApprovalHandler;

  /// Outcome of the most recent host-key rejection during the in-flight
  /// [connect] (user declined vs fingerprint change), threaded into the
  /// resulting [AppFailure.details] for localisation. Reset per attempt.
  ///
  /// Safe as a single field: [_connecting] serialises every [connect] on this
  /// manager, so the KEX-callback write and the catch-block read always belong
  /// to the same attempt. The *endpoint*, by contrast, is passed per-connection
  /// through a closure (see [connect]) because the dartssh2 host-key callback
  /// carries no endpoint identity of its own.
  HostKeyRejection? _hostKeyRejection;

  SSHSocket? _socket;
  SSHClient? _client;
  SSHSession? _shell;

  StreamSubscription<Uint8List>? _stdoutSub;
  StreamSubscription<Uint8List>? _stderrSub;

  final StreamController<Uint8List> _outputController =
      StreamController<Uint8List>.broadcast();
  final StreamController<SshConnectionState> _stateController =
      StreamController<SshConnectionState>.broadcast();

  SshConnectionState _state = const SshConnectionState.disconnected();
  String? _serverName;
  bool _connecting = false;
  bool _intentionalClose = false;
  bool _disposed = false;

  // ─── Public surface ────────────────────────────────────────────────────

  /// Merged stdout + stderr from the remote shell, as raw UTF-8 bytes.
  Stream<Uint8List> get outputStream => _outputController.stream;

  /// Connection-state transitions.
  Stream<SshConnectionState> get stateStream => _stateController.stream;

  /// Latest emitted state.
  SshConnectionState get currentState => _state;

  bool get isConnected => _state.status == SshConnectionStatus.connected;

  /// Whether this manager routes the first-connect trust prompt through a
  /// user-facing handler — the exact flag [resolveHandshakeTimeout] consults
  /// to pick the handshake budget for the next [connect].
  ///
  /// Exposed so the M-3 decoupling can be asserted *per manager* (wired →
  /// extended budget, unwired → plain timeout) rather than only through the
  /// pure function in isolation.
  @visibleForTesting
  bool get hasHostKeyApprovalHandler => _hostKeyApprovalHandler != null;

  /// Dials, authenticates, and opens an interactive PTY shell.
  ///
  /// Provide [password] for password auth, or [privateKey] (+ optional
  /// [passphrase]) for public-key auth. Throws [AppFailureException] on
  /// failure after emitting an [SshConnectionState.error].
  Future<void> connect({
    required String host,
    required int port,
    required String username,
    String? serverName,
    String? password,
    String? privateKey,
    String? passphrase,
    int width = 80,
    int height = 24,
  }) async {
    if (_disposed) {
      throw AppFailureException(
        AppFailure.ssh('SSH manager has been disposed.'),
      );
    }
    if (_connecting) {
      // A connection attempt is already running; ignore the duplicate so the
      // page's post-frame auto-connect can't race a manual retry.
      return;
    }

    _connecting = true;
    _intentionalClose = false;
    _serverName = serverName;
    await _teardown();

    try {
      _emit(SshConnectionState.connecting(serverName: serverName));

      // Decode key material up-front so a bad PEM surfaces as a clear error.
      List<SSHKeyPair>? identities;
      final bool useKey = privateKey != null && privateKey.trim().isNotEmpty;
      if (useKey) {
        final String? pass =
            (passphrase != null && passphrase.isNotEmpty) ? passphrase : null;
        identities = SSHKeyPair.fromPem(privateKey, pass);
        if (identities.isEmpty) {
          throw AppFailureException(
            AppFailure.validation('No usable key found in the private key.'),
          );
        }
      }

      final bool usePassword =
          !useKey && password != null && password.isNotEmpty;

      final SSHSocket socket = await SSHSocket.connect(
        host,
        port,
        timeout: AppConstants.sshConnectTimeout,
      );
      _socket = socket;

      // Handshake budget: with an approval handler wired, the first connect
      // blocks inside key exchange while the user reviews the fingerprint —
      // dartssh2 starts the handshake timer at SSHClient construction and
      // only cancels it once the transport is ready, so the dialog's await is
      // covered by this budget and it must exceed the dialog countdown.
      // Without a handler nothing can block the handshake, so the plain
      // connect timeout applies. TCP dialing stays bounded by
      // [AppConstants.sshConnectTimeout] via SSHSocket.connect either way.
      final Duration handshakeTimeout = resolveHandshakeTimeout(
        hasHostKeyApprovalHandler,
      );

      final SSHClient client = SSHClient(
        socket,
        username: username,
        identities: identities,
        // Endpoint identity travels with this attempt via closure: the
        // dartssh2 callback carries no host/port, and sharing a mutable field
        // across attempts risks reading a later attempt's endpoint.
        onVerifyHostKey: (String type, Uint8List fingerprint) =>
            _verifyHostKey(type, fingerprint, host, port),
        onPasswordRequest: usePassword ? () => password : null,
        // Many servers only offer keyboard-interactive; answer it with the
        // same password so login still works there.
        onUserInfoRequest: usePassword
            ? (SSHUserInfoRequest request) =>
                request.prompts.map((_) => password).toList()
            : null,
        keepAliveInterval: AppConstants.sshKeepAliveInterval,
        handshakeTimeout: handshakeTimeout,
        authTimeout: AppConstants.sshConnectTimeout,
        printDebug: AppConstants.debugSsh
            ? (String? m) => debugPrint('[ssh] $m')
            : null,
      );
      _client = client;

      _emit(SshConnectionState.authenticating(serverName: serverName));

      // Completes once userauth succeeds, or throws on rejection/timeout.
      await client.authenticated;

      // Detect remote/transport drops after we're live.
      unawaited(client.done.then(
        (_) => _onTransportClosed(),
        onError: (Object _) => _onTransportClosed(),
      ));

      final SSHSession shell = await client.shell(
        pty: SSHPtyConfig(
          type: AppConstants.defaultTermType,
          width: width,
          height: height,
        ),
      );
      _shell = shell;
      _pumpShell(shell);

      _emit(SshConnectionState.connected(serverName: serverName));
    } catch (error) {
      final AppFailure failure =
          mapError(error, hostKeyRejection: _hostKeyRejection);
      _intentionalClose = true; // teardown below must not emit "disconnected"
      await _teardown();
      _emit(SshConnectionState.error(
        message: failure.message,
        serverName: serverName,
        failureKind: failure.kind.name,
        failureReason: failure.details['reason'] as String?,
      ));
      throw AppFailureException(failure);
    } finally {
      _connecting = false;
    }
  }

  /// Writes user keystrokes / control sequences to the shell's stdin.
  void sendInput(String data) {
    final SSHSession? shell = _shell;
    if (shell == null || !isConnected || data.isEmpty) return;
    try {
      shell.stdin.add(Uint8List.fromList(utf8.encode(data)));
    } catch (error) {
      debugPrint('[ssh] sendInput failed: $error');
    }
  }

  /// Notifies the remote PTY of a new cell grid.
  Future<void> resize(int width, int height) async {
    final SSHSession? shell = _shell;
    if (shell == null || !isConnected) return;
    if (width <= 0 || height <= 0) return;
    try {
      shell.resizeTerminal(width, height);
    } catch (error) {
      debugPrint('[ssh] resize failed: $error');
    }
  }

  /// Runs [command] over a dedicated `exec` channel and captures its output.
  ///
  /// This is independent of the interactive PTY shell — it opens a separate
  /// SSH channel, so it never disturbs what's on screen in the terminal.
  /// Throws [AppFailureException] when not connected, on timeout, or on any
  /// transport/protocol error (mapped via [mapError]).
  Future<CommandExecutionResult> runCommand(
    String command, {
    Duration? timeout,
  }) async {
    final SSHClient? client = _client;
    if (client == null || !isConnected) {
      throw AppFailureException(
        AppFailure.ssh('Not connected — cannot run command.'),
      );
    }

    final Duration effectiveTimeout =
        timeout ?? const Duration(seconds: 30);

    try {
      final SSHRunResult result = await client
          .runWithResult(command)
          .timeout(effectiveTimeout);
      return CommandExecutionResult(
        stdout: utf8.decode(result.stdout, allowMalformed: true),
        stderr: utf8.decode(result.stderr, allowMalformed: true),
        exitCode: result.exitCode ?? -1,
      );
    } on TimeoutException catch (error) {
      throw AppFailureException(
        AppFailure.timeout(effectiveTimeout, cause: error),
      );
    } catch (error) {
      throw AppFailureException(mapError(error));
    }
  }

  /// Deliberately closes the link and emits [SshConnectionStatus.disconnected].
  Future<void> disconnect() async {
    _intentionalClose = true;
    await _teardown();
    _emit(SshConnectionState.disconnected(serverName: _serverName));
  }

  /// Releases every resource. After this the manager is unusable.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _intentionalClose = true;
    await _teardown();
    await _outputController.close();
    await _stateController.close();
  }

  // ─── Internals ─────────────────────────────────────────────────────────

  /// Resolves the dartssh2 `handshakeTimeout` for a connect attempt.
  ///
  /// Approval-enabled managers get the extended budget so the trust dialog's
  /// await (which runs inside key exchange) cannot be overtaken by the
  /// handshake timer; dialog-less managers keep the plain connect timeout.
  /// Exposed as a pure function for unit-testing the decoupling.
  static Duration resolveHandshakeTimeout(bool approvalWired) =>
      approvalWired
          ? AppConstants.sshHandshakeTimeoutWithApproval
          : AppConstants.sshConnectTimeout;

  /// Host-key verification (first-connect confirmation, D2 semantics).
  ///
  /// * No stored record → ask the user via [hostKeyApprovalHandler]:
  ///   approved → persist the fingerprint and accept; rejected → reject.
  /// * Stored record matches → accept silently.
  /// * Stored record differs → reject (likely MITM); the user must reset
  ///   the host's trust from the server edit page.
  ///
  /// The fingerprint arrives already OpenSSH-encoded (`SHA256:<base64>`) from
  /// `dartssh2`'s handshake, so it is stored verbatim. Returning `false` makes
  /// dartssh2 abort the handshake with `SSHHostkeyError`, which [mapError]
  /// turns into an [AppFailure] tagged with [hostKeyRejectionReason] so the
  /// UI can localise it; the rejection *outcome* (declined vs mismatch) is
  /// kept in [_hostKeyRejection] and folded into the failure details too.
  /// The endpoint arguments are supplied per-connection by the [connect]
  /// closure rather than read from shared fields, so an in-flight callback can
  /// never observe another attempt's endpoint.
  Future<bool> _verifyHostKey(
    String type,
    Uint8List fingerprint,
    String host,
    int port,
  ) async {
    final String fp = decodeHostKeyFingerprint(fingerprint);
    _hostKeyRejection = null;
    return verifyHostKeyTrust(
      store: _hostKeyStore,
      host: host,
      port: port,
      fingerprint: fp,
      approvalHandler: _hostKeyApprovalHandler,
      onRejection: (HostKeyRejection outcome) => _hostKeyRejection = outcome,
    );
  }

  void _pumpShell(SSHSession shell) {
    _stdoutSub = shell.stdout.listen(
      (Uint8List data) {
        if (!_outputController.isClosed) _outputController.add(data);
      },
      onError: (Object error) => _onStreamError(error),
      onDone: _onShellDone,
      cancelOnError: false,
    );
    _stderrSub = shell.stderr.listen(
      (Uint8List data) {
        if (!_outputController.isClosed) _outputController.add(data);
      },
      onError: (Object _) {},
      cancelOnError: false,
    );
  }

  /// The remote closed the shell channel (e.g. user typed `exit`).
  void _onShellDone() {
    if (_intentionalClose || _disposed) return;
    if (_state.status != SshConnectionStatus.connected) return;
    _intentionalClose = true;
    unawaited(_teardown().then((_) {
      _emit(SshConnectionState.disconnected(serverName: _serverName));
    }));
  }

  /// The transport dropped unexpectedly (network change, server hangup).
  void _onTransportClosed() {
    if (_intentionalClose || _disposed) return;
    if (_state.status != SshConnectionStatus.connected) return;
    _intentionalClose = true;
    unawaited(_teardown().then((_) {
      _emit(SshConnectionState.error(
        message: 'Connection lost — the remote closed the session.',
        serverName: _serverName,
        failureKind: FailureKind.network.name,
      ));
    }));
  }

  void _onStreamError(Object error) {
    if (_intentionalClose || _disposed) return;
    _intentionalClose = true;
    final AppFailure failure = mapError(error);
    unawaited(_teardown().then((_) {
      _emit(SshConnectionState.error(
        message: failure.message,
        serverName: _serverName,
        failureKind: failure.kind.name,
      ));
    }));
  }

  /// Closes shell/client/socket and cancels subscriptions without touching
  /// [_state]. Safe to call repeatedly.
  Future<void> _teardown() async {
    await _stdoutSub?.cancel();
    _stdoutSub = null;
    await _stderrSub?.cancel();
    _stderrSub = null;

    final SSHSession? shell = _shell;
    _shell = null;
    try {
      shell?.close();
    } catch (_) {}

    final SSHClient? client = _client;
    _client = null;
    try {
      // dartssh2 4.x: close() is async — await it so the transport (including
      // its socket) is fully torn down before the socket close below.
      await client?.close();
    } catch (_) {}

    final SSHSocket? socket = _socket;
    _socket = null;
    try {
      await socket?.close();
    } catch (_) {}
  }

  void _emit(SshConnectionState next) {
    if (_disposed) return;
    _state = next;
    if (!_stateController.isClosed) _stateController.add(next);
  }

  // ─── Error mapping ───────────────────────────────────────────────────────

  /// Normalises any thrown object from the connect/IO path into an
  /// [AppFailure] with a human-readable message. Exposed so the repository can
  /// reuse it when wrapping [connect] in [Result.guard].
  ///
  /// Optional [hostKeyRejection] decorates `SSHHostkeyError` results with
  /// the machine-readable `reason` marker (`host_key_rejected` when the user
  /// declined the first-connect prompt, `host_key_mismatch` on a fingerprint
  /// change) — the caller passes the value recorded during the in-flight
  /// handshake so the UI can localise each case.
  static AppFailure mapError(
    Object error, {
    HostKeyRejection? hostKeyRejection,
  }) {
    if (error is AppFailureException) return error.failure;
    if (error is AppFailure) return error;

    if (error is TimeoutException) {
      return AppFailure.timeout(AppConstants.sshConnectTimeout, cause: error);
    }
    if (error is SocketException) {
      return AppFailure(
        kind: FailureKind.network,
        message: 'Cannot reach host — ${error.osError?.message ?? error.message}',
        cause: error,
        recoverable: true,
      );
    }
    if (error is SSHKeyDecryptError) {
      return AppFailure.auth(
        message: 'Could not decrypt the private key — wrong passphrase?',
        cause: error,
      );
    }
    if (error is SSHKeyDecodeError) {
      return AppFailure.validation(
        'Could not parse the private key (unsupported or malformed PEM).',
      );
    }
    if (error is SSHAuthFailError) {
      return AppFailure.auth(
        message: 'Authentication failed — check username and credentials.',
        cause: error,
      );
    }
    if (error is SSHAuthAbortError) {
      return AppFailure.auth(
        message: 'Authentication aborted: ${error.message}',
        cause: error,
      );
    }
    if (error is SSHHandshakeError) {
      return AppFailure.ssh('SSH handshake failed: ${error.message}',
          cause: error);
    }
    if (error is SSHHostkeyError) {
      // The host-key callback returned false (first-connect rejection or
      // fingerprint mismatch). The marker lets the UI render a localised,
      // specific message and point the user at "reset host trust".
      return AppFailure(
        kind: FailureKind.ssh,
        message: 'Host key rejected: ${error.message}',
        cause: error,
        recoverable: true,
        details: <String, dynamic>{
          'reason': hostKeyRejection == HostKeyRejection.mismatch
              ? hostKeyMismatchReason
              : hostKeyRejectionReason,
        },
      );
    }
    if (error is SSHChannelOpenError) {
      return AppFailure.ssh(
        'Server refused the shell channel (${error.code}: ${error.description}).',
        code: error.code,
        cause: error,
      );
    }
    if (error is SSHChannelRequestError) {
      return AppFailure.ssh('Shell request failed: ${error.message}',
          cause: error);
    }
    if (error is SSHSocketError) {
      return AppFailure.network(error.error);
    }
    if (error is SSHError) {
      final String msg = error is SSHMessageError
          ? (error as SSHMessageError).message
          : error.toString();
      return AppFailure.ssh(msg);
    }
    return AppFailure.unexpected(error);
  }
}
