import 'package:flutter_test/flutter_test.dart';
import 'package:shell_mind/features/ssh_terminal/domain/entities/connection_state.dart';

void main() {
  group('SshConnectionStatus', () {
    test('has expected values', () {
      expect(SshConnectionStatus.values.length, 5);
    });

    test('isBusy is true for connecting and authenticating', () {
      expect(SshConnectionStatus.connecting.isBusy, isTrue);
      expect(SshConnectionStatus.authenticating.isBusy, isTrue);
    });

    test('isBusy is false for other states', () {
      expect(SshConnectionStatus.disconnected.isBusy, isFalse);
      expect(SshConnectionStatus.connected.isBusy, isFalse);
      expect(SshConnectionStatus.error.isBusy, isFalse);
    });

    test('token returns correct strings', () {
      expect(SshConnectionStatus.disconnected.token, 'OFFLINE');
      expect(SshConnectionStatus.connecting.token, 'CONNECTING');
      expect(SshConnectionStatus.authenticating.token, 'AUTH');
      expect(SshConnectionStatus.connected.token, 'CONNECTED');
      expect(SshConnectionStatus.error.token, 'ERROR');
    });
  });

  group('SshConnectionState constructors', () {
    test('disconnected creates correct state', () {
      const state = SshConnectionState.disconnected(serverName: 'my-server');
      expect(state.status, SshConnectionStatus.disconnected);
      expect(state.serverName, 'my-server');
      expect(state.errorMessage, isNull);
      expect(state.connectedAt, isNull);
      expect(state.failureKind, isNull);
      expect(state.isDisconnected, isTrue);
      expect(state.isConnected, isFalse);
      expect(state.isError, isFalse);
      expect(state.isBusy, isFalse);
    });

    test('connecting creates correct state', () {
      const state = SshConnectionState.connecting(serverName: 'host-1');
      expect(state.status, SshConnectionStatus.connecting);
      expect(state.serverName, 'host-1');
      expect(state.isBusy, isTrue);
      expect(state.isConnected, isFalse);
    });

    test('authenticating creates correct state', () {
      const state = SshConnectionState.authenticating();
      expect(state.status, SshConnectionStatus.authenticating);
      expect(state.isBusy, isTrue);
    });

    test('connected creates state with timestamp', () {
      final before = DateTime.now();
      final state = SshConnectionState.connected(serverName: 'live');
      final after = DateTime.now();

      expect(state.status, SshConnectionStatus.connected);
      expect(state.serverName, 'live');
      expect(state.isConnected, isTrue);
      expect(state.connectedAt, isNotNull);
      expect(
        state.connectedAt!.isAfter(before) ||
            state.connectedAt!.isAtSameMomentAs(before),
        isTrue,
      );
      expect(
        state.connectedAt!.isBefore(after) ||
            state.connectedAt!.isAtSameMomentAs(after),
        isTrue,
      );
    });

    test('connected accepts explicit timestamp', () {
      final ts = DateTime(2024, 6, 15, 10, 30);
      final state = SshConnectionState.connected(connectedAt: ts);
      expect(state.connectedAt, ts);
    });

    test('error creates correct state', () {
      const state = SshConnectionState.error(
        message: 'Connection refused',
        serverName: 'bad-host',
        failureKind: 'network',
      );
      expect(state.status, SshConnectionStatus.error);
      expect(state.errorMessage, 'Connection refused');
      expect(state.serverName, 'bad-host');
      expect(state.failureKind, 'network');
      expect(state.isError, isTrue);
      expect(state.isConnected, isFalse);
      expect(state.connectedAt, isNull);
    });
  });

  group('SshConnectionState.copyWith', () {
    test('copies without changes', () {
      const original = SshConnectionState.disconnected(serverName: 'test');
      final copy = original.copyWith();
      expect(copy, equals(original));
    });

    test('overrides status', () {
      const original = SshConnectionState.disconnected();
      final copy = original.copyWith(status: SshConnectionStatus.connecting);
      expect(copy.status, SshConnectionStatus.connecting);
    });

    test('overrides errorMessage', () {
      const original = SshConnectionState.error(message: 'old');
      final copy = original.copyWith(errorMessage: 'new error');
      expect(copy.errorMessage, 'new error');
      expect(copy.status, SshConnectionStatus.error);
    });

    test('overrides serverName', () {
      const original = SshConnectionState.connecting(serverName: 'old');
      final copy = original.copyWith(serverName: 'new');
      expect(copy.serverName, 'new');
    });
  });

  group('SshConnectionState equality', () {
    test('identical states are equal', () {
      const a = SshConnectionState.disconnected(serverName: 'x');
      const b = SshConnectionState.disconnected(serverName: 'x');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different status makes states unequal', () {
      const a = SshConnectionState.disconnected();
      const b = SshConnectionState.connecting();
      expect(a, isNot(equals(b)));
    });

    test('different serverName makes states unequal', () {
      const a = SshConnectionState.connecting(serverName: 'one');
      const b = SshConnectionState.connecting(serverName: 'two');
      expect(a, isNot(equals(b)));
    });

    test('different errorMessage makes states unequal', () {
      const a = SshConnectionState.error(message: 'err1');
      const b = SshConnectionState.error(message: 'err2');
      expect(a, isNot(equals(b)));
    });
  });

  group('SshConnectionState.toString', () {
    test('includes status and server name', () {
      const state = SshConnectionState.connecting(serverName: 'my-host');
      final str = state.toString();
      expect(str, contains('connecting'));
      expect(str, contains('my-host'));
    });

    test('includes error message when present', () {
      const state = SshConnectionState.error(message: 'timeout');
      expect(state.toString(), contains('timeout'));
    });
  });

  group('State transitions', () {
    test('typical lifecycle: disconnected -> connecting -> authenticating -> connected', () {
      var state = const SshConnectionState.disconnected(serverName: 'srv');
      expect(state.isDisconnected, isTrue);

      state = const SshConnectionState.connecting(serverName: 'srv');
      expect(state.isBusy, isTrue);

      state = const SshConnectionState.authenticating(serverName: 'srv');
      expect(state.isBusy, isTrue);

      state = SshConnectionState.connected(serverName: 'srv');
      expect(state.isConnected, isTrue);
      expect(state.isBusy, isFalse);
    });

    test('error transition from connecting', () {
      var state = const SshConnectionState.connecting(serverName: 'srv');
      state = const SshConnectionState.error(
        message: 'Connection refused',
        serverName: 'srv',
        failureKind: 'network',
      );
      expect(state.isError, isTrue);
      expect(state.isBusy, isFalse);
    });
  });
}
