import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

/// Root widget of the Shell-Mind application.
///
/// Wraps [MaterialApp.router] with the Terminal-Noir theme and the
/// Riverpod-driven [GoRouter] configured in `router.dart`.
class ShellMindApp extends ConsumerWidget {
  const ShellMindApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Shell-Mind',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      highContrastTheme: AppTheme.darkTheme,
      highContrastDarkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      scrollBehavior: const _ShellMindScrollBehavior(),
      builder: (context, child) {
        // Slightly dampen text scale so the dense terminal UI stays legible
        // without collapsing at large system font sizes.
        final MediaQueryData mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.35,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
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
