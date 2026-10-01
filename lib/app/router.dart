import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_constants.dart';
import '../features/ai_chat/presentation/pages/ai_chat_page.dart';
import '../features/server_config/presentation/pages/server_edit_page.dart';
import '../features/server_config/presentation/pages/servers_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/settings/presentation/widgets/update_prompt_dialog.dart';
import '../features/ssh_terminal/presentation/pages/terminal_page.dart';
import '../l10n/app_localizations.dart';

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

/// The application router.
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

      // ─── Add / edit server form ───
      GoRoute(
        path: RoutePaths.serverEdit,
        name: RouteNames.serverEdit,
        parentNavigatorKey: rootKey,
        pageBuilder: (context, state) {
          final String? serverId = state.uri.queryParameters['id'];
          return _fadeThrough(ServerEditPage(serverId: serverId), state);
        },
      ),

      // ─── Full-screen terminal ───
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

/// Bottom-navigation shell using standard Material 3 NavigationBar.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: UpdateGate(child: navigationShell),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.dns_outlined),
            selectedIcon: const Icon(Icons.dns_rounded),
            label: l10n.navServers,
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: const Icon(Icons.chat_bubble_rounded),
            label: l10n.navAiChat,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}

// ─── Route error page ─────────────────────────────────────────────────────

class _RouteErrorPage extends StatelessWidget {
  const _RouteErrorPage({this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.error_outline_rounded, size: 48, color: colors.error),
              const SizedBox(height: 16),
              Text(
                l10n.pageNotFound,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error?.toString() ?? '',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.goNamed(RouteNames.servers),
                child: Text(l10n.backToServers),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
