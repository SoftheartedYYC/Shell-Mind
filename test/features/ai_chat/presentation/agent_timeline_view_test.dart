import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shell_mind/features/ai_chat/presentation/widgets/agent_timeline_sheet.dart';
import 'package:shell_mind/l10n/app_localizations.dart';
import 'package:shell_mind/shared/ssh/ssh_command_executor.dart';

/// Builds a [CommandResult] with sensible defaults for timeline tests.
CommandResult _result({
  String command = 'uname -a',
  int exitCode = 0,
  String stdout = '',
  String stderr = '',
}) {
  return CommandResult(
    serverId: 'srv-1',
    serverName: 'web-01',
    command: command,
    stdout: stdout,
    stderr: stderr,
    exitCode: exitCode,
    elapsed: const Duration(milliseconds: 850),
    executedAt: DateTime(2026, 1, 1, 10, 30),
  );
}

/// Pumps [child] inside a localized scaffold (en locale by default in tests).
Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows empty state when no commands have run',
      (WidgetTester tester) async {
    await _pump(
      tester,
      const AgentTimelineView(
        results: <CommandResult>[],
        taskRounds: 0,
        taskStartedAt: null,
      ),
    );

    // Empty-state copy is present, no summary chips or nodes.
    expect(find.text('No commands executed yet'), findsOneWidget);
    expect(find.textContaining('Run commands via chat'), findsOneWidget);
    expect(find.text('Output'), findsNothing);
    expect(find.textContaining('Exit code'), findsNothing);
  });

  testWidgets('renders a single successful command node with summary',
      (WidgetTester tester) async {
    final CommandResult ok = _result(command: 'uname -a');
    await _pump(
      tester,
      AgentTimelineView(
        results: <CommandResult>[ok],
        taskRounds: 1,
        taskStartedAt: DateTime(2026, 1, 1, 10, 30),
      ),
    );

    // Node content: sequence dot, server badge, command text, status, timing.
    expect(find.text('1'), findsOneWidget);
    expect(find.text('web-01'), findsOneWidget);
    expect(find.textContaining('uname -a'), findsOneWidget);
    expect(find.text('Exit code: 0'), findsOneWidget);
    expect(find.text('850ms'), findsOneWidget);

    // Summary chips: rounds / commands / success / failure tallies.
    expect(find.text('1 round'), findsOneWidget);
    expect(find.text('1 command'), findsOneWidget);
    expect(find.text('1 succeeded'), findsOneWidget);
    expect(find.text('0 failed'), findsOneWidget);
    expect(find.textContaining('Started 10:30:00'), findsOneWidget);

    // Empty output -> no collapsible output block, no error output section.
    expect(find.text('Output'), findsNothing);
    expect(find.text('Error output'), findsNothing);
  });

  testWidgets('collapses long output of a failed command and expands on tap',
      (WidgetTester tester) async {
    final CommandResult failed = _result(
      command: './deploy.sh',
      exitCode: 1,
      stdout: 'out-1\nout-2\nout-3\nout-4\nout-5\nout-6',
      stderr: 'boom',
    );
    await _pump(
      tester,
      AgentTimelineView(
        results: <CommandResult>[failed],
        taskRounds: 1,
        taskStartedAt: DateTime(2026, 1, 1, 10, 30),
      ),
    );

    // Collapsed: first 4 lines visible, remainder truncated with a marker.
    expect(find.text('Output'), findsOneWidget);
    expect(find.textContaining('out-4'), findsOneWidget);
    expect(find.textContaining('out-5'), findsNothing);
    expect(find.textContaining('+2'), findsOneWidget);
    // Failed status surfaces the raw exit code and an error output section.
    expect(find.text('Exit code: 1'), findsOneWidget);
    expect(find.text('Error output'), findsOneWidget);
    expect(find.textContaining('boom'), findsOneWidget);

    // Expand the output block: full stdout becomes visible.
    await tester.tap(find.text('Output'));
    await tester.pumpAndSettle();
    expect(find.textContaining('out-6'), findsOneWidget);
    expect(find.textContaining('+2'), findsNothing);
  });

  testWidgets('appends a live running node while executing',
      (WidgetTester tester) async {
    final CommandResult ok = _result();
    await _pump(
      tester,
      AgentTimelineView(
        results: <CommandResult>[ok],
        taskRounds: 1,
        taskStartedAt: DateTime(2026, 1, 1, 10, 30),
        isExecuting: true,
      ),
    );

    // A live placeholder node trails the finished command.
    expect(find.textContaining('Running'), findsOneWidget);
  });
}
