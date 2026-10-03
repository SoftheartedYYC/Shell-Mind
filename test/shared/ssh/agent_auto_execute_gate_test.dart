import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shell_mind/core/storage/preferences_service.dart';
import 'package:shell_mind/shared/ssh/agent_controller.dart';

/// Unit tests for the AI auto-execution master gate on
/// [AgentController.startAutoMode].
///
/// The settings "auto-execute commands" switch acts as the global capability
/// switch: with it off, `startAutoMode` must refuse to arm the loop (and
/// leave the state untouched); with it on, the session toggle works as
/// before.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Fresh mock storage per test — the singleton reads live values, so the
    // gate can be flipped between tests via setAiAutoExecute.
    SharedPreferences.setMockInitialValues(<String, Object>{
      'pref.ai_auto_execute': false,
    });
    await PreferencesService.instance.init();
  });

  ProviderContainer createContainer() {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
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
}
