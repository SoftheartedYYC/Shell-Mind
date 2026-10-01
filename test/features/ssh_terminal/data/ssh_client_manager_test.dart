import 'dart:async';
import 'dart:io' show SocketException;

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell_mind/core/utils/result.dart';
import 'package:shell_mind/features/ssh_terminal/data/ssh_client_manager.dart';
import 'package:shell_mind/features/ssh_terminal/domain/entities/connection_state.dart';

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
}
