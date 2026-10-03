import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/presentation/providers/locale_provider.dart';
import '../features/settings/presentation/providers/theme_provider.dart';
import '../l10n/app_localizations.dart';
import 'auth_lock.dart';
import 'router.dart';
import 'theme.dart';

/// Root widget of the Shell-Mind application.
///
/// Wraps [MaterialApp.router] with light/dark themes and the
/// Riverpod-driven [GoRouter] configured in `router.dart`.
///
/// Also observes app lifecycle transitions for the biometric app lock:
/// `hidden`/`inactive` flag the session as needing verification and
/// `resumed` triggers the biometric prompt (see [AuthLockController]).
class ShellMindApp extends ConsumerStatefulWidget {
  const ShellMindApp({super.key});

  @override
  ConsumerState<ShellMindApp> createState() => _ShellMindAppState();
}

class _ShellMindAppState extends ConsumerState<ShellMindApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Fire-and-forget: the controller owns the verification round-trip.
    ref.read(authLockProvider.notifier).onAppLifecycleChanged(state);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'ShellMind',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      scrollBehavior: const _ShellMindScrollBehavior(),
      builder: (context, child) {
        final MediaQueryData mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.35,
            ),
          ),
          // The biometric lock overlay sits above every routed page and is
          // driven purely by [authLockProvider], so it works across all
          // navigators (tabs, fullscreen terminal, dialogs).
          child: Stack(
            children: <Widget>[
              child ?? const SizedBox.shrink(),
              const AuthLockOverlay(),
            ],
          ),
        );
      },
    );
  }
}

/// Momentum scrolling on desktop + no overscroll glow on mobile.
class _ShellMindScrollBehavior extends MaterialScrollBehavior {
  const _ShellMindScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  Widget buildOverscrollIndicator(
          BuildContext context, Widget child, ScrollableDetails details) =>
      child;
}
