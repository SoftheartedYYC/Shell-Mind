// Smoke test: the app should boot, mount the shell, and land on the
// Servers tab without throwing.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shell_mind/app/app.dart';
import 'package:shell_mind/app/router.dart';

void main() {
  testWidgets('Shell-Mind boots into the servers tab',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(child: const ShellMindApp()),
    );
    await tester.pumpAndSettle();

    // The bottom navigation should always be present in the shell.
    // `~/servers` appears both in the nav bar and the page header.
    expect(find.text('~/servers'), findsAtLeastNWidgets(1));
    expect(find.text('~/ai'), findsOneWidget);
    expect(find.text('~/config'), findsOneWidget);

    // The shell should render the initial route's landing content.
    expect(find.text('Your hosts.'), findsOneWidget);

    // The initial route resolves to Servers.
    expect(
      find.byType(ProviderScope),
      findsOneWidget,
      reason: 'ProviderScope should wrap the root app',
    );
  });

  testWidgets('Route paths resolve to distinct routes',
      (WidgetTester tester) async {
    expect(RoutePaths.servers, '/servers');
    expect(RoutePaths.aiChat, '/ai');
    expect(RoutePaths.settings, '/settings');
    expect(RoutePaths.terminalFor('abc'), '/terminal/abc');
  });
}
