import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shell_mind/core/utils/result.dart';
import 'package:shell_mind/features/server_config/domain/entities/server_config.dart';
import 'package:shell_mind/shared/ssh/health_probe.dart';
import 'package:shell_mind/shared/ssh/ssh_command_executor.dart';

class MockSshCommandExecutor extends Mock implements SshCommandExecutor {}

void main() {
  late MockSshCommandExecutor executor;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(const Duration(seconds: 5));
    registerFallbackValue(AppFailure.notFound(message: 'fallback'));
  });

  ServerConfig buildConfig(String id, String name) => ServerConfig(
        id: id,
        name: name,
        host: '10.0.0.1',
        username: 'root',
        createdAt: DateTime(2024),
      );

  CommandResult buildResult(
    String id,
    String name,
    String stdout, {
    int exitCode = 0,
  }) =>
      CommandResult(
        serverId: id,
        serverName: name,
        command: SshHealthProbe.probeCommand,
        stdout: stdout,
        stderr: '',
        exitCode: exitCode,
        elapsed: const Duration(milliseconds: 120),
        executedAt: DateTime(2024),
      );

  ProviderContainer createContainer() {
    final ProviderContainer c = ProviderContainer(overrides: [
      sshCommandExecutorProvider.overrideWithValue(executor),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    executor = MockSshCommandExecutor();
    container = createContainer();
  });

  group('SshHealthProbe', () {
    test('probes every server successfully and parses uptime + load', () async {
      final ServerConfig a = buildConfig('a', 'web-01');
      final ServerConfig b = buildConfig('b', 'db-01');

      when(() => executor.execute(
            serverId: any(named: 'serverId'),
            command: any(named: 'command'),
            timeout: any(named: 'timeout'),
          )).thenAnswer((Invocation inv) async {
        final String id = inv.namedArguments[#serverId] as String;
        return Result<CommandResult>.success(
          buildResult(
            id,
            id == 'a' ? 'web-01' : 'db-01',
            ' 14:32:01 up 3 days,  2:14,  2 users,  load average: 0.52, 0.58, 0.60\n'
                '0.52 0.58 0.60 1/847 12345',
          ),
        );
      });

      final FleetHealthSnapshot snapshot =
          await container.read(sshHealthProbeProvider).probeFleet([a, b]);

      expect(snapshot.totalCount, 2);
      expect(snapshot.onlineCount, 2);
      expect(snapshot.mood, FleetMood.allOnline);
      expect(snapshot.onlineServers[0].uptimeBrief, 'up 3 days, 2:14');
      expect(snapshot.onlineServers[0].loadAverage, '0.52, 0.58, 0.60');

      verify(() => executor.execute(
            serverId: 'a',
            command: SshHealthProbe.probeCommand,
            timeout: SshHealthProbe.probeTimeout,
          )).called(1);
      verify(() => executor.execute(
            serverId: 'b',
            command: SshHealthProbe.probeCommand,
            timeout: SshHealthProbe.probeTimeout,
          )).called(1);
    });

    test('one failing server does not affect the others', () async {
      final ServerConfig a = buildConfig('a', 'web-01');
      final ServerConfig b = buildConfig('b', 'db-01');

      when(() => executor.execute(
            serverId: 'a',
            command: any(named: 'command'),
            timeout: any(named: 'timeout'),
          )).thenAnswer((_) async => Result<CommandResult>.success(
            buildResult(
              'a',
              'web-01',
              ' 10:00:00 up 1:02,  1 user,  load average: 0.10, 0.20, 0.30',
            ),
          ));
      when(() => executor.execute(
            serverId: 'b',
            command: any(named: 'command'),
            timeout: any(named: 'timeout'),
          )).thenAnswer((_) async => Result<CommandResult>.failure(
            AppFailure.ssh('connection lost'),
          ));

      final FleetHealthSnapshot snapshot =
          await container.read(sshHealthProbeProvider).probeFleet([a, b]);

      expect(snapshot.totalCount, 2);
      expect(snapshot.onlineCount, 1);
      expect(snapshot.mood, FleetMood.degraded);
      expect(snapshot.offlineServers.single.serverId, 'b');
      expect(snapshot.offlineServers.single.serverName, 'db-01');
      expect(snapshot.onlineServers.single.uptimeBrief, 'up 1:02');
    });

    test('timeout maps the server to offline without throwing', () async {
      final ServerConfig a = buildConfig('a', 'slow-box');

      when(() => executor.execute(
            serverId: 'a',
            command: any(named: 'command'),
            timeout: any(named: 'timeout'),
          )).thenAnswer((_) async => Result<CommandResult>.failure(
            AppFailure.timeout(SshHealthProbe.probeTimeout),
          ));

      final FleetHealthSnapshot snapshot =
          await container.read(sshHealthProbeProvider).probeFleet([a]);

      expect(snapshot.onlineCount, 0);
      expect(snapshot.totalCount, 1);
      expect(snapshot.mood, FleetMood.allOffline);
      expect(snapshot.offlineServers.single.serverName, 'slow-box');
    });

    test('parses uptime output variants', () {
      // procps style: users + load average.
      expect(
        SshHealthProbe.parseUptimeBrief(
          ' 14:32:01 up 8 days,  3:42,  2 users,  load average: 0.52, 0.58, 0.60',
        ),
        'up 8 days, 3:42',
      );
      // busybox style: no user count.
      expect(
        SshHealthProbe.parseUptimeBrief(' 14:32:01 up 2:14, load average: 0.08'),
        'up 2:14',
      );
      // load figures from either the uptime line or /proc/loadavg.
      expect(
        SshHealthProbe.parseLoadAverage(
          ' 14:32:01 up 8 days,  3:42,  2 users,  load average: 0.52, 0.58, 0.60',
        ),
        '0.52, 0.58, 0.60',
      );
      expect(
        SshHealthProbe.parseLoadAverage('0.52 0.58 0.60 1/847 12345'),
        '0.52, 0.58, 0.60',
      );
      // Unparseable output yields nulls rather than garbage.
      expect(SshHealthProbe.parseUptimeBrief('Welcome to Ubuntu'), isNull);
      expect(SshHealthProbe.parseLoadAverage('nothing numeric here'), isNull);
    });

    test('caches the snapshot until the TTL expires or the fleet changes',
        () async {
      final ServerConfig a = buildConfig('a', 'web-01');
      final ServerConfig b = buildConfig('b', 'db-01');

      var calls = 0;
      when(() => executor.execute(
            serverId: any(named: 'serverId'),
            command: any(named: 'command'),
            timeout: any(named: 'timeout'),
          )).thenAnswer((_) async {
        calls++;
        return Result<CommandResult>.success(
          buildResult('a', 'web-01', ' 10:00:00 up 1:02,  load average: 0.1, 0.2, 0.3'),
        );
      });

      final SshHealthProbe probe = container.read(sshHealthProbeProvider);

      final FleetHealthSnapshot first = await probe.probeFleet([a, b]);
      expect(calls, 2); // two servers, one round.

      // Fresh cache + same fleet -> no new probe.
      final FleetHealthSnapshot second = await probe.probeFleet([a, b]);
      expect(identical(first, second), isTrue);
      expect(calls, 2);

      // Different fleet -> new round.
      await probe.probeFleet([a]);
      expect(calls, 3);

      // Forced probe bypasses the cache.
      await probe.probeFleet([a], force: true);
      expect(calls, 4);
    });

    test('empty fleet returns an empty snapshot without calling the executor',
        () async {
      final FleetHealthSnapshot snapshot =
          await container.read(sshHealthProbeProvider).probeFleet(const []);

      expect(snapshot.totalCount, 0);
      expect(snapshot.mood, FleetMood.empty);
      verifyNever(() => executor.execute(
            serverId: any(named: 'serverId'),
            command: any(named: 'command'),
            timeout: any(named: 'timeout'),
          ));
    });

    test('non-zero exit without uptime signature counts as offline', () async {
      final ServerConfig a = buildConfig('a', 'shell-quota-box');

      when(() => executor.execute(
            serverId: 'a',
            command: any(named: 'command'),
            timeout: any(named: 'timeout'),
          )).thenAnswer((_) async => Result<CommandResult>.success(
            buildResult('a', 'shell-quota-box', 'Permission denied', exitCode: 127),
          ));

      final FleetHealthSnapshot snapshot =
          await container.read(sshHealthProbeProvider).probeFleet([a]);

      expect(snapshot.mood, FleetMood.allOffline);
    });
  });

  group('FleetHealthNotifier', () {
    test('probe publishes state and guards re-entrant calls', () async {
      final ServerConfig a = buildConfig('a', 'web-01');
      final Completer<Result<CommandResult>> gate =
          Completer<Result<CommandResult>>();

      when(() => executor.execute(
            serverId: 'a',
            command: any(named: 'command'),
            timeout: any(named: 'timeout'),
          )).thenAnswer((_) async => await gate.future);

      final FleetHealthNotifier notifier =
          container.read(fleetHealthProvider.notifier);

      final Future<void> inFlight = notifier.probe([a], force: true);
      expect(container.read(fleetHealthProvider).isProbing, isTrue);

      // Re-entrant call while probing is ignored (no second execute).
      await notifier.probe([a], force: true);

      gate.complete(Result<CommandResult>.success(
        buildResult('a', 'web-01', ' 10:00:00 up 1:02,  load average: 0.1, 0.2, 0.3'),
      ));
      await inFlight;

      // Exactly one execute for the whole test — the re-entrant probe was
      // swallowed by the in-flight guard.
      verify(() => executor.execute(
            serverId: 'a',
            command: any(named: 'command'),
            timeout: any(named: 'timeout'),
          )).called(1);

      expect(container.read(fleetHealthProvider).isProbing, isFalse);
      expect(container.read(fleetHealthProvider).snapshot?.onlineCount, 1);
    });
  });
}
