import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../features/ai_chat/presentation/pages/ai_chat_page.dart';
import '../features/server_config/presentation/pages/server_edit_page.dart';
import '../features/server_config/presentation/pages/servers_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/ssh_terminal/presentation/pages/terminal_page.dart';
import 'theme.dart';

// ─── Route name registry ──────────────────────────────────────────────────
abstract final class RouteNames {
  static const String servers = 'servers';
  static const String serverEdit = 'serverEdit';
  static const String aiChat = 'aiChat';
  static const String settings = 'settings';
  static const String terminal = 'terminal';
}

// Path constants reused by navigation calls throughout the app.
abstract final class RoutePaths {
  static const String servers = '/servers';
  static const String serverEdit = '/servers/edit';
  static const String aiChat = '/ai';
  static const String settings = '/settings';
  static const String terminal = '/terminal';

  static String terminalFor(String serverId) => '$terminal/$serverId';

  /// Add form when [serverId] is null, edit form otherwise.
  static String serverEditFor([String? serverId]) =>
      serverId == null ? serverEdit : '$serverEdit?id=$serverId';
}

/// The application router. Kept as a Riverpod provider so it can be
/// invalidated if navigation guards are added later (e.g. onboarding flow).
final Provider<GoRouter> routerProvider = Provider<GoRouter>((ref) {
  final GlobalKey<NavigatorState> rootKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');
  final GlobalKey<StatefulNavigationShellState> shellKey =
      GlobalKey<StatefulNavigationShellState>(debugLabel: 'shell');

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: RoutePaths.servers,
    debugLogDiagnostics: AppConstants.debugRouter,
    routes: <RouteBase>[
      // ─── Main shell: bottom navigation with three primary tabs ───
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: rootKey,
        key: shellKey,
        builder: (BuildContext context, GoRouterState state,
                StatefulNavigationShell navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.servers,
                name: RouteNames.servers,
                pageBuilder: (context, state) =>
                    _fadeThrough(const ServersPage(), state),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.aiChat,
                name: RouteNames.aiChat,
                pageBuilder: (context, state) =>
                    _fadeThrough(const AiChatPage(), state),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.settings,
                name: RouteNames.settings,
                pageBuilder: (context, state) =>
                    _fadeThrough(const SettingsPage(), state),
              ),
            ],
          ),
        ],
      ),

      // ─── Add / edit server form, sits above the shell ───
      GoRoute(
        path: RoutePaths.serverEdit,
        name: RouteNames.serverEdit,
        parentNavigatorKey: rootKey,
        pageBuilder: (context, state) {
          final String? serverId = state.uri.queryParameters['id'];
          return _fadeThrough(ServerEditPage(serverId: serverId), state);
        },
      ),

      // ─── Full-screen terminal, sits above the shell ───
      GoRoute(
        path: '${RoutePaths.terminal}/:serverId',
        name: RouteNames.terminal,
        parentNavigatorKey: rootKey,
        pageBuilder: (context, state) {
          final String serverId = state.pathParameters['serverId'] ?? '';
          return CustomTransitionPage<void>(
            key: state.pageKey,
            transitionDuration: const Duration(milliseconds: 260),
            reverseTransitionDuration: const Duration(milliseconds: 200),
            child: TerminalPage(serverId: serverId),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              final CurvedAnimation curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              );
              return FadeTransition(
                opacity: curved,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.03),
                    end: Offset.zero,
                  ).animate(curved),
                  child: child,
                ),
              );
            },
          );
        },
      ),
    ],
    errorPageBuilder: (context, state) => CustomTransitionPage<void>(
      key: state.pageKey,
      transitionsBuilder: (context, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
      child: _RouteErrorPage(error: state.error),
    ),
  );
});

CustomTransitionPage<void> _fadeThrough(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final CurvedAnimation curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.012),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

// ─── AppShell ─────────────────────────────────────────────────────────────

/// Bottom-navigation shell around the three primary tabs.
///
/// Rather than the default Material pill indicator, this uses a
/// terminal-inspired nav bar: a hairline top border, monospaced
/// "path" labels (`~/servers`, `~/ai`, `~/config`), and a phosphor
/// glow under the active destination.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    // Tapping the active tab pops it back to its root route.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.inkVoid,
      extendBody: false,
      body: navigationShell,
      bottomNavigationBar: _TerminalNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
      ),
    );
  }
}

class _TerminalNavBar extends StatelessWidget {
  const _TerminalNavBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF0C1120),
        border: Border(top: BorderSide(color: AppTheme.inkBorderSoft)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(6, 4, 6, 6),
        child: Row(
          children: <Widget>[
            for (int i = 0; i < _TabSpec.all.length; i++)
              Expanded(
                child: _NavItem(
                  spec: _TabSpec.all[i],
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final _TabSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color tint = selected ? AppTheme.phosphor : AppTheme.textTertiary;

    return Semantics(
      button: true,
      selected: selected,
      label: spec.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.phosphor.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(scale: anim, child: child),
                ),
                child: Icon(
                  selected ? spec.activeIcon : spec.icon,
                  key: ValueKey<bool>(selected),
                  size: 20,
                  color: tint,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                spec.path,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.monoFont,
                  fontFamilyFallback: const <String>[
                    'JetBrains Mono',
                    'Menlo',
                    'Consolas',
                    'monospace',
                  ],
                  fontSize: 9.5,
                  letterSpacing: 0.6,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: tint,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 2,
                width: selected ? 18 : 0,
                decoration: BoxDecoration(
                  color: selected ? AppTheme.phosphor : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: selected
                      ? <BoxShadow>[
                          BoxShadow(
                            color: AppTheme.phosphor.withValues(alpha: 0.6),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec({
    required this.label,
    required this.path,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final String path;
  final IconData icon;
  final IconData activeIcon;

  static const List<_TabSpec> all = <_TabSpec>[
    _TabSpec(
      label: 'Servers',
      path: '~/servers',
      icon: Icons.dns_outlined,
      activeIcon: Icons.dns_rounded,
    ),
    _TabSpec(
      label: 'AI Assistant',
      path: '~/ai',
      icon: Icons.bolt_outlined,
      activeIcon: Icons.bolt_rounded,
    ),
    _TabSpec(
      label: 'Settings',
      path: '~/config',
      icon: Icons.tune_rounded,
      activeIcon: Icons.tune_rounded,
    ),
  ];
}

class _RouteErrorPage extends StatelessWidget {
  const _RouteErrorPage({this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.error_outline_rounded,
                  size: 40, color: AppTheme.coral),
              const SizedBox(height: 12),
              Text('route not found',
                  style: AppTheme.monoStyle(context, size: 14)),
              const SizedBox(height: 8),
              Text(
                error?.toString() ?? '',
                textAlign: TextAlign.center,
                style: context.text.bodySmall
                    ?.copyWith(color: AppTheme.textTertiary),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.goNamed(RouteNames.servers),
                child: const Text('Back to servers'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
