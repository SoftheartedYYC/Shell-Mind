import 'dart:async';
import 'dart:io' show SocketException;
import 'dart:typed_data' show Uint8List;

import 'package:dartssh2/dartssh2.dart';

import '../../server_config/domain/entities/server_config.dart';

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
  const SshConnectionTester._();

  /// Runs a complete SSH handshake + authentication attempt.
  ///
  /// [password] is used when [authType] is [AuthType.password]; [privateKey]
  /// (with optional [passphrase]) is used when [authType] is
  /// [AuthType.privateKey]. No shell is opened — the connection is closed as
  /// soon as authentication resolves.
  static Future<SshTestResult> test({
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
        onVerifyHostKey: _verifyHostKey,
        onPasswordRequest: usePassword ? () => pwd : null,
        // Many servers only offer keyboard-interactive; answer it with the
        // same password so the test mirrors a real login.
        onUserInfoRequest: usePassword
            ? (SSHUserInfoRequest request) =>
                request.prompts.map((_) => pwd).toList()
            : null,
        handshakeTimeout: timeout,
        authTimeout: timeout,
      );

      // Completes once userauth succeeds, or throws on rejection/timeout.
      await client.authenticated;
      return SshTestResult.success;
    } catch (error) {
      return mapException(error);
    } finally {
      try {
        client?.close();
      } catch (_) {}
      try {
        await socket?.close();
      } catch (_) {}
    }
  }

  /// First-connect trust: accept any host key so the probe never blocks on a
  /// verification prompt.
  static FutureOr<bool> _verifyHostKey(String type, Uint8List fingerprint) =>
      true;

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
