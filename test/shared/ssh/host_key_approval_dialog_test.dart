import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell_mind/core/constants/app_constants.dart';
import 'package:shell_mind/l10n/app_localizations.dart';
import 'package:shell_mind/shared/ssh/host_key_approval_dialog.dart';
import 'package:shell_mind/shared/ssh/host_key_store.dart';

void main() {
  const String host = '10.0.0.5';
  const int port = 22;
  const String fingerprint = 'SHA256:abcdef123456';

  /// Resolves with whatever the dialog popped with; set by [pumpDialog].
  Future<bool?>? dialogResult;

  /// Opens the dialog like [HostKeyApprovalDialog.show] does and leaves it on
  /// screen for interaction.
  ///
  /// Uses two fixed pumps instead of [WidgetTester.pumpAndSettle] on purpose:
  /// the countdown's periodic timer schedules a frame every second, so a
  /// settle would fast-forward the fake clock until the auto-reject fires and
  /// leave no time to tap the buttons.
  Future<void> pumpDialog(
    WidgetTester tester, {
    Duration countdown = const Duration(seconds: 60),
  }) async {
    dialogResult = null;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => Center(
              child: TextButton(
                onPressed: () {
                  dialogResult = showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => HostKeyApprovalDialog(
                      host: host,
                      port: port,
                      fingerprint: fingerprint,
                      countdown: countdown,
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump(); // route push begins
    await tester.pump(const Duration(milliseconds: 250)); // entrance settles
  }

  /// Closes a still-open dialog via the Reject button so no periodic timer
  /// survives into the next test.
  Future<void> closeViaReject(WidgetTester tester) async {
    await tester.tap(find.text('Reject'));
    await tester.pumpAndSettle();
  }

  group('HostKeyApprovalDialog', () {
    testWidgets(
      'shows endpoint, fingerprint and the countdown notice',
      (WidgetTester tester) async {
        await pumpDialog(tester, countdown: const Duration(seconds: 30));

        expect(find.text('$host:$port'), findsOneWidget);
        expect(find.text(fingerprint), findsOneWidget);
        expect(find.textContaining('Auto-rejects in 30s'), findsOneWidget);

        // Ticking: after one pump-second the copy shows 29.
        await tester.pump(const Duration(seconds: 1));
        expect(find.textContaining('Auto-rejects in 29s'), findsOneWidget);

        await closeViaReject(tester);
      },
    );

    testWidgets(
      'trust tap resolves true',
      (WidgetTester tester) async {
        await pumpDialog(tester, countdown: const Duration(seconds: 30));

        await tester.tap(find.text('Trust and connect'));
        await tester.pumpAndSettle();

        expect(find.byType(HostKeyApprovalDialog), findsNothing);
        expect(await dialogResult, isTrue);
      },
    );

    testWidgets(
      'reject tap resolves false before the countdown expires',
      (WidgetTester tester) async {
        await pumpDialog(tester, countdown: const Duration(seconds: 30));

        await tester.tap(find.text('Reject'));
        await tester.pumpAndSettle();

        expect(find.byType(HostKeyApprovalDialog), findsNothing);
        expect(await dialogResult, isFalse);
      },
    );

    testWidgets(
      'countdown expiry auto-rejects and closes the dialog',
      (WidgetTester tester) async {
        await pumpDialog(tester, countdown: const Duration(seconds: 2));

        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(HostKeyApprovalDialog), findsOneWidget);

        // Second tick reaches zero: settle(false) pops the route. The
        // periodic timer is cancelled inside _settle, so a settle here only
        // drains the exit animation — no pending timers remain.
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        expect(find.byType(HostKeyApprovalDialog), findsNothing);
        expect(await dialogResult, isFalse);
      },
    );

    testWidgets(
      'urgent styling kicks in when 10 seconds or fewer remain',
      (WidgetTester tester) async {
        await pumpDialog(tester, countdown: const Duration(seconds: 11));

        expect(find.textContaining('Auto-rejects in 11s'), findsOneWidget);
        await tester.pump(const Duration(seconds: 1));

        expect(find.textContaining('Auto-rejects in 10s'), findsOneWidget);
        final ColorScheme colors = Theme.of(
          tester.element(find.byType(HostKeyApprovalDialog)),
        ).colorScheme;
        final Icon icon =
            tester.widget<Icon>(find.byIcon(Icons.timer_outlined));
        expect(icon.color, colors.error);

        await closeViaReject(tester);
      },
    );

    testWidgets(
      'default countdown comes from AppConstants and stays inside the '
      'approval handshake budget',
      (WidgetTester tester) async {
        await pumpDialog(tester);

        expect(
          find.textContaining(
            'Auto-rejects in '
            '${AppConstants.hostKeyApprovalTimeout.inSeconds}s',
          ),
          findsOneWidget,
        );
        // The invariant the fix relies on: countdown strictly below the
        // handshake budget granted for approval-enabled connections.
        expect(
          AppConstants.hostKeyApprovalTimeout,
          lessThan(AppConstants.sshHandshakeTimeoutWithApproval),
        );

        await closeViaReject(tester);
      },
    );

    testWidgets(
      'zero countdown rejects immediately on the first frame',
      (WidgetTester tester) async {
        await pumpDialog(tester, countdown: Duration.zero);
        await tester.pumpAndSettle();

        expect(find.byType(HostKeyApprovalDialog), findsNothing);
        expect(await dialogResult, isFalse);
      },
    );
  });

  group('countdown expiry leaves the trust store untouched', () {
    test(
      'handler resolving false after expiry (auto-reject shape) records '
      'nothing',
      () async {
        final InMemoryHostKeyStore store = InMemoryHostKeyStore();

        // Same outcome as the dialog's countdown expiry: the await resolves
        // false, so verifyHostKeyTrust must take the rejection path without
        // touching the store. The timing itself is covered by the widget
        // tests above; here only the store contract matters.
        Future<bool> handler(String h, int p, String f) async => false;

        final bool ok = await verifyHostKeyTrust(
          store: store,
          host: host,
          port: port,
          fingerprint: fingerprint,
          approvalHandler: handler,
        );

        expect(ok, isFalse);
        expect(await store.get(host, port), isNull);
        expect(store.length, 0);
      },
    );

    test(
      'handler answering true is the only path that records the fingerprint',
      () async {
        final InMemoryHostKeyStore store = InMemoryHostKeyStore();

        Future<bool> handler(String h, int p, String f) async => true;

        final bool ok = await verifyHostKeyTrust(
          store: store,
          host: host,
          port: port,
          fingerprint: fingerprint,
          approvalHandler: handler,
        );

        expect(ok, isTrue);
        expect(await store.get(host, port), fingerprint);
        expect(store.length, 1);
      },
    );
  });
}
