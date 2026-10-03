import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shell_mind/app/theme.dart';
import 'package:shell_mind/features/server_config/domain/entities/server_config.dart';
import 'package:shell_mind/features/server_config/presentation/widgets/health_summary_card.dart';
import 'package:shell_mind/features/server_config/presentation/widgets/server_card.dart';
import 'package:shell_mind/l10n/app_localizations.dart';

/// Regression suite for the fleet list's quick actions:
///
/// * the health card's "AI diagnostics" button must render its label on a
///   tinted (non-primary) background — the app-wide FilledButtonTheme used
///   to paint it primary-on-blue, making the text invisible;
/// * a connected [ServerCard] exposes a disconnect affordance (inline icon
///   button + overflow/sheet entries) wired to the disconnect callback, and
///   an offline card offers none.
ServerConfig buildConfig({String id = 'srv-1'}) => ServerConfig(
      id: id,
      name: 'web-01',
      host: '10.0.0.1',
      username: 'root',
      createdAt: DateTime(2024),
    );

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(child: child),
      ),
    );

void main() {
  group('SnackBarActionButton (AI diagnostics button)', () {
    testWidgets('renders its label on a tinted background', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(
        SnackBarActionButton(
          label: 'AI diagnostics',
          icon: Icons.auto_awesome_rounded,
          onPressed: () {},
        ),
      ));

      // The label text is present...
      expect(find.text('AI diagnostics'), findsOneWidget);

      // ...and the resolved button style is NOT a solid primary background
      // (which would swallow the primary-coloured label). The fix paints a
      // translucent primary tint instead.
      final FilledButton button =
          tester.widget<FilledButton>(find.byType(FilledButton));
      final ButtonStyle? style = button.style;
      expect(style, isNotNull);
      expect(style!.backgroundColor, isNotNull);
      expect(
        style.backgroundColor!.resolve(const <WidgetState>{}),
        isNot(AppTheme.lightTheme.colorScheme.primary),
      );
    });
  });

  group('ServerCard disconnect affordance', () {
    testWidgets('shows inline disconnect button only when connected', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(
        ServerCard(
          config: buildConfig(),
          connected: true,
          onConnect: () {},
          onDisconnect: () {},
          onEdit: () {},
          onDelete: () {},
        ),
      ));

      expect(find.byIcon(Icons.link_off_rounded), findsOneWidget);
    });

    testWidgets('offline card offers no disconnect affordance', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(
        ServerCard(
          config: buildConfig(),
          connected: false,
          onConnect: () {},
          onDisconnect: () {},
          onEdit: () {},
          onDelete: () {},
        ),
      ));

      expect(find.byIcon(Icons.link_off_rounded), findsNothing);
    });

    testWidgets('tapping the inline button fires onDisconnect', (
      WidgetTester tester,
    ) async {
      var disconnected = false;
      await tester.pumpWidget(_wrap(
        ServerCard(
          config: buildConfig(),
          connected: true,
          onConnect: () {},
          onDisconnect: () => disconnected = true,
          onEdit: () {},
          onDelete: () {},
        ),
      ));

      await tester.tap(find.byIcon(Icons.link_off_rounded));
      expect(disconnected, isTrue);
    });

    testWidgets('overflow menu carries the disconnect entry when connected',
        (WidgetTester tester) async {
      var disconnected = false;
      await tester.pumpWidget(_wrap(
        ServerCard(
          config: buildConfig(),
          connected: true,
          onConnect: () {},
          onDisconnect: () => disconnected = true,
          onEdit: () {},
          onDelete: () {},
        ),
      ));

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      final Finder entry = find.text('Disconnect');
      expect(entry, findsOneWidget);

      await tester.tap(entry);
      await tester.pumpAndSettle();
      expect(disconnected, isTrue);
    });
  });
}
