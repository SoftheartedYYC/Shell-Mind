import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shell_mind/features/server_config/domain/entities/server_config.dart';
import 'package:shell_mind/features/ssh_terminal/data/ssh_client_manager.dart';
import 'package:shell_mind/features/ssh_terminal/domain/entities/connection_state.dart';
import 'package:shell_mind/shared/ssh/ssh_session_registry.dart';

class MockSshClientManager extends Mock implements SshClientManager {}

void main() {
  const String serverId1 = 'server-1';
  const String serverId2 = 'server-2';

  late List<StreamController<SshConnectionState>> controllers;

  ServerConfig buildConfig(String id, String name) => ServerConfig(
        id: id,
        name: name,
        host: '10.0.0.1',
        username: 'root',
        createdAt: DateTime(2024),
      );

  /// Creates a mock manager backed by a fresh broadcast state controller that
  /// is tracked in [controllers] for teardown.
  MockSshClientManager buildManager({bool connected = true}) {
    final StreamController<SshConnectionState> controller =
        StreamController<SshConnectionState>.broadcast();
    controllers.add(controller);
    final MockSshClientManager manager = MockSshClientManager();
    when(() => manager.isConnected).thenReturn(connected);
    when(() => manager.stateStream).thenAnswer((_) => controller.stream);
    // The registry owns its sessions and disposes the manager when the
    // transport drops; the mock must honour the Future<void> contract.
    when(() => manager.dispose()).thenAnswer((_) async {});
    return manager;
  }

  /// The state controller backing [manager] (matched by creation order).
  StreamController<SshConnectionState> controllerFor(MockSshClientManager m) {
    for (final StreamController<SshConnectionState> c in controllers) {
      if (c.stream == m.stateStream) return c;
    }
    throw StateError('controller not found');
  }

  setUp(() {
    controllers = <StreamController<SshConnectionState>>[];
  });

  tearDown(() async {
    for (final StreamController<SshConnectionState> c in controllers) {
      await c.close();
    }
  });

  ProviderContainer createContainer() {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('SshSessionRegistry', () {
    test('register session adds to state', () {
      final ProviderContainer container = createContainer();
      final SshSessionRegistry registry =
          container.read(sshSessionRegistryProvider.notifier);
      final MockSshClientManager manager = buildManager();

      registry.register(serverId1, manager, buildConfig(serverId1, 'web-01'));

      final Map<String, RegisteredSession> state =
          container.read(sshSessionRegistryProvider);
      expect(state, contains(serverId1));
      expect(state[serverId1]!.serverName, 'web-01');
      expect(registry.hasActiveSessions, isTrue);
      expect(registry.sessionCount, 1);
    });

    test('unregister session removes from state', () {
      final ProviderContainer container = createContainer();
      final SshSessionRegistry registry =
          container.read(sshSessionRegistryProvider.notifier);
      registry.register(serverId1, buildManager(), buildConfig(serverId1, 'web-01'));

      registry.unregister(serverId1);

      expect(container.read(sshSessionRegistryProvider), isNot(contains(serverId1)));
      expect(registry.hasActiveSessions, isFalse);
    });

    test('unregister is a no-op for unknown id', () {
      final ProviderContainer container = createContainer();
      final SshSessionRegistry registry =
          container.read(sshSessionRegistryProvider.notifier);
      registry.register(serverId1, buildManager(), buildConfig(serverId1, 'web-01'));

      registry.unregister('unknown');

      expect(registry.sessionCount, 1);
    });

    test('getSession returns correct session', () {
      final ProviderContainer container = createContainer();
      final SshSessionRegistry registry =
          container.read(sshSessionRegistryProvider.notifier);
      registry.register(serverId1, buildManager(), buildConfig(serverId1, 'web-01'));
      registry.register(serverId2, buildManager(), buildConfig(serverId2, 'web-02'));

      expect(registry.getSession(serverId1)!.serverName, 'web-01');
      expect(registry.getSession(serverId2)!.serverName, 'web-02');
      expect(registry.getSession('missing'), isNull);
    });

    test('activeSessions returns list of all sessions', () {
      final ProviderContainer container = createContainer();
      final SshSessionRegistry registry =
          container.read(sshSessionRegistryProvider.notifier);
      registry.register(serverId1, buildManager(), buildConfig(serverId1, 'web-01'));
      registry.register(serverId2, buildManager(), buildConfig(serverId2, 'web-02'));

      final List<RegisteredSession> sessions = registry.activeSessions;
      expect(sessions, hasLength(2));
      expect(
        sessions.map((RegisteredSession s) => s.serverId),
        containsAll(<String>[serverId1, serverId2]),
      );
    });

    test('register replaces existing session for same id', () {
      final ProviderContainer container = createContainer();
      final SshSessionRegistry registry =
          container.read(sshSessionRegistryProvider.notifier);
      registry.register(serverId1, buildManager(), buildConfig(serverId1, 'first'));
      registry.register(serverId1, buildManager(), buildConfig(serverId1, 'second'));

      expect(registry.sessionCount, 1);
      expect(registry.getSession(serverId1)!.serverName, 'second');
    });

    test('auto-unregister on disconnected state', () async {
      final ProviderContainer container = createContainer();
      final SshSessionRegistry registry =
          container.read(sshSessionRegistryProvider.notifier);
      final MockSshClientManager manager = buildManager();
      registry.register(serverId1, manager, buildConfig(serverId1, 'web-01'));
      expect(registry.sessionCount, 1);

      controllerFor(manager).add(const SshConnectionState.disconnected());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(registry.getSession(serverId1), isNull);
      expect(registry.hasActiveSessions, isFalse);
    });

    test('auto-unregister on error state', () async {
      final ProviderContainer container = createContainer();
      final SshSessionRegistry registry =
          container.read(sshSessionRegistryProvider.notifier);
      final MockSshClientManager manager = buildManager();
      registry.register(serverId1, manager, buildConfig(serverId1, 'web-01'));

      controllerFor(manager)
          .add(const SshConnectionState.error(message: 'dropped'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(registry.getSession(serverId1), isNull);
    });

    test('auto-unregister on stream closed (manager disposed)', () async {
      final ProviderContainer container = createContainer();
      final SshSessionRegistry registry =
          container.read(sshSessionRegistryProvider.notifier);
      final MockSshClientManager manager = buildManager();
      registry.register(serverId1, manager, buildConfig(serverId1, 'web-01'));

      await controllerFor(manager).close();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(registry.getSession(serverId1), isNull);
    });

    test('stays connected state does not unregister', () async {
      final ProviderContainer container = createContainer();
      final SshSessionRegistry registry =
          container.read(sshSessionRegistryProvider.notifier);
      final MockSshClientManager manager = buildManager();
      registry.register(serverId1, manager, buildConfig(serverId1, 'web-01'));

      controllerFor(manager).add(SshConnectionState.connected());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(registry.getSession(serverId1), isNotNull);
    });

    test('defaultSession returns most recent active session', () async {
      final ProviderContainer container = createContainer();
      final SshSessionRegistry registry =
          container.read(sshSessionRegistryProvider.notifier);

      registry.register(serverId1, buildManager(), buildConfig(serverId1, 'old'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      registry.register(serverId2, buildManager(), buildConfig(serverId2, 'new'));

      expect(registry.defaultSession!.serverId, serverId2);
    });

    test('defaultSession is null when empty', () {
      final ProviderContainer container = createContainer();
      final SshSessionRegistry registry =
          container.read(sshSessionRegistryProvider.notifier);

      expect(registry.defaultSession, isNull);
    });
  });
}
