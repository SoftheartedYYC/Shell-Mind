import 'dart:async';
import 'dart:io' show SocketException;
import 'dart:typed_data' show Uint8List;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:dartssh2/dartssh2.dart';

import '../../../core/constants/app_constants.dart';
import '../../server_config/domain/entities/server_config.dart';
import '../../../../shared/ssh/host_key_store.dart';

/// Outcome of a full SSH handshake + authentication probe.
///
/// Unlike a bare TCP port check, these results distinguish *why* a test
/// failed so the UI can tell the user whether the host is down, the network
/// timed out, the SSH protocol/handshake broke, or the credentials were
/// rejected.
enum SshTestResult {
  /// Handshake and userauth both succeeded.
  success,

  /// The host could not be reached (DNS failure, connection refused, etc.).
  unreachable,

  /// The connection or authentication exceeded the allotted time.
  timeout,

  /// TCP connected but the SSH handshake/protocol exchange failed.
  handshakeFailed,

  /// SSH handshake succeeded but the supplied credentials were rejected.
  authFailed,
}

/// Performs a real SSH authentication test without opening a shell.
///
/// This replaces the previous TCP-only "is the port open?" probe that
/// incorrectly reported success for wrong passwords. It dials the host,
/// completes the SSH handshake, and runs userauth with the *current form*
/// credentials, then tears the transport down immediately.
///
/// All exceptions are funnelled through [mapException] so callers receive a
/// plain [SshTestResult] instead of raw protocol errors.
class SshConnectionTester {
  /// Creates a tester that participates in the app-wide host-key trust
  /// policy: the first-connect confirmation dialog and the recorded
  /// fingerprints are shared with every other connection path (terminal
  /// page, AI auto-connect, in-chat picker).
  ///
  /// When [hostKeyStore] is `null` the probe falls back to the legacy
  /// accept-any-key behaviour (kept for plain unit tests and callers that
  /// run before the keystore is available).
  const SshConnectionTester({
    this.hostKeyStore,
    this.hostKeyApprovalHandler,
  });

  /// Shared fingerprint store — the same instance the terminal page's
  /// connection path uses, keyed by `host_port`.
  final HostKeyStore? hostKeyStore;

  /// First-connect confirmation bridge. Wired to the root navigator's
  /// [HostKeyApprovalDialog] in production (see `server_edit_page.dart`).
  final Future<bool> Function(String host, int port, String fingerprint)?
      hostKeyApprovalHandler;

  /// Runs a complete SSH handshake + authentication attempt.
  ///
  /// [password] is used when [authType] is [AuthType.password]; [privateKey]
  /// (with optional [passphrase]) was used when [authType] is
  /// [AuthType.privateKey]. No shell is opened — the connection is closed as
  /// soon as authentication resolves.
  Future<SshTestResult> test({
    required String host,
    required int port,
    required String username,
    required AuthType authType,
    String? password,
    String? privateKey,
    String? passphrase,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    SSHSocket? socket;
    SSHClient? client;
    try {
      // Decode key material up-front so a malformed/undecryptable PEM is
      // surfaced as an auth problem rather than a generic handshake error.
      List<SSHKeyPair>? identities;
      if (authType == AuthType.privateKey) {
        final String key = privateKey?.trim() ?? '';
        if (key.isEmpty) {
          // Nothing to authenticate with.
          return SshTestResult.authFailed;
        }
        final String? pass =
            (passphrase != null && passphrase.isNotEmpty) ? passphrase : null;
        identities = SSHKeyPair.fromPem(key, pass);
        if (identities.isEmpty) {
          return SshTestResult.authFailed;
        }
      }

      final bool usePassword = authType == AuthType.password;
      final String pwd = password ?? '';

      socket = await SSHSocket.connect(host, port, timeout: timeout);

      client = SSHClient(
        socket,
        username: username,
        identities: identities,
        onVerifyHostKey: (String type, Uint8List fingerprint) =>
            _verifyHostKey(host, port, fingerprint),
        onPasswordRequest: usePassword ? () => pwd : null,
        // Many servers only offer keyboard-interactive; answer it with the
        // same password so the test mirrors a real login.
        onUserInfoRequest: usePassword
            ? (SSHUserInfoRequest request) =>
                request.prompts.map((_) => pwd).toList()
            : null,
        handshakeTimeout: resolveHandshakeTimeout(
          hostKeyApprovalHandler != null,
          timeout,
        ),
        authTimeout: timeout,
      );

      // Completes once userauth succeeds, or throws on rejection/timeout.
      await client.authenticated;
      return SshTestResult.success;
    } catch (error) {
      return mapException(error);
    } finally {
      try {
        // dartssh2 4.x: close() is async — await full transport teardown.
        await client?.close();
      } catch (_) {}
      try {
        await socket?.close();
      } catch (_) {}
    }
  }

  /// Handshake budget for one probe attempt.
  ///
  /// Mirrors the `SshClientManager.resolveHandshakeTimeout` invariant: when
  /// the first-connect approval dialog may block inside key exchange, the
  /// budget must cover the dialog countdown
  /// ([AppConstants.sshHandshakeTimeoutWithApproval]); without a handler
  /// nothing can stall the handshake, so the caller's [plainTimeout] applies
  /// unchanged. TCP dialing and authentication keep [plainTimeout] either
  /// way — the approval callback only ever fires during key exchange.
  static Duration resolveHandshakeTimeout(
    bool approvalWired,
    Duration plainTimeout,
  ) =>
      approvalWired
          ? AppConstants.sshHandshakeTimeoutWithApproval
          : plainTimeout;

  /// First-connect trust: accept any host key so the probe never blocks on a
  /// verification prompt.
  static FutureOr<bool> _verifyAnyHostKey(
      String type, Uint8List fingerprint) =>
      true;

  /// Host-key verification through the shared [verifyHostKeyTrust] policy.
  ///
  /// With no store bridged the probe keeps the legacy accept-any behaviour —
  /// a credential test must never be the first thing to write a trust
  /// record, and unit tests stay prompt-free.
  Future<bool> _verifyHostKey(
    String host,
    int port,
    Uint8List fingerprint,
  ) async {
    final HostKeyStore? store = hostKeyStore;
    if (store == null) {
      return _verifyAnyHostKey('', fingerprint);
    }
    return verifyHostKeyTrust(
      store: store,
      host: host,
      port: port,
      fingerprint: decodeHostKeyFingerprint(fingerprint),
      approvalHandler: hostKeyApprovalHandler,
    );
  }

  /// Test-only seam over the private verification path: lets unit tests
  /// assert the injection wiring (store consulted, approval handler bridged,
  /// fingerprint decoded) without opening a real socket.
  @visibleForTesting
  Future<bool> debugVerifyHostKey(String host, int port, Uint8List fingerprint) =>
      _verifyHostKey(host, port, fingerprint);

  /// Pure mapping from a thrown object to an [SshTestResult].
  ///
  /// Exposed (and kept free of I/O) so it can be unit-tested without opening
  /// a real socket. Mirrors the classification used by `SshClientManager`'s
  /// error mapping.
  static SshTestResult mapException(Object error) {
    if (error is TimeoutException) return SshTestResult.timeout;
    if (error is SocketException) return SshTestResult.unreachable;

    // A wrong passphrase or malformed PEM is a credential problem.
    if (error is SSHKeyDecryptError) return SshTestResult.authFailed;
    if (error is SSHKeyDecodeError) return SshTestResult.authFailed;

    // Authentication rejected / aborted by the server.
    if (error is SSHAuthError) return SshTestResult.authFailed;

    // Transport-level network error before the handshake could complete.
    if (error is SSHSocketError) return SshTestResult.unreachable;

    // Handshake / host-key / generic protocol failures.
    if (error is SSHHandshakeError) return SshTestResult.handshakeFailed;
    if (error is SSHHostkeyError) return SshTestResult.handshakeFailed;
    if (error is SSHError) return SshTestResult.handshakeFailed;

    // Anything unexpected: treat as a handshake failure (we did reach the
    // point of attempting the protocol exchange).
    return SshTestResult.handshakeFailed;
  }
}