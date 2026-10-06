import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shell_mind/core/utils/result.dart';
import 'package:shell_mind/features/ai_chat/domain/entities/chat_message.dart';
import 'package:shell_mind/features/ai_chat/domain/repositories/chat_repository.dart';
import 'package:shell_mind/features/ai_chat/presentation/providers/chat_providers.dart';
import 'package:shell_mind/features/server_config/domain/entities/server_config.dart';
import 'package:shell_mind/features/ssh_terminal/data/ssh_client_manager.dart';
import 'package:shell_mind/features/ssh_terminal/domain/entities/connection_state.dart';
import 'package:shell_mind/shared/ssh/agent_controller.dart';
import 'package:shell_mind/shared/ssh/ssh_command_executor.dart';
import 'package:shell_mind/shared/ssh/ssh_session_registry.dart';

class MockSshClientManager extends Mock implements SshClientManager {}

class MockChatRepository extends Mock implements ChatRepository {}

/// Executor stub whose multi-server entry always throws a raw (non-AppFailure)
/// exception — drives the controller's [AgentErrorKind.unexpected] path.
class _ThrowingExecutor implements SshCommandExecutor {
  @override
  Future<Result<CommandResult>> execute({
    required String serverId,
    required String command,
    Duration timeout = SshCommandExecutor.defaultTimeout,
  }) async =>
      Result<CommandResult>.failure(AppFailure.ssh('unused'));

  @override
  Future<List<Result<CommandResult>>> executeOnMultiple({
    required List<String> serverIds,
    required String command,
    bool parallel = true,
    Duration timeout = SshCommandExecutor.defaultTimeout,
  }) async =>
      throw StateError('socket gone');

  @override
  Future<Result<CommandResult>> executeOnDefault({
    required String command,
    Duration timeout = SshCommandExecutor.defaultTimeout,
  }) async =>
      Result<CommandResult>.failure(AppFailure.ssh('unused'));
}

void main() {
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

  setUp(() {
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

  ProviderContainer createContainer({
    bool registerSession = true,
    List<Override> overrides = const <Override>[],
  }) {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        chatRepositoryProvider.overrideWithValue(chatRepo),
        ...overrides,
      ],
    );
    addTearDown(container.dispose);
    if (registerSession) {
      container.read(sshSessionRegistryProvider.notifier).register(
            serverId,
            manager,
            buildConfig(),
          );
    }
    return container;
  }

  group('AgentController', () {
    test('initial state is idle and not auto mode', () {
      final ProviderContainer container = createContainer();
      final AgentState state = container.read(agentControllerProvider);
      expect(state.status, AgentStatus.idle);
      expect(state.isAutoMode, isFalse);
      expect(state.autoLoopCount, 0);
    });

    test('executeConfirmed returns result and sends tool message', () async {
      final ProviderContainer container = createContainer();
      final AgentController agent =
          container.read(agentControllerProvider.notifier);

      final Result<CommandResult> result = await agent.executeConfirmed(
        command: 'echo hi',
        serverIds: const <String>[serverId],
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.stdout, 'command-output');
      expect(result.valueOrNull!.serverId, serverId);

      // The tool result was fed back into the conversation.
      final ChatState chat = container.read(chatMessagesProvider);
      expect(
        chat.messages.any((ChatMessage m) => m.role == MessageRole.tool),
        isTrue,
      );
      // Agent returns to idle after a successful confirmed run.
      expect(container.read(agentControllerProvider).status, AgentStatus.idle);
    });

    test('executeConfirmed fails validation when no server selected', () async {
      final ProviderContainer container = createContainer();
      final AgentController agent =
          container.read(agentControllerProvider.notifier);

      final Result<CommandResult> result = await agent.executeConfirmed(
        command: 'echo hi',
        serverIds: const <String>[],
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull!.failure.kind, FailureKind.validation);
      // Defensive pre-check leaves the state untouched: no error is published
      // (the chat page maps this failure via its own Result handling).
      final AgentState state = container.read(agentControllerProvider);
      expect(state.errorKind, isNull);
      expect(state.errorMessage, isNull);
      verifyNever(
        () => manager.runCommand(any(), timeout: any(named: 'timeout')),
      );
    });

    test('executeConfirmed surfaces error state when execution fails', () async {
      when(() => manager.runCommand(any(), timeout: any(named: 'timeout')))
          .thenThrow(AppFailureException(AppFailure.ssh('boom')));
      final ProviderContainer container = createContainer();
      final AgentController agent =
          container.read(agentControllerProvider.notifier);

      final Result<CommandResult> result = await agent.executeConfirmed(
        command: 'echo hi',
        serverIds: const <String>[serverId],
      );

      expect(result.isFailure, isTrue);
      expect(container.read(agentControllerProvider).status, AgentStatus.error);
      // Execution failure is classified as [AgentErrorKind.execFailed] so the
      // UI can render a localised message in any app language.
      final AgentState state = container.read(agentControllerProvider);
      expect(state.errorKind, AgentErrorKind.execFailed);
      expect(state.errorMessage, isNotNull);
    });

    test('auto loop terminates when no more commands', () {
      final ProviderContainer container = createContainer();
      final AgentController agent =
          container.read(agentControllerProvider.notifier);

      agent.startAutoMode(maxLoops: 5);
      expect(container.read(agentControllerProvider).isAutoMode, isTrue);

      // A reply with no executable block ends the loop.
      agent.onAssistantResponseComplete('Here is some prose, no commands.');

      final AgentState state = container.read(agentControllerProvider);
      expect(state.status, AgentStatus.idle);
      expect(state.isAutoMode, isFalse);
      verifyNever(
        () => manager.runCommand(any(), timeout: any(named: 'timeout')),
      );
    });

    test('auto loop executes a parsed command block', () async {
      final ProviderContainer container = createContainer();
      final AgentController agent =
          container.read(agentControllerProvider.notifier);

      agent.startAutoMode(maxLoops: 5);
      agent.onAssistantResponseComplete('''
Sure, run this:
```bash
echo hello
```
''');

      await Future<void>.delayed(const Duration(milliseconds: 80));

      verify(() => manager.runCommand('echo hello', timeout: any(named: 'timeout')))
          .called(1);
      final AgentState state = container.read(agentControllerProvider);
      expect(state.autoLoopCount, 1);
      expect(state.status, AgentStatus.idle);
    });

    test('auto loop stops at maxTurns', () async {
      final ProviderContainer container = createContainer();
      final AgentController agent =
          container.read(agentControllerProvider.notifier);

      agent.startAutoMode(maxLoops: 1);
      // First response runs one command -> autoLoopCount becomes 1.
      agent.onAssistantResponseComplete('```bash\necho one\n```');
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(container.read(agentControllerProvider).autoLoopCount, 1);

      // Second response must be refused because the loop budget is spent.
      agent.onAssistantResponseComplete('```bash\necho two\n```');
      await Future<void>.delayed(const Duration(milliseconds: 80));

      final AgentState state = container.read(agentControllerProvider);
      expect(state.isAutoMode, isFalse);
      expect(state.status, AgentStatus.idle);
      // Only the first command was ever executed.
      verify(() => manager.runCommand(any(), timeout: any(named: 'timeout')))
          .called(1);
    });

    test('stopAutoMode terminates loop immediately', () async {
      final ProviderContainer container = createContainer();
      final AgentController agent =
          container.read(agentControllerProvider.notifier);

      agent.startAutoMode(maxLoops: 5);
      agent.stopAutoMode();

      final AgentState state = container.read(agentControllerProvider);
      expect(state.status, AgentStatus.stopped);
      expect(state.isAutoMode, isFalse);

      // A subsequent response is ignored because auto mode is off.
      agent.onAssistantResponseComplete('```bash\necho ignored\n```');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      verifyNever(
        () => manager.runCommand(any(), timeout: any(named: 'timeout')),
      );
    });

    test('dangerous commands are skipped in auto mode', () async {
      final ProviderContainer container = createContainer();
      final AgentController agent =
          container.read(agentControllerProvider.notifier);

      agent.startAutoMode(maxLoops: 5);
      agent.onAssistantResponseComplete('''
```bash
rm -rf /
```
''');

      await Future<void>.delayed(const Duration(milliseconds: 80));

      // The destructive command was never dispatched to the manager.
      verifyNever(
        () => manager.runCommand(any(), timeout: any(named: 'timeout')),
      );
      final AgentState state = container.read(agentControllerProvider);
      expect(state.errorMessage, isNotNull);
      expect(state.status, AgentStatus.idle);
      // Skipped dangerous commands carry a machine-readable kind plus the
      // truncated command as the interpolation argument.
      expect(state.errorKind, AgentErrorKind.dangerSkipped);
      expect(state.errorArg, isNotNull);
      expect(state.errorArg, contains('rm -rf /'));
    });

    test('reset restores initial state', () async {
      final ProviderContainer container = createContainer();
      final AgentController agent =
          container.read(agentControllerProvider.notifier);

      agent.startAutoMode(maxLoops: 3);
      agent.reset();

      final AgentState state = container.read(agentControllerProvider);
      expect(state, const AgentState());
    });

    test('auto loop reports noTargetServer for unknown # server: tag',
        () async {
      // No sessions registered at all: an AI block that names a server can
      // never resolve, so the loop must stop with the machine-readable
      // noTargetServer kind instead of a raw Chinese-only string.
      final ProviderContainer container = createContainer(
        registerSession: false,
      );
      final AgentController agent =
          container.read(agentControllerProvider.notifier);

      agent.startAutoMode(maxLoops: 5);
      agent.onAssistantResponseComplete('''
```bash
# server: ghost-host
uptime
```
''');

      await Future<void>.delayed(const Duration(milliseconds: 80));

      verifyNever(
        () => manager.runCommand(any(), timeout: any(named: 'timeout')),
      );
      final AgentState state = container.read(agentControllerProvider);
      // The error surfaces through the machine-readable kind + message (the
      // UI maps these to a localised string); the round ends idle because the
      // post-loop bookkeeping runs before any await can observe the transient
      // error status.
      expect(state.status, AgentStatus.idle);
      expect(state.errorKind, AgentErrorKind.noTargetServer);
      expect(state.errorMessage, isNotNull);
    });

    test('unexpected executor exception is classified as unexpected kind',
        () async {
      final ProviderContainer container = createContainer(
        overrides: <Override>[
          sshCommandExecutorProvider.overrideWithValue(_ThrowingExecutor()),
        ],
      );
      final AgentController agent =
          container.read(agentControllerProvider.notifier);

      // A raw (non-AppFailure) exception escapes the executor entirely; the
      // controller keeps the `e.toString()` text but tags the state with the
      // unexpected kind so the UI knows no localised equivalent exists.
      final Result<CommandResult> result = await agent.executeConfirmed(
        command: 'echo hi',
        serverIds: const <String>[serverId],
      );

      expect(result.isFailure, isTrue);
      final AgentState state = container.read(agentControllerProvider);
      expect(state.status, AgentStatus.error);
      expect(state.errorKind, AgentErrorKind.unexpected);
      expect(state.errorMessage, contains('socket gone'));
    });

    test('clearError resets errorKind and errorArg together', () {
      final ProviderContainer container = createContainer();

      // Simulate a dangerSkipped note landing in the state.
      final AgentState withError = container
          .read(agentControllerProvider)
          .copyWith(
            errorMessage: 'Skipped dangerous command: rm -rf /',
            errorKind: AgentErrorKind.dangerSkipped,
            errorArg: 'rm -rf /',
          );
      expect(withError.errorKind, AgentErrorKind.dangerSkipped);

      // A fresh execution turn clears the error: kind and arg must reset
      // together with the message so a stale kind can never be mapped onto
      // a different (localised) message by the UI.
      final AgentState cleared = withError.copyWith(
        status: AgentStatus.executing,
        clearError: true,
      );
      expect(cleared.errorMessage, isNull);
      expect(cleared.errorKind, isNull);
      expect(cleared.errorArg, isNull);

      // A brand-new message without an explicit kind drops the previous kind.
      final AgentState newMessage =
          withError.copyWith(errorMessage: 'fresh failure');
      expect(newMessage.errorMessage, 'fresh failure');
      expect(newMessage.errorKind, isNull);
      expect(newMessage.errorArg, isNull);
    });
  });
}
