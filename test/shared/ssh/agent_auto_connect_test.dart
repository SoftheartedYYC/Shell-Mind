import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shell_mind/core/storage/preferences_service.dart';
import 'package:shell_mind/features/ai_chat/domain/repositories/chat_repository.dart';
import 'package:shell_mind/features/ai_chat/presentation/providers/chat_providers.dart';
import 'package:shell_mind/features/server_config/domain/entities/server_config.dart';
import 'package:shell_mind/features/server_config/presentation/providers/server_config_providers.dart';
import 'package:shell_mind/features/ssh_terminal/data/ssh_client_manager.dart';
import 'package:shell_mind/features/ssh_terminal/domain/entities/connection_state.dart';
import 'package:shell_mind/shared/ssh/agent_controller.dart';
import 'package:shell_mind/shared/ssh/ssh_session_registry.dart';

class MockSshClientManager extends Mock implements SshClientManager {}

class MockChatRepository extends Mock implements ChatRepository {}

/// Serves a fixed saved fleet without Hive — drives the offline-config
/// resolution inside [AgentController]'s auto-connect path.
class _FakeFleetController extends ServerConfigListController {
  _FakeFleetController(this._fleet);

  final List<ServerConfig> _fleet;

  @override
  Future<List<ServerConfig>> build() async => _fleet;
}

/// Tests for the AI auto-connect dial path.
///
/// When a command block targets an offline-but-configured server:
/// - `aiAutoConnect` on → the controller dials through the injectable
///   connect hook and executes once the session goes live;
/// - credential-less dial → [AgentErrorKind.connectAuthRequired];
/// - dial failure → [AgentErrorKind.connectFailed];
/// - `aiAutoConnect` off → the legacy [AgentErrorKind.noTargetServer]
///   behaviour and no dial at all.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String serverId = 'server-1';

  late MockSshClientManager manager;
  late MockChatRepository chatRepo;
  late StreamController<SshConnectionState> stateController;
  late StreamController<String> aiStreamController;

  ServerConfig buildConfig() => ServerConfig(
        id: serverId,
        name: 'web-01',
        host: '10.0.0.1',
        username: 'root',
        createdAt: DateTime(2024),
      );

  setUpAll(() {
    registerFallbackValue(const Duration(seconds: 30));
  });

  setUp(() async {
    // Fresh mock storage per test; the actual gate values are set explicitly
    // inside each test because the singleton keeps its store across setUp runs.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await PreferencesService.instance.init();

    manager = MockSshClientManager();
    chatRepo = MockChatRepository();
    stateController = StreamController<SshConnectionState>.broadcast();
    aiStreamController = StreamController<String>.broadcast();

    when(() => manager.isConnected).thenReturn(true);
    when(() => manager.stateStream).thenAnswer((_) => stateController.stream);
    when(() => manager.dispose()).thenAnswer((_) async {});
    when(() => manager.runCommand(any(), timeout: any(named: 'timeout')))
        .thenAnswer(
      (_) async => const CommandExecutionResult(
        stdout: 'command-output',
        stderr: '',
        exitCode: 0,
      ),
    );
    when(() => chatRepo.sendMessageStream(
          history: any(named: 'history'),
          userMessage: any(named: 'userMessage'),
        )).thenAnswer((_) => aiStreamController.stream);
  });

  tearDown(() async {
    await stateController.close();
    await aiStreamController.close();
  });

  /// Container with **no** live session (the target is offline) and a fixed
  /// saved fleet served by a fake controller.
  ProviderContainer createContainer() {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        chatRepositoryProvider.overrideWithValue(chatRepo),
        serverConfigListProvider.overrideWith(
          () => _FakeFleetController(<ServerConfig>[buildConfig()]),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('AgentController auto-connect', () {
    test('offline target + switch on: dials, registers, executes', () async {
      await PreferencesService.instance.setAiAutoExecute(true);
      await PreferencesService.instance.setAiAutoConnect(true);

      final ProviderContainer container = createContainer();
      final AgentController agent =
          container.read(agentControllerProvider.notifier);

      // Simulate a successful dial: the production hook
      // (SshServerConnectController) registers the live session through the
      // registry on success, so the mock mirrors that.
      agent.connectHook = (String id, ServerConfig config) async {
        container
            .read(sshSessionRegistryProvider.notifier)
            .register(config.id, manager, config);
        return AgentConnectOutcome.success;
      };

      agent.startAutoMode(maxLoops: 5);
      agent.onAssistantResponseComplete(
        '```bash\n# server: web-01\nuptime\n```',
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));

      verify(() => manager.runCommand('uptime', timeout: any(named: 'timeout')))
          .called(1);
      final AgentState state = container.read(agentControllerProvider);
      expect(state.autoLoopCount, 1);
      expect(state.status, AgentStatus.idle);
      expect(state.errorKind, isNull);
      expect(state.results, hasLength(1));
      expect(state.results.first.serverId, serverId);
    });

    test('dial without saved credentials maps to connectAuthRequired',
        () async {
      await PreferencesService.instance.setAiAutoExecute(true);
      await PreferencesService.instance.setAiAutoConnect(true);

      final ProviderContainer container = createContainer();
      final AgentController agent =
          container.read(agentControllerProvider.notifier);

      var hookCalls = 0;
      agent.connectHook = (String id, ServerConfig config) async {
        hookCalls++;
        return AgentConnectOutcome.authRequired;
      };

      agent.startAutoMode(maxLoops: 5);
      agent.onAssistantResponseComplete(
        '```bash\n# server: web-01\nuptime\n```',
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(hookCalls, 1);
      verifyNever(
        () => manager.runCommand(any(), timeout: any(named: 'timeout')),
      );
      final AgentState state = container.read(agentControllerProvider);
      expect(state.errorKind, AgentErrorKind.connectAuthRequired);
      expect(state.errorMessage, isNotNull);
    });

    test('dial failure maps to connectFailed', () async {
      await PreferencesService.instance.setAiAutoExecute(true);
      await PreferencesService.instance.setAiAutoConnect(true);

      final ProviderContainer container = createContainer();
      final AgentController agent =
          container.read(agentControllerProvider.notifier);

      var hookCalls = 0;
      agent.connectHook = (String id, ServerConfig config) async {
        hookCalls++;
        return AgentConnectOutcome.failed;
      };

      agent.startAutoMode(maxLoops: 5);
      agent.onAssistantResponseComplete(
        '```bash\n# server: web-01\nuptime\n```',
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(hookCalls, 1);
      verifyNever(
        () => manager.runCommand(any(), timeout: any(named: 'timeout')),
      );
      final AgentState state = container.read(agentControllerProvider);
      expect(state.errorKind, AgentErrorKind.connectFailed);
      expect(state.errorMessage, isNotNull);
    });

    test('switch off keeps the legacy noTargetServer path and never dials',
        () async {
      await PreferencesService.instance.setAiAutoExecute(true);
      await PreferencesService.instance.setAiAutoConnect(false);

      final ProviderContainer container = createContainer();
      final AgentController agent =
          container.read(agentControllerProvider.notifier);

      var hookCalls = 0;
      agent.connectHook = (String id, ServerConfig config) async {
        hookCalls++;
        return AgentConnectOutcome.failed;
      };

      agent.startAutoMode(maxLoops: 5);
      agent.onAssistantResponseComplete(
        '```bash\n# server: web-01\nuptime\n```',
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(hookCalls, 0);
      verifyNever(
        () => manager.runCommand(any(), timeout: any(named: 'timeout')),
      );
      final AgentState state = container.read(agentControllerProvider);
      expect(state.errorKind, AgentErrorKind.noTargetServer);
      expect(state.errorMessage, isNotNull);
    });

    test('dropped-but-registered session triggers dial and executes', () async {
      await PreferencesService.instance.setAiAutoExecute(true);
      await PreferencesService.instance.setAiAutoConnect(true);

      final ProviderContainer container = createContainer();
      final AgentController agent =
          container.read(agentControllerProvider.notifier);

      // A registry entry that outlived its transport: the session dropped
      // unexpectedly (auto-reconnect in progress or the loop gave up), so
      // the entry is present but the manager reports not connected.
      container
          .read(sshSessionRegistryProvider.notifier)
          .register(serverId, manager, buildConfig());
      when(() => manager.isConnected).thenReturn(false);

      // The dial succeeds and registers a *live* session, mirroring what the
      // production hook (SshServerConnectController) does on success.
      final MockSshClientManager liveManager = MockSshClientManager();
      final StreamController<SshConnectionState> liveController =
          StreamController<SshConnectionState>.broadcast();
      addTearDown(liveController.close);
      when(() => liveManager.isConnected).thenReturn(true);
      when(() => liveManager.stateStream)
          .thenAnswer((_) => liveController.stream);
      when(() => liveManager.dispose()).thenAnswer((_) async {});
      when(() => liveManager.runCommand(any(), timeout: any(named: 'timeout')))
          .thenAnswer(
        (_) async => const CommandExecutionResult(
          stdout: 'dialled-output',
          stderr: '',
          exitCode: 0,
        ),
      );

      var hookCalls = 0;
      agent.connectHook = (String id, ServerConfig config) async {
        hookCalls++;
        container
            .read(sshSessionRegistryProvider.notifier)
            .register(config.id, liveManager, config);
        return AgentConnectOutcome.success;
      };

      agent.startAutoMode(maxLoops: 5);
      // No explicit # server: tag — the fallback resolves to the dropped
      // entry. The entry alone must not pass the needsDial gate: the loop
      // has to dial instead of executing on the dead transport.
      agent.onAssistantResponseComplete('```bash\nuptime\n```');
      await Future<void>.delayed(const Duration(milliseconds: 80));

      // The dial was attempted and the live manager executed the command.
      expect(hookCalls, 1);
      verify(() =>
          liveManager.runCommand('uptime', timeout: any(named: 'timeout')))
          .called(1);
      // The dead transport must never be touched.
      verifyNever(
        () => manager.runCommand(any(), timeout: any(named: 'timeout')),
      );
      final AgentState state = container.read(agentControllerProvider);
      expect(state.autoLoopCount, 1);
      expect(state.status, AgentStatus.idle);
      expect(state.errorKind, isNull);
      expect(state.results, hasLength(1));
      expect(state.results.first.stdout, 'dialled-output');
    });
  });
}
