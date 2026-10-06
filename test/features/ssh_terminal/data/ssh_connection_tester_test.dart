import 'dart:async';
import 'dart:io' show SocketException;

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell_mind/core/constants/app_constants.dart';
import 'package:shell_mind/features/ssh_terminal/data/ssh_connection_tester.dart';

void main() {
  group('SshConnectionTester.mapException', () {
    test('TimeoutException maps to timeout', () {
      expect(
        SshConnectionTester.mapException(TimeoutException('slow')),
        SshTestResult.timeout,
      );
    });

    test('SocketException maps to unreachable', () {
      expect(
        SshConnectionTester.mapException(
          const SocketException('connection refused'),
        ),
        SshTestResult.unreachable,
      );
    });

    test('SSHSocketError maps to unreachable', () {
      expect(
        SshConnectionTester.mapException(SSHSocketError('network down')),
        SshTestResult.unreachable,
      );
    });

    test('SSHKeyDecryptError (wrong passphrase) maps to authFailed', () {
      expect(
        SshConnectionTester.mapException(SSHKeyDecryptError('Invalid passphrase')),
        SshTestResult.authFailed,
      );
    });

    test('SSHKeyDecodeError (malformed PEM) maps to authFailed', () {
      expect(
        SshConnectionTester.mapException(
          SSHKeyDecodeError('Failed to decode private key'),
        ),
        SshTestResult.authFailed,
      );
    });

    test('SSHAuthFailError maps to authFailed', () {
      expect(
        SshConnectionTester.mapException(
          SSHAuthFailError('All authentication methods failed'),
        ),
        SshTestResult.authFailed,
      );
    });

    test('SSHAuthAbortError maps to authFailed', () {
      expect(
        SshConnectionTester.mapException(
          SSHAuthAbortError('Authentication timed out'),
        ),
        SshTestResult.authFailed,
      );
    });

    test('SSHHandshakeError maps to handshakeFailed', () {
      expect(
        SshConnectionTester.mapException(SSHHandshakeError('bad version')),
        SshTestResult.handshakeFailed,
      );
    });

    test('SSHHostkeyError maps to handshakeFailed', () {
      expect(
        SshConnectionTester.mapException(
          SSHHostkeyError('Signature verification failed'),
        ),
        SshTestResult.handshakeFailed,
      );
    });

    test('generic SSHError maps to handshakeFailed', () {
      expect(
        SshConnectionTester.mapException(_FakeSshError()),
        SshTestResult.handshakeFailed,
      );
    });

    test('unknown error maps to handshakeFailed', () {
      expect(
        SshConnectionTester.mapException(StateError('boom')),
        SshTestResult.handshakeFailed,
      );
    });
  });

  group('SshConnectionTester handshake timeout (approval budget)', () {
    test('approval-wired probe uses the extended handshake timeout', () {
      final Duration budget = SshConnectionTester.resolveHandshakeTimeout(
        true,
        const Duration(seconds: 10),
      );

      expect(budget, AppConstants.sshHandshakeTimeoutWithApproval);
    });

    test('handler-less probe keeps the caller-supplied timeout', () {
      const Duration callerTimeout = Duration(seconds: 10);

      expect(
        SshConnectionTester.resolveHandshakeTimeout(false, callerTimeout),
        callerTimeout,
      );
    });

    test('60s approval countdown stays strictly inside the probe budget', () {
      // Pin the same invariant the manager path pins: the host-key dialog
      // auto-rejects after [AppConstants.hostKeyApprovalTimeout]; the probe's
      // handshake timer must survive a full unattended countdown plus normal
      // protocol time, or a first-connect confirmation could resolve after
      // the transport already failed.
      expect(
        AppConstants.hostKeyApprovalTimeout,
        lessThan(
          SshConnectionTester.resolveHandshakeTimeout(
            true,
            const Duration(seconds: 10),
          ),
        ),
      );
    });
  });
}

/// Minimal [SSHError] implementation used to exercise the generic branch of
/// [SshConnectionTester.mapException] without opening a real socket.
class _FakeSshError implements SSHError {}
