import 'dart:async';
import 'dart:io' show SocketException;

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_test/flutter_test.dart';
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
}

/// Minimal [SSHError] implementation used to exercise the generic branch of
/// [SshConnectionTester.mapException] without opening a real socket.
class _FakeSshError implements SSHError {}
