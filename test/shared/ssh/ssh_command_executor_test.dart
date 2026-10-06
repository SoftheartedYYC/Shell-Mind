import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shell_mind/core/utils/result.dart';
import 'package:shell_mind/features/server_config/domain/entities/server_config.dart';
import 'package:shell_mind/features/ssh_terminal/data/ssh_client_manager.dart';
import 'package:shell_mind/features/ssh_terminal/domain/entities/connection_state.dart';
import 'package:shell_mind/shared/ssh/ssh_command_executor.dart';
import 'package:shell_mind/shared/ssh/ssh_session_registry.dart';

class MockSshClientManager extends Mock implements SshClientManager {}

void main() {
  late StreamController<SshConnectionState> stateController1;
  late StreamController<SshConnectionState> stateController2;
  late MockSshClientManager manager1;
  late MockSshClientManager manager2;

  const String serverId1 = 'server-1';
  const String serverId2 = 'server-2';

  ServerConfig buildConfig(String id, String name) => ServerConfig(
        id: id,
        name: name,
        host: '10.0.0.1',
        username: 'root',
        createdAt: DateTime(2024),
      );

  /// Stubs [manager] so it reports a connected shell and echoes a successful
  /// command result unless overridden.
  void stubManager(
    MockSshClientManager manager,
    StreamController<SshConnectionState> controller, {
    String stdout = 'ok',
    String stderr = '',
    int exitCode = 0,
  }) {
    when(() => manager.isConnected).thenReturn(true);
    when(() => manager.stateStream).thenAnswer((_) => controller.stream);
    when(() => manager.runCommand(any(), timeout: any(named: 'timeout')))
        .thenAnswer(
      (_) async => CommandExecutionResult(
        stdout: stdout,
        stderr: stderr,
        exitCode: exitCode,
      ),
    );
  }

  setUpAll(() {
    registerFallbackValue(const Duration(seconds: 30));
  });

  setUp(() {
    stateController1 = StreamController<SshConnectionState>.broadcast();
    stateController2 = StreamController<SshConnectionState>.broadcast();
    manager1 = MockSshClientManager();
    manager2 = MockSshClientManager();
    stubManager(manager1, stateController1, stdout: 'result-1');
    stubManager(manager2, stateController2, stdout: 'result-2');
  });

  tearDown(() async {
    await stateController1.close();
    await stateController2.close();
  });

  Future<ProviderContainer> createContainer() async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    final SshSessionRegistry registry =
        container.read(sshSessionRegistryProvider.notifier);
    registry.register(serverId1, manager1, buildConfig(serverId1, 'web-01'));
    // Guarantee a strictly later connectedAt for server-2 so defaultSession
    // ordering is deterministic regardless of clock resolution.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    registry.register(serverId2, manager2, buildConfig(serverId2, 'web-02'));
    return container;
  }

  group('SshCommandExecutor', () {
    test('execute returns result for successful command', () async {
      final ProviderContainer container = await createContainer();
      final SshCommandExecutor executor =
          container.read(sshCommandExecutorProvider);

      final Result<CommandResult> result = await executor.execute(
        serverId: serverId1,
        command: 'echo hi',
      );

      expect(result.isSuccess, isTrue);
      final CommandResult value = result.valueOrNull!;
      expect(value.serverId, serverId1);
      expect(value.serverName, 'web-01');
      expect(value.command, 'echo hi');
      expect(value.stdout, 'result-1');
      expect(value.exitCode, 0);
      expect(value.success, isTrue);
      verify(() => manager1.runCommand('echo hi', timeout: any(named: 'timeout')))
          .called(1);
    });

    test('execute returns error when session not found', () async {
      final ProviderContainer container = await createContainer();
      final SshCommandExecutor executor =
          container.read(sshCommandExecutorProvider);

      final Result<CommandResult> result = await executor.execute(
        serverId: 'does-not-exist',
        command: 'ls',
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull!.failure.kind, FailureKind.notFound);
      verifyNever(
        () => manager1.runCommand(any(), timeout: any(named: 'timeout')),
      );
    });

    test('execute surfaces non-zero exit code as a successful Result', () async {
      stubManager(manager1, stateController1, stdout: '', stderr: 'boom', exitCode: 2);
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(sshSessionRegistryProvider.notifier).register(
            serverId1,
            manager1,
            buildConfig(serverId1, 'web-01'),
          );
      final SshCommandExecutor executor =
          container.read(sshCommandExecutorProvider);

      final Result<CommandResult> result = await executor.execute(
        serverId: serverId1,
        command: 'false',
      );

      // A non-zero exit is still a delivered result, not a transport failure.
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.exitCode, 2);
      expect(result.valueOrNull!.success, isFalse);
      expect(result.valueOrNull!.stderr, 'boom');
    });

    test('executeOnMultiple parallel execution', () async {
      final ProviderContainer container = await createContainer();
      final SshCommandExecutor executor =
          container.read(sshCommandExecutorProvider);

      final List<Result<CommandResult>> results =
          await executor.executeOnMultiple(
        serverIds: <String>[serverId1, serverId2],
        command: 'uptime',
        parallel: true,
      );

      expect(results, hasLength(2));
      expect(results.every((Result<CommandResult> r) => r.isSuccess), isTrue);
      // Positionally aligned with the requested server ids.
      expect(results[0].valueOrNull!.serverId, serverId1);
      expect(results[1].valueOrNull!.serverId, serverId2);
      verify(() => manager1.runCommand('uptime', timeout: any(named: 'timeout')))
          .called(1);
      verify(() => manager2.runCommand('uptime', timeout: any(named: 'timeout')))
          .called(1);
    });

    test('executeOnMultiple sequential execution', () async {
      final ProviderContainer container = await createContainer();
      final SshCommandExecutor executor =
          container.read(sshCommandExecutorProvider);

      final List<Result<CommandResult>> results =
          await executor.executeOnMultiple(
        serverIds: <String>[serverId2, serverId1],
        command: 'date',
        parallel: false,
      );

      expect(results, hasLength(2));
      expect(results[0].valueOrNull!.serverId, serverId2);
      expect(results[1].valueOrNull!.serverId, serverId1);
    });

    test('executeOnMultiple returns empty list for empty server ids', () async {
      final ProviderContainer container = await createContainer();
      final SshCommandExecutor executor =
          container.read(sshCommandExecutorProvider);

      final List<Result<CommandResult>> results =
          await executor.executeOnMultiple(
        serverIds: const <String>[],
        command: 'date',
      );

      expect(results, isEmpty);
    });

    test('executeOnMultiple keeps per-server failures independent', () async {
      // manager2 times out while manager1 succeeds.
      when(() => manager2.runCommand(any(), timeout: any(named: 'timeout')))
          .thenThrow(AppFailureException(AppFailure.timeout(const Duration(seconds: 30))));
      final ProviderContainer container = await createContainer();
      final SshCommandExecutor executor =
          container.read(sshCommandExecutorProvider);

      final List<Result<CommandResult>> results =
          await executor.executeOnMultiple(
        serverIds: <String>[serverId1, serverId2],
        command: 'uptime',
        parallel: true,
      );

      expect(results[0].isSuccess, isTrue);
      expect(results[1].isFailure, isTrue);
      expect(results[1].failureOrNull!.failure.kind, FailureKind.timeout);
    });

    test('executeOnDefault targets most recent session', () async {
      final ProviderContainer container = await createContainer();
      final SshCommandExecutor executor =
          container.read(sshCommandExecutorProvider);

      final Result<CommandResult> result = await executor.executeOnDefault(
        command: 'hostname',
      );

      expect(result.isSuccess, isTrue);
      // server-2 was registered last => most recent connectedAt.
      expect(result.valueOrNull!.serverId, serverId2);
    });

    test('isDangerous detects rm -rf /', () {
      expect(SshCommandExecutor.isDangerous('rm -rf /'), isTrue);
      expect(SshCommandExecutor.isDangerous('sudo rm -rf /home'), isTrue);
      expect(SshCommandExecutor.isDangerous('mkfs.ext4 /dev/sda1'), isTrue);
      expect(SshCommandExecutor.isDangerous('dd if=/dev/zero of=/dev/sda'),
          isTrue);
      expect(SshCommandExecutor.isDangerous('shutdown now'), isTrue);
      expect(SshCommandExecutor.isDangerous('reboot'), isTrue);
      expect(SshCommandExecutor.isDangerous('chmod -R 777 /'), isTrue);
    });

    test('isDangerous returns false for benign commands', () {
      expect(SshCommandExecutor.isDangerous('ls -la'), isFalse);
      expect(SshCommandExecutor.isDangerous('echo hello'), isFalse);
      expect(SshCommandExecutor.isDangerous('cat /var/log/syslog'), isFalse);
      expect(SshCommandExecutor.isDangerous('rm file.txt'), isFalse);
    });

    test('isDangerous detects home directory wipes (rm -rf ~ variants)', () {
      expect(SshCommandExecutor.isDangerous('rm -rf ~'), isTrue);
      expect(SshCommandExecutor.isDangerous('rm -fr ~'), isTrue);
      expect(SshCommandExecutor.isDangerous('rm -r -f ~'), isTrue);
      expect(SshCommandExecutor.isDangerous(r'rm -rf $HOME'), isTrue);
      expect(SshCommandExecutor.isDangerous(r'rm -rf ${HOME}'), isTrue);
      expect(SshCommandExecutor.isDangerous('rm -rf ~/projects'), isTrue);
      expect(SshCommandExecutor.isDangerous(r'rm -rf $HOME/work'), isTrue);
      expect(SshCommandExecutor.isDangerous('rm -rf ~bob'), isTrue);
      expect(SshCommandExecutor.isDangerous('sudo rm -rf ~'), isTrue);
      expect(SshCommandExecutor.isDangerous(r'sudo rm -fr $HOME'), isTrue);
    });

    test('isDangerous does not flag safe rm variants', () {
      // Deleting a single file inside the home directory is not a home wipe
      // (no recursive+force flags). Absolute-path wipes are intentionally
      // covered by the pre-existing root pattern asserted above.
      expect(SshCommandExecutor.isDangerous('rm ~/notes.txt'), isFalse);
      expect(SshCommandExecutor.isDangerous('rm -i ~'), isFalse);
      // Without the f flag (no force) the command is at least interactive.
      expect(SshCommandExecutor.isDangerous('rm -r ~/projects'), isFalse);
      expect(SshCommandExecutor.isDangerous('rm -r /tmp/cache'), isFalse);
      // Without the r flag (no recursion) only single files are removed.
      expect(SshCommandExecutor.isDangerous('rm -f ~'), isFalse);
      expect(SshCommandExecutor.isDangerous('rm -f file~'), isFalse);
      // A trailing tilde (backup suffix) is a normal filename, not the home
      // directory — but `rm -rf ~` itself is still caught above.
      expect(SshCommandExecutor.isDangerous('rm -f notes.txt~'), isFalse);
      // Prefix-smuggled binaries must not match.
      expect(SshCommandExecutor.isDangerous('myrm -rf ~'), isFalse);
      // Relative paths are not home-directory wipes.
      expect(SshCommandExecutor.isDangerous('rm -rf build/'), isFalse);
      expect(SshCommandExecutor.isDangerous('rm -rf ./node_modules'), isFalse);
    });

    test('isDangerous detects find -delete', () {
      expect(SshCommandExecutor.isDangerous('find / -name "*.tmp" -delete'),
          isTrue);
      expect(SshCommandExecutor.isDangerous('find . -delete'), isTrue);
      expect(SshCommandExecutor.isDangerous('find /var/log -mtime +7 -delete'),
          isTrue);
      expect(SshCommandExecutor.isDangerous('sudo find /tmp -delete'), isTrue);
      // `-delete` glued to a longer flag must not count.
      expect(SshCommandExecutor.isDangerous('find . -name x -delete-me'),
          isFalse);
    });

    test('isDangerous does not flag find without -delete', () {
      expect(SshCommandExecutor.isDangerous('find / -name "*.log"'), isFalse);
      expect(SshCommandExecutor.isDangerous('find . -type f -print'), isFalse);
      // Piped to xargs rm is aggressive but goes through a real rm invocation;
      // the -delete heuristic targets find's own destructive flag only.
      expect(
          SshCommandExecutor
              .isDangerous('find /var/log -name "*.log" | xargs rm'),
          isFalse);
      // -delete mentioned after a command separator belongs to another command.
      expect(
          SshCommandExecutor.isDangerous('find . -print; echo -delete'), isFalse);
    });

    test('isDangerous detects truncate to zero', () {
      expect(SshCommandExecutor.isDangerous('truncate -s 0 access.log'), isTrue);
      expect(SshCommandExecutor.isDangerous('truncate -s0 access.log'), isTrue);
      expect(SshCommandExecutor.isDangerous('truncate --size=0 access.log'),
          isTrue);
      expect(SshCommandExecutor.isDangerous('truncate --size 0 access.log'),
          isTrue);
      expect(
          SshCommandExecutor.isDangerous('sudo truncate -s 0 /var/log/app.log'),
          isTrue);
      // Extra flags before -s.
      expect(SshCommandExecutor.isDangerous('truncate -v -s 0 file'), isTrue);
    });

    test('isDangerous does not flag non-zero truncate', () {
      // Resizing to a positive value keeps the content model intact.
      expect(SshCommandExecutor.isDangerous('truncate -s 100 disk.img'),
          isFalse);
      expect(SshCommandExecutor.isDangerous('truncate -s 1M sparse.img'),
          isFalse);
      // Zero-ish sizes that are not the bare `0` token must not match.
      expect(SshCommandExecutor.isDangerous('truncate -s 10 file'), isFalse);
      // `0x…` / `00` are not the standalone zero token.
      expect(SshCommandExecutor.isDangerous('truncate -s 0x10 file'), isFalse);
      // Prefix-smuggled binaries must not match.
      expect(SshCommandExecutor.isDangerous('mytruncate -s 0 file'), isFalse);
      // Path substring must not trigger: the command itself is find/truncate.
      expect(
          SshCommandExecutor.isDangerous('ls /usr/bin/truncate -s 0.bin'),
          isFalse);
    });

    test('isDangerous normalises GNU long options to short forms', () {
      // --recursive → -r, --force → -f: the long spellings must hit the same
      // detectors as the short ones (auto mode's only destructive gate).
      expect(SshCommandExecutor.isDangerous('rm --recursive --force ~'), isTrue);
      expect(SshCommandExecutor.isDangerous('rm --force --recursive ~'), isTrue);
      expect(SshCommandExecutor.isDangerous('rm --recursive --force /'), isTrue);
      expect(
          SshCommandExecutor.isDangerous(r'sudo rm --recursive --force $HOME'),
          isTrue);
      expect(SshCommandExecutor.isDangerous('rm --recursive --force ~user'),
          isTrue);
      // Mixed short/long.
      expect(SshCommandExecutor.isDangerous('rm -r --force ~'), isTrue);
      expect(SshCommandExecutor.isDangerous('rm --recursive -f ~'), isTrue);
      // chmod --recursive 777 / normalises into the chmod detector.
      expect(SshCommandExecutor.isDangerous('chmod --recursive 777 /'), isTrue);
    });

    test('isDangerous long options without both flags stay safe', () {
      // Only recursion (no force) keeps rm interactive.
      expect(SshCommandExecutor.isDangerous('rm --recursive ~/projects'),
          isFalse);
      expect(SshCommandExecutor.isDangerous('rm --recursive /tmp/cache'),
          isFalse);
      // Only force (no recursion) removes single files.
      expect(SshCommandExecutor.isDangerous('rm --force ~'), isFalse);
      expect(SshCommandExecutor.isDangerous('rm --force notes.txt'), isFalse);
      // Long options are not normalised when glued into longer words.
      expect(SshCommandExecutor.isDangerous('rm --recursive-dir ~'), isFalse);
      expect(SshCommandExecutor.isDangerous('rm --forcibly ~'), isFalse);
      // A file literally named like a flag must not poison other tokens:
      // no r/f flags around the real name.
      expect(SshCommandExecutor.isDangerous('touch --recursive'), isFalse);
    });

    test('isDangerous leaves dash-glued long options untouched', () {
      // The normalisation lookahead guards `-` too: `--recursive-dir` is one
      // (unknown) token, not `--recursive` + suffix. Rewriting it to `-r-dir`
      // corrupts the command and can fabricate flags — e.g. the old
      // `(?![\w=])` lookahead turned `rm --recursive-dir --force ~` into
      // `rm -r-dir -f ~`, a false positive on a command rm itself rejects.
      expect(SshCommandExecutor.isDangerous('rm --recursive-dir ~'), isFalse);
      expect(
          SshCommandExecutor.isDangerous('rm --recursive-dir --force ~'),
          isFalse);
      expect(
          SshCommandExecutor.isDangerous('rm --recursive --force-weird ~'),
          isFalse);
      // The genuine long spellings must still normalise and be caught.
      expect(SshCommandExecutor.isDangerous('rm --recursive --force ~'), isTrue);
    });

    test('timeout returns AppFailure.timeout', () async {
      when(() => manager1.runCommand(any(), timeout: any(named: 'timeout')))
          .thenThrow(
        AppFailureException(AppFailure.timeout(const Duration(seconds: 30))),
      );
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(sshSessionRegistryProvider.notifier).register(
            serverId1,
            manager1,
            buildConfig(serverId1, 'web-01'),
          );
      final SshCommandExecutor executor =
          container.read(sshCommandExecutorProvider);

      final Result<CommandResult> result = await executor.execute(
        serverId: serverId1,
        command: 'sleep 100',
        timeout: const Duration(seconds: 30),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull!.failure.kind, FailureKind.timeout);
    });
  });
}
