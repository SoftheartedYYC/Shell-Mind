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
import 'package:shell_mind/features/ssh_terminal/data/ssh_client_manager.dart';
import 'package:shell_mind/features/ssh_terminal/domain/entities/connection_state.dart';
import 'package:shell_mind/shared/ssh/agent_controller.dart';
import 'package:shell_mind/shared/ssh/ssh_session_registry.dart';

class MockSshClientManager extends Mock implements SshClientManager {}

class MockChatRepository extends Mock implements ChatRepository {}

/// Tests for the AI auto-execution master gate.
///
/// The settings "auto-execute commands" switch (`aiAutoExecute`) is the
/// global capability switch:
/// - with it off, [AgentController.startAutoMode] refuses to arm the loop,
///   and a finished reply never arms it either;
/// - with it on, a finished reply arms the loop by itself (the chat UI no
///   longer exposes a session toggle), while tool-feedback continuations
///   never re-arm it — a user stop must survive in-flight follow-ups.
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
    // Fresh mock storage per test — the singleton reads live values, so the
    // gate can be flipped between tests via setAiAutoExecute.
    SharedPreferences.setMockInitialValues(<String, Object>{
      'pref.ai_auto_execute': false,
    });
    await PreferencesService.instance.init();

    manager = MockSshClientManager();
    chatRepo = MockChatRepository();
    stateController = StreamController<SshConnectionState>.broadcast();
    aiStreamController = StreamController<String>.broadcast();

    when(() => manager.isConnected).thenReturn(true);
    when(() => manager.stateStream).thenAnswer((_) => stateController.stream);
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

  ProviderContainer createContainer() {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        chatRepositoryProvider.overrideWithValue(chatRepo),
      ],
    );
    addTearDown(container.dispose);
    container.read(sshSessionRegistryProvider.notifier).register(
          serverId,
          manager,
          buildConfig(),
        );
    return container;
  }

  test('startAutoMode is rejected while the master switch is off', () {
    final ProviderContainer container = createContainer();
    final AgentController agent = container.read(agentControllerProvider.notifier);

    final bool accepted = agent.startAutoMode(maxLoops: 5);

    expect(accepted, isFalse);
    expect(container.read(agentControllerProvider).isAutoMode, isFalse);
    expect(container.read(agentControllerProvider).status, AgentStatus.idle);
  });

  test('startAutoMode is accepted once the master switch is on', () async {
    await PreferencesService.instance.setAiAutoExecute(true);

    final ProviderContainer container = createContainer();
    final AgentController agent = container.read(agentControllerProvider.notifier);

    final bool accepted = agent.startAutoMode(maxLoops: 5);

    expect(accepted, isTrue);
    expect(container.read(agentControllerProvider).isAutoMode, isTrue);
    expect(container.read(agentControllerProvider).maxAutoLoops, 5);
  });

  test('rejection leaves a previously running loop untouched', () async {
    await PreferencesService.instance.setAiAutoExecute(true);

    final ProviderContainer container = createContainer();
    final AgentController agent = container.read(agentControllerProvider.notifier);

    expect(agent.startAutoMode(maxLoops: 5), isTrue);
    expect(container.read(agentControllerProvider).autoLoopCount, 0);

    // Flip the gate off mid-run, then try to (re)start.
    await PreferencesService.instance.setAiAutoExecute(false);
    final bool accepted = agent.startAutoMode(maxLoops: 2);

    expect(accepted, isFalse);
    // The already-running loop keeps its budget — it is only stopped via
    // stopAutoMode, never silently reconfigured by a rejected start.
    expect(container.read(agentControllerProvider).maxAutoLoops, 5);
    expect(container.read(agentControllerProvider).isAutoMode, isTrue);
  });

  test('settings switch on: a finished reply arms the loop by itself', () async {
    await PreferencesService.instance.setAiAutoExecute(true);

    final ProviderContainer container = createContainer();
    final AgentController agent = container.read(agentControllerProvider.notifier);

    // No startAutoMode call — the settings switch alone must arm the loop
    // when the first reply lands. The budget comes from preferences.
    agent.onAssistantResponseComplete('```bash\necho hello\n```');
    await Future<void>.delayed(const Duration(milliseconds: 80));

    verify(() => manager.runCommand('echo hello', timeout: any(named: 'timeout')))
        .called(1);
    final AgentState state = container.read(agentControllerProvider);
    expect(state.autoLoopCount, 1);
    expect(state.status, AgentStatus.idle);
    // The loop stays armed for the follow-up reply (continuation flow).
    expect(state.isAutoMode, isTrue);
  });

  test('settings switch off: a finished reply never arms the loop', () async {
    // The singleton keeps values from earlier tests (init() is idempotent),
    // so the off state must be set explicitly rather than relying on setUp.
    await PreferencesService.instance.setAiAutoExecute(false);

    final ProviderContainer container = createContainer();
    final AgentController agent = container.read(agentControllerProvider.notifier);

    agent.onAssistantResponseComplete('```bash\necho ignored\n```');
    await Future<void>.delayed(const Duration(milliseconds: 80));

    verifyNever(
      () => manager.runCommand(any(), timeout: any(named: 'timeout')),
    );
    final AgentState state = container.read(agentControllerProvider);
    expect(state.isAutoMode, isFalse);
    expect(state.status, AgentStatus.idle);
  });

  test('user stop survives an in-flight continuation reply', () async {
    await PreferencesService.instance.setAiAutoExecute(true);

    final ProviderContainer container = createContainer();
    final AgentController agent = container.read(agentControllerProvider.notifier);

    // First reply arms and runs the loop.
    agent.onAssistantResponseComplete('```bash\necho first\n```');
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(container.read(agentControllerProvider).autoLoopCount, 1);

    // The user hits stop; the tool-feedback continuation reply is still in
    // flight and lands afterwards. It must not re-arm the loop.
    agent.stopAutoMode();
    agent.onAssistantResponseComplete(
      '```bash\necho after-stop\n```',
      isContinuation: true,
    );
    await Future<void>.delayed(const Duration(milliseconds: 80));

    verifyNever(
      () => manager.runCommand('echo after-stop', timeout: any(named: 'timeout')),
    );
    expect(container.read(agentControllerProvider).isAutoMode, isFalse);
  });

  test('continuation never arms the loop even with the switch on', () async {
    await PreferencesService.instance.setAiAutoExecute(true);

    final ProviderContainer container = createContainer();
    final AgentController agent = container.read(agentControllerProvider.notifier);

    // A confirmed-execution follow-up (never armed) that lands as a tool
    // continuation must stay non-automatic even though the switch is on.
    agent.onAssistantResponseComplete(
      '```bash\necho follow-up\n```',
      isContinuation: true,
    );
    await Future<void>.delayed(const Duration(milliseconds: 80));

    verifyNever(
      () => manager.runCommand('echo follow-up', timeout: any(named: 'timeout')),
    );
    expect(container.read(agentControllerProvider).isAutoMode, isFalse);
  });
}
