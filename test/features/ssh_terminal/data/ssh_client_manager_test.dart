import 'dart:async';
import 'dart:io' show SocketException;

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell_mind/core/constants/app_constants.dart';
import 'package:shell_mind/core/utils/result.dart';
import 'package:shell_mind/features/ssh_terminal/data/ssh_client_manager.dart';
import 'package:shell_mind/features/ssh_terminal/domain/entities/connection_state.dart';
import 'package:shell_mind/shared/ssh/host_key_store.dart';

void main() {
  group('SshClientManager.mapError', () {
    test('maps AppFailureException to its contained failure', () {
      final failure = AppFailure.ssh('test error');
      final exception = AppFailureException(failure);

      final result = SshClientManager.mapError(exception);
      expect(result, same(failure));
    });

    test('maps AppFailure directly', () {
      final failure = AppFailure.network('offline');

      final result = SshClientManager.mapError(failure);
      expect(result, same(failure));
    });

    test('maps TimeoutException to timeout failure', () {
      final error = TimeoutException('connection timed out');

      final result = SshClientManager.mapError(error);
      expect(result.kind, FailureKind.timeout);
      expect(result.recoverable, isTrue);
    });

    test('maps SocketException to network failure', () {
      final error = SocketException('Connection refused');

      final result = SshClientManager.mapError(error);
      expect(result.kind, FailureKind.network);
      expect(result.message, contains('Cannot reach host'));
      expect(result.recoverable, isTrue);
    });

    test('maps SSHAuthFailError to auth failure', () {
      final error = SSHAuthFailError('No methods available');

      final result = SshClientManager.mapError(error);
      expect(result.kind, FailureKind.auth);
      expect(result.message, contains('Authentication failed'));
    });

    test('maps SSHHandshakeError to ssh failure', () {
      final error = SSHHandshakeError('protocol mismatch');

      final result = SshClientManager.mapError(error);
      expect(result.kind, FailureKind.ssh);
      expect(result.message, contains('handshake failed'));
    });

    test('maps SSHHostkeyError to ssh failure', () {
      final error = SSHHostkeyError('key rejected');

      final result = SshClientManager.mapError(error);
      expect(result.kind, FailureKind.ssh);
      expect(result.message, contains('Host key rejected'));
    });

    test('maps SSHHostkeyError without outcome to rejection reason', () {
      final error = SSHHostkeyError('Hostkey verification failed');

      final result = SshClientManager.mapError(error);
      expect(result.kind, FailureKind.ssh);
      expect(result.details['reason'], hostKeyRejectionReason);
    });

    test('maps SSHHostkeyError with user rejection to rejection reason', () {
      final error = SSHHostkeyError('Hostkey verification failed');

      final result = SshClientManager.mapError(
        error,
        hostKeyRejection: HostKeyRejection.rejected,
      );
      expect(result.kind, FailureKind.ssh);
      expect(result.details['reason'], hostKeyRejectionReason);
      expect(result.details['reason'], isNot(hostKeyMismatchReason));
    });

    test('maps SSHHostkeyError with mismatch to mismatch reason', () {
      final error = SSHHostkeyError('Hostkey verification failed');

      final result = SshClientManager.mapError(
        error,
        hostKeyRejection: HostKeyRejection.mismatch,
      );
      expect(result.kind, FailureKind.ssh);
      expect(result.details['reason'], hostKeyMismatchReason);
      expect(result.details['reason'], isNot(hostKeyRejectionReason));
    });

    test('maps SSHChannelOpenError to ssh failure with code', () {
      final error = SSHChannelOpenError(1, 'not allowed');

      final result = SshClientManager.mapError(error);
      expect(result.kind, FailureKind.ssh);
      expect(result.message, contains('refused the shell channel'));
      expect(result.code, 1);
    });

    test('maps SSHMessageError subtype to ssh failure', () {
      // SSHPacketError is a concrete SSHError with SSHMessageError mixin
      final error = SSHPacketError('malformed packet');

      final result = SshClientManager.mapError(error);
      expect(result.kind, FailureKind.ssh);
      expect(result.message, contains('malformed packet'));
    });

    test('maps unknown error to unexpected failure', () {
      final error = Exception('something weird');

      final result = SshClientManager.mapError(error);
      expect(result.kind, FailureKind.unexpected);
      expect(result.cause, same(error));
    });

    test('maps StateError to unexpected failure', () {
      final error = StateError('bad state');

      final result = SshClientManager.mapError(error);
      expect(result.kind, FailureKind.unexpected);
    });
  });

  group('SshClientManager lifecycle', () {
    late SshClientManager manager;

    setUp(() {
      manager = SshClientManager();
    });

    tearDown(() async {
      await manager.dispose();
    });

    test('initial state is disconnected', () {
      expect(manager.currentState.status, SshConnectionStatus.disconnected);
      expect(manager.isConnected, isFalse);
    });

    test('outputStream is a broadcast stream', () {
      // Should be able to listen multiple times without error
      final sub1 = manager.outputStream.listen((_) {});
      final sub2 = manager.outputStream.listen((_) {});
      sub1.cancel();
      sub2.cancel();
    });

    test('stateStream is a broadcast stream', () {
      final sub1 = manager.stateStream.listen((_) {});
      final sub2 = manager.stateStream.listen((_) {});
      sub1.cancel();
      sub2.cancel();
    });

    test('sendInput does nothing when not connected', () {
      // Should not throw
      manager.sendInput('ls -la\n');
    });

    test('resize does nothing when not connected', () async {
      // Should not throw
      await manager.resize(120, 40);
    });

    test('disconnect emits disconnected state', () async {
      final states = <SshConnectionState>[];
      final sub = manager.stateStream.listen(states.add);

      await manager.disconnect();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(states, isNotEmpty);
      expect(states.last.status, SshConnectionStatus.disconnected);

      await sub.cancel();
    });

    test('connect throws AppFailureException after dispose', () async {
      await manager.dispose();

      expect(
        () => manager.connect(
          host: '10.0.0.1',
          port: 22,
          username: 'root',
          password: 'pass',
        ),
        throwsA(isA<AppFailureException>()),
      );
    });

    test('dispose is idempotent', () async {
      await manager.dispose();
      await manager.dispose(); // Should not throw
    });
  });

  group('SshClientManager host-key wiring', () {
    test('accepts an injected store and approval handler', () {
      final InMemoryHostKeyStore store = InMemoryHostKeyStore();
      Future<bool> approval(String host, int port, String fingerprint) async =>
          true;

      // Dependency-injection channel: a fake store (tests) and a dialog
      // handler (presentation) can both be wired in. The D2 trust policy
      // itself is exercised in test/shared/ssh/host_key_store_test.dart via
      // verifyHostKeyTrust, which _verifyHostKey delegates to.
      final manager = SshClientManager(
        hostKeyStore: store,
        hostKeyApprovalHandler: approval,
      );

      expect(manager.currentState.status, SshConnectionStatus.disconnected);
      expect(manager.isConnected, isFalse);
    });

    test('default construction keeps the legacy behaviour available', () {
      // Plain `SshClientManager()` (existing call sites) must stay
      // constructible — it silently falls back to an in-memory store and
      // auto-accepts unknown keys.
      final manager = SshClientManager();

      expect(manager.currentState.status, SshConnectionStatus.disconnected);
    });
  });

  // ─── M-3: TOFU dialog vs handshake timeout race ────────────────────────
  //
  // Before the fix, dartssh2's handshake timer (sshConnectTimeout, 15s) kept
  // running *while* the first-connect trust dialog was on screen: the
  // host-key callback awaits the user inside key exchange, so a user who took
  // longer than 15s to read the fingerprint got a timeout failure — yet trust
  // had already been recorded and the dialog lingered. connect() now derives
  // its handshake budget from whether an approval handler is wired
  // (SshClientManager.resolveHandshakeTimeout), and the dialog auto-rejects
  // strictly earlier than that budget. These tests pin that seam plus the
  // constant invariants it must preserve.
  group('SshClientManager handshake timeout decoupling (M-3)', () {
    test('approval-enabled budget is the extended handshake timeout', () {
      expect(
        SshClientManager.resolveHandshakeTimeout(true),
        AppConstants.sshHandshakeTimeoutWithApproval,
      );
    });

    test('handler-less budget stays the plain connect timeout', () {
      expect(
        SshClientManager.resolveHandshakeTimeout(false),
        AppConstants.sshConnectTimeout,
      );
    });

    test('wired manager dials with the extended budget', () {
      Future<bool> approval(String host, int port, String fingerprint) async =>
          true;

      final SshClientManager wired = SshClientManager(
        hostKeyStore: InMemoryHostKeyStore(),
        hostKeyApprovalHandler: approval,
      );
      final SshClientManager plain = SshClientManager();

      final bool wiredFlag = wired.hasHostKeyApprovalHandler;
      final bool plainFlag = plain.hasHostKeyApprovalHandler;

      // Exactly the expression connect() feeds SSHClient.handshakeTimeout.
      expect(
        SshClientManager.resolveHandshakeTimeout(wiredFlag),
        AppConstants.sshHandshakeTimeoutWithApproval,
      );
      expect(
        SshClientManager.resolveHandshakeTimeout(plainFlag),
        AppConstants.sshConnectTimeout,
      );

      // A legacy auto-accept manager must never inherit the long budget.
      expect(wiredFlag, isTrue);
      expect(plainFlag, isFalse);
    });

    test('dialog countdown expires strictly before the handshake timer', () {
      // Ordering invariant that kills the race: the auto-reject must fire
      // while the transport is still alive, so an unattended prompt can never
      // resolve after the handshake already failed.
      final Duration budget = SshClientManager.resolveHandshakeTimeout(true);

      expect(AppConstants.hostKeyApprovalTimeout, lessThan(budget));
      expect(budget, greaterThan(AppConstants.hostKeyApprovalTimeout));
      // 60s dialog inside a 90s handshake still leaves protocol time.
      expect(
        budget - AppConstants.hostKeyApprovalTimeout,
        greaterThanOrEqualTo(const Duration(seconds: 15)),
      );
    });

    test('extended budget does not loosen the TCP dial bound', () {
      // SSHSocket.connect always receives sshConnectTimeout regardless of the
      // approval wiring: an unreachable host still fails fast, only the
      // in-handshake wait for the user is extended.
      expect(
        AppConstants.sshConnectTimeout,
        lessThan(AppConstants.sshHandshakeTimeoutWithApproval),
      );
      expect(
        SshClientManager.resolveHandshakeTimeout(true),
        isNot(AppConstants.sshConnectTimeout),
      );
    });
  });
}
