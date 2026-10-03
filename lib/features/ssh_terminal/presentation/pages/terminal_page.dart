import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xterm/xterm.dart';

import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ssh/ssh_reconnect_coordinator.dart';
import '../../../../shared/ssh/ssh_session_registry.dart';
import '../../../../shared/ssh/terminal_context_provider.dart';
import '../../../ai_chat/domain/entities/ai_chat_extra.dart';
import '../../../command_snippets/domain/entities/command_snippet.dart';
import '../../../command_snippets/presentation/widgets/snippet_picker_sheet.dart';
import '../../../server_config/domain/entities/server_config.dart';
import '../../../server_config/presentation/providers/server_config_providers.dart';
import '../../domain/entities/connection_state.dart';
import '../providers/ssh_providers.dart';
import '../providers/terminal_tab_providers.dart';
import '../widgets/keyboard_toolbar.dart';
import '../widgets/terminal_server_picker_sheet.dart';
import '../widgets/terminal_view.dart';

/// Terminal background constant — the terminal area is always dark.
const Color _kTerminalBg = Color(0xFF1A1B26);

/// Live SSH terminal with multi-tab session switching.
///
/// Mounted from `/terminal/:serverId` (backward compatible with the single-
/// server route). The entered server is seeded as the focused tab; further
/// tabs are opened via the "+" button in the tab strip, each backed by its
/// own app-wide cached xterm [Terminal] (`terminalTabCacheProvider`) so
/// switching never loses scrollback and never drops a connection — sessions
/// live in the global [SshSessionRegistry], not in this page.
class TerminalPage extends ConsumerStatefulWidget {
  const TerminalPage({super.key, required this.serverId});

  /// Server identifier pulled from `/terminal/:serverId`.
  final String serverId;

  @override
  ConsumerState<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends ConsumerState<TerminalPage> {
  final FocusNode _focusNode = FocusNode();

  /// Per-tab selection controllers (one per open server id) so each tab keeps
  /// its own selection state. Created lazily, disposed with the page.
  final Map<String, TerminalController> _tabControllers =
      <String, TerminalController>{};

  /// Tabs whose shell has gone live at least once while this page could see
  /// it — lets a re-focused tab show "session closed" instead of a spinner.
  final Set<String> _everConnected = <String>{};

  /// Server the mirrored chrome state is currently attached to.
  String? _chromeServerId;

  /// Resolved target server (null until the fleet lookup completes).
  ServerConfig? _config;

  /// Set when [widget.serverId] matches no saved server.
  bool _notFound = false;

  double _fontSize = AppConstants.defaultTerminalFontSize;

  /// Drives the uptime readout; only repaints while connected.
  Timer? _uptimeTicker;

  @override
  void initState() {
    super.initState();
    _uptimeTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (ref.read(sshConnectionStateProvider).isConnected) {
        setState(() {});
      }
    });
    // Attach to existing session (if any) and kick connection after first frame
    // so the terminal widget is laid out (and its size known) before PTY opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Seed the entry server as the focused tab (keeps previously-open tabs).
      ref.read(terminalTabsProvider.notifier).seed(widget.serverId);
      // If the registry already has a live session for this server, remember
      // it so a later drop shows the "session closed" surface, not a spinner.
      final RegisteredSession? existing =
          ref.read(sshSessionRegistryProvider)[widget.serverId];
      if (existing != null) {
        _everConnected.add(widget.serverId);
      }
      _focusTab(widget.serverId);
      // Backward compatibility: entering from the servers list with no live
      // session starts the dial right here (as this page always has).
      if (existing == null) unawaited(_startConnectionFor(widget.serverId));
    });
  }

  @override
  void dispose() {
    _uptimeTicker?.cancel();
    _focusNode.dispose();
    for (final TerminalController controller in _tabControllers.values) {
      controller.dispose();
    }
    _tabControllers.clear();
    super.dispose();
  }

  // ─── Tab management ─────────────────────────────────────────────────────

  /// The currently focused tab (entry server as a fallback).
  String get _activeTabId =>
      ref.read(terminalTabsProvider).activeId ?? widget.serverId;

  /// Lazily creates the per-tab [TerminalController] for [serverId].
  TerminalController _controllerFor(String serverId) {
    return _tabControllers.putIfAbsent(serverId, () => TerminalController());
  }

  /// Makes [serverId] the visible tab: opens it, re-attaches the mirrored
  /// chrome state (always, so a freshly registered session's stream is
  /// picked up) and resolves its config for the top bar / status strip.
  void _focusTab(String serverId) {
    ref.read(terminalTabsProvider.notifier).openTab(serverId);
    _attachChromeTo(serverId, force: true);
    final RegisteredSession? session =
        ref.read(sshSessionRegistryProvider)[serverId];
    if (session != null &&
        session.isConnected &&
        !_everConnected.contains(serverId)) {
      setState(() => _everConnected.add(serverId));
    }
    unawaited(_resolveConfigFor(serverId));
  }

  /// Points the mirrored connection state at [serverId] so the status strip
  /// and overlays follow the visible tab's session. [force] re-subscribes
  /// even when already attached (needed after the registry replaced the
  /// manager or registered a session post-attach).
  void _attachChromeTo(String serverId, {bool force = false}) {
    if (!force && _chromeServerId == serverId) return;
    _chromeServerId = serverId;
    ref.read(sshConnectionStateProvider.notifier).attach(serverId);
  }

  /// Opens the server picker behind the "+" button; the chosen server becomes
  /// the focused tab (dialing first when it is still offline).
  Future<void> _openServerPicker() async {
    HapticFeedback.selectionClick();
    await TerminalServerPickerSheet.show(
      context,
      onSelect: _focusTab,
    );
  }

  /// Resolves the config of an arbitrary tab target for display purposes.
  Future<void> _resolveConfigFor(String serverId) async {
    final ServerConfig? resolved = await ref
        .read(serverConfigListProvider.notifier)
        .resolveById(serverId);
    if (!mounted) return;
    if (resolved == null) {
      setState(() => _notFound = true);
      return;
    }
    setState(() {
      _config = resolved;
      _notFound = false;
    });
  }

  /// Closes a tab, keeping its session alive in the registry (connections are
  /// registry-owned, never page-owned). Disposes the tab's selection
  /// controller; when the last tab closes the page pops back to the servers
  /// list.
  void _closeTab(String serverId) {
    final bool wasActive =
        ref.read(terminalTabsProvider).activeId == serverId;
    ref.read(terminalTabsProvider.notifier).closeTab(serverId);
    _tabControllers.remove(serverId)?.dispose();
    if (!wasActive) return;
    final String? next = ref.read(terminalTabsProvider).activeId;
    if (next != null) {
      _focusTab(next);
    } else {
      _popWithoutDisconnect();
    }
  }

  // ─── Connection control ───────────────────────────────────────────────────

  /// Resolves [serverId]'s config and opens the shell via the global
  /// registry. Safe to call again to retry — the registry tears down any
  /// prior session. The mirrored chrome state follows the dialing server.
  Future<void> _startConnectionFor(String serverId) async {
    final ServerConfig? config =
        await ref.read(serverConfigListProvider.notifier).resolveById(serverId);
    if (!mounted || config == null) return;
    _chromeServerId = serverId;
    await ref.read(sshConnectionStateProvider.notifier).connect(config);
  }

  /// Navigates back without disconnecting — the session stays alive in the
  /// global registry so the AI assistant and other pages can still use it.
  void _popWithoutDisconnect() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.servers);
    }
  }

  void _sendInput(String data) {
    final session = ref.read(sshSessionRegistryProvider)[_activeTabId];
    session?.manager.sendInput(data);
  }

  void _bumpFontSize(double delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _fontSize = (_fontSize + delta).clamp(
        AppConstants.minTerminalFontSize,
        AppConstants.maxTerminalFontSize,
      );
    });
  }

  // ─── Ask AI ─────────────────────────────────────────────────────────────

  /// Hands the current terminal selection (if any) off to the AI assistant.
  ///
  /// Always scopes the terminal-context provider to this server so the chat
  /// page can attach live output. When text is selected a confirmation sheet
  /// previews what will be sent; otherwise it navigates straight to the chat.
  void _openAiAssistant() {
    HapticFeedback.selectionClick();
    // The assistant always targets the *active* tab's shell.
    final String activeId = _activeTabId;
    final CachedTerminal? cached =
        ref.read(terminalTabCacheProvider)[activeId];
    final Terminal? terminal = cached?.terminal;
    final TerminalController controller = _controllerFor(activeId);

    String? selected;
    final BufferRange? range = controller.selection;
    if (range != null && terminal != null) {
      final String text = terminal.buffer.getText(range).trim();
      if (text.isNotEmpty) selected = text;
    }

    // Scope context capture to this server before we leave the page.
    ref.read(terminalContextProvider.notifier).setServer(widget.serverId);

    if (selected != null) {
      _showAskAiSheet(selected);
    } else {
      _navigateToAi(null);
    }
  }

  void _navigateToAi(String? query) {
    context.goNamed(
      RouteNames.aiChat,
      extra: AiChatExtra(
        serverId: widget.serverId,
        initialQuery: query,
        attachedTerminalContext: true,
      ),
    );
  }

  // ─── Command snippets ────────────────────────────────────────────────────

  /// Opens the snippet picker; the chosen command is piped into the live
  /// shell immediately, terminated by a newline so it executes.
  Future<void> _openSnippets() async {
    HapticFeedback.selectionClick();
    final CommandSnippet? snippet = await SnippetPickerSheet.show(context);
    if (!mounted || snippet == null) return;
    _sendInput('${snippet.command}\n');
  }

  void _showAskAiSheet(String selected) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Text(
                  selected,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontFamilyFallback: AppTheme.monoFallback,
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.smart_toy_rounded, color: colors.primary),
                title: Text(l10n.terminalAskAi),
                subtitle: Text(l10n.terminalAskAiSubtitle),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _navigateToAi(selected);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final TerminalTabsState tabs = ref.watch(terminalTabsProvider);
    // Fall back to the entry server until the post-frame seed runs.
    final String activeId = tabs.activeId ?? widget.serverId;
    final TerminalTabStatus tabStatus =
        ref.watch(terminalTabStatusProvider(activeId));
    final CachedTerminal? cached = ref.watch(terminalTabCacheProvider)[activeId];

    // Auto-reconnect feedback: re-attach the mirrored chrome state to the
    // resumed session on success (the registry replaced the manager) and
    // toast the recovery.
    ref.listen<Map<String, SshReconnectState>>(
        sshReconnectStateProvider, (prev, next) {
      final SshReconnectState? before = prev?[activeId];
      final SshReconnectState? after = next[activeId];

      // A live entry vanishing means the loop published idle → reconnected.
      if (before != null && after == null) {
        if (!_everConnected.contains(activeId)) {
          setState(() => _everConnected.add(activeId));
        }
        // Re-attach the mirrored state to the fresh manager.
        ref.read(sshConnectionStateProvider.notifier).attach(activeId);
        final String? name = _config?.name;
        if (name != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).sshReconnectReconnectedSnack(name),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });

    // Mark the visible tab as "went live" once its shell connects, so a
    // later drop shows the "session closed" surface instead of a spinner.
    if (tabStatus.isConnected && !_everConnected.contains(activeId)) {
      _everConnected.add(activeId);
    }

    final bool live = tabStatus.isConnected;
    final SshReconnectState reconnect =
        ref.watch(sshReconnectStateProvider)[activeId] ??
            const SshReconnectState.idle();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _TerminalTopBar(
              serverName: _config?.name ?? activeId,
              identity: _config?.identity,
              fontSize: _fontSize,
              onBack: _popWithoutDisconnect,
              onAskAi: _openAiAssistant,
              onDisconnect: live
                  ? () => unawaited(ref
                      .read(sshConnectionStateProvider.notifier)
                      .disconnectServer(activeId))
                  : null,
              onFontSmaller: () => _bumpFontSize(-1),
              onFontLarger: () => _bumpFontSize(1),
            ),
            _TerminalTabStrip(
              openIds: tabs.openIds,
              activeId: activeId,
              onSelect: _focusTab,
              onClose: _closeTab,
              onAdd: _openServerPicker,
            ),
            _StatusStrip(
              state: SshConnectionState(
                status: tabStatus.connectionStatus,
                errorMessage: tabStatus.errorMessage,
                serverName: _config?.name,
                connectedAt: tabStatus.isConnected
                    ? ref
                        .watch(sshSessionRegistryProvider)[activeId]
                        ?.connectedAt
                    : null,
                failureKind: tabStatus.failureKind,
              ),
              connectedAt: tabStatus.isConnected
                  ? ref.watch(sshSessionRegistryProvider)[activeId]?.connectedAt
                  : null,
              reconnect: reconnect,
            ),
            Expanded(
              child: ColoredBox(
                color: _kTerminalBg,
                child: Stack(
                  children: <Widget>[
                    // The active tab's terminal is always mounted so its I/O
                    // stays wired and output paints even beneath a transient
                    // overlay. The ValueKey forces the viewport to rebuild
                    // when switching tabs (the cache swaps buffers wholesale).
                    if (cached != null)
                      Positioned.fill(
                        child: ShellTerminalView(
                          key: ValueKey<Terminal>(cached.terminal),
                          terminal: cached.terminal,
                          controller: _controllerFor(activeId),
                          fontSize: _fontSize,
                          focusNode: _focusNode,
                          readOnly: !live,
                        ),
                      )
                    else
                      const Positioned.fill(child: ColoredBox(color: _kTerminalBg)),
                    if (!live)
                      Positioned.fill(
                        child: _buildIdleSurface(activeId, tabStatus, reconnect),
                      ),
                  ],
                ),
              ),
            ),
            KeyboardToolbar(
              onSend: _sendInput,
              enabled: live,
              onAskAi: _openAiAssistant,
              onSnippets: _openSnippets,
            ),
          ],
        ),
      ),
    );
  }

  /// Chooses the overlay shown while the active tab's shell is not live:
  /// loading, error, reconnecting, gave-up, "session closed", or
  /// "host not found".
  Widget _buildIdleSurface(
    String serverId,
    TerminalTabStatus tabStatus,
    SshReconnectState reconnect,
  ) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (_notFound) {
      return _OverlayShell(
        child: EmptyState(
          title: l10n.terminalHostNotFound,
          message: l10n.terminalHostNotFoundMessage(serverId),
          icon: Icons.dns_outlined,
          action: OutlinedButton.icon(
            onPressed: () => _closeTab(serverId),
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: Text(l10n.terminalBackToServers),
          ),
        ),
      );
    }

    switch (tabStatus.phase) {
      case TerminalTabPhase.error:
        // While an auto-reconnect loop is driving the recovery, show its
        // progress instead of the plain error surface.
        if (reconnect.isReconnecting) {
          return _buildReconnectingOverlay(l10n, reconnect, serverId);
        }
        if (reconnect.hasGivenUp) {
          return _buildGaveUpOverlay(l10n, reconnect, serverId);
        }
        final AppFailure failure = AppFailure(
          kind: _kindFromName(tabStatus.failureKind),
          message:
              tabStatus.errorMessage ?? l10n.terminalConnectionFailed,
        );
        return _OverlayShell(
          opacity: 0.94,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ErrorBanner(
                  failure: failure,
                  onRetry: () =>
                      unawaited(_startConnectionFor(serverId)),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    onPressed: () => _closeTab(serverId),
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: Text(l10n.terminalBackToServers),
                  ),
                ),
              ],
            ),
          ),
        );
      case TerminalTabPhase.reconnecting:
        return _buildReconnectingOverlay(l10n, reconnect, serverId);
      case TerminalTabPhase.gaveUp:
        return _buildGaveUpOverlay(l10n, reconnect, serverId);
      case TerminalTabPhase.closed:
        // A previously-live shell that has since dropped → offer a reconnect.
        if (_everConnected.contains(serverId)) {
          return _OverlayShell(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.link_off_rounded,
                    size: 40, color: Colors.white54),
                const SizedBox(height: 14),
                Text(
                  l10n.terminalSessionClosed,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.terminalSessionClosedMessage(
                      _config?.name ?? serverId),
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 12, color: Colors.white38),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () =>
                      unawaited(_startConnectionFor(serverId)),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(l10n.terminalReconnect),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      case TerminalTabPhase.connecting:
      case TerminalTabPhase.connected:
        // Dialing / handshaking (or the brief pre-connect frame).
        final String label = tabStatus.authenticating
            ? l10n.terminalAuthenticating
            : l10n.terminalConnecting;
        return _OverlayShell(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const AppSpinner(size: 28),
              const SizedBox(height: 18),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _config == null
                    ? l10n.terminalResolvingHost
                    : '${_config!.identity}:${_config!.port}',
                style: TextStyle(
                  fontFamily: AppTheme.monoFont,
                  fontFamilyFallback: AppTheme.monoFallback,
                  fontSize: 11,
                  letterSpacing: 0.4,
                  color: Colors.white38,
                ),
              ),
            ],
          ),
        );
    }
  }

  /// Overlay while the auto-reconnect loop is actively retrying: spinner,
  /// "重连第 N 次" (with the cap when one is set), and a stop button that
  /// cancels the loop (acting as a manual disconnect).
  Widget _buildReconnectingOverlay(
    AppLocalizations l10n,
    SshReconnectState reconnect,
    String serverId,
  ) {
    final String label = reconnect.maxAttempts != null
        ? l10n.sshReconnectStatusReconnectingOf(
            reconnect.attempt, reconnect.maxAttempts!)
        : l10n.sshReconnectStatusReconnecting(reconnect.attempt);
    return _OverlayShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const AppSpinner(size: 28),
          const SizedBox(height: 18),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (reconnect.lastError != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              reconnect.lastError!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.white38),
            ),
          ],
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => unawaited(
              ref
                  .read(sshConnectionStateProvider.notifier)
                  .disconnectServer(serverId),
            ),
            icon: const Icon(Icons.stop_rounded, size: 16),
            label: Text(l10n.sshReconnectStopAuto),
          ),
        ],
      ),
    );
  }

  /// Sticky overlay once the loop gave up: message, "retry now" (restarts the
  /// backoff loop) and the plain manual reconnect (fresh full connect).
  Widget _buildGaveUpOverlay(
    AppLocalizations l10n,
    SshReconnectState reconnect,
    String serverId,
  ) {
    final String name = _config?.name ?? _reconnectServerNameFallback(reconnect);
    final String message = reconnect.maxAttempts != null
        ? l10n.sshReconnectGaveUpMessage(name, reconnect.maxAttempts!)
        : l10n.sshReconnectGaveUpMessageUnlimited(name);
    return _OverlayShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.cloud_off_rounded, size: 40, color: Colors.white54),
          const SizedBox(height: 14),
          Text(
            l10n.sshReconnectGaveUp,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.white38),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _retryReconnectNow(serverId),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(l10n.sshReconnectRetryNow),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _closeTab(serverId),
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: Text(l10n.terminalBackToServers),
          ),
        ],
      ),
    );
  }

  /// Restarts the gave-up auto-reconnect loop through the registry, or falls
  /// back to a fresh manual connection when no loop is left to retry.
  void _retryReconnectNow(String serverId) {
    final bool started = ref
        .read(sshSessionRegistryProvider.notifier)
        .retryReconnect(serverId);
    if (!started) unawaited(_startConnectionFor(serverId));
  }

  static String _reconnectServerNameFallback(SshReconnectState reconnect) =>
      reconnect.lastError ?? '';

  static FailureKind _kindFromName(String? name) => FailureKind.values.firstWhere(
        (FailureKind k) => k.name == name,
        orElse: () => FailureKind.ssh,
      );
}

// ─── Top bar ──────────────────────────────────────────────────────────────

class _TerminalTopBar extends StatelessWidget {
  const _TerminalTopBar({
    required this.serverName,
    required this.identity,
    required this.fontSize,
    required this.onBack,
    required this.onAskAi,
    required this.onDisconnect,
    required this.onFontSmaller,
    required this.onFontLarger,
  });

  final String serverName;
  final String? identity;
  final double fontSize;
  final VoidCallback onBack;
  final VoidCallback onAskAi;
  final VoidCallback? onDisconnect;
  final VoidCallback onFontSmaller;
  final VoidCallback onFontLarger;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 6, 4),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back_rounded,
                size: 20, color: colors.onSurface),
            tooltip: l10n.terminalTooltipDisconnectBack,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  serverName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (identity != null)
                  Text(
                    identity!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.monoFont,
                      fontFamilyFallback: AppTheme.monoFallback,
                      fontSize: 10,
                      letterSpacing: 0.4,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          _BarButton(
            icon: Icons.smart_toy_rounded,
            tooltip: l10n.terminalTooltipAskAi,
            color: colors.primary,
            onTap: onAskAi,
          ),
          _BarButton(
            icon: Icons.text_decrease_rounded,
            tooltip: l10n.terminalTooltipSmallerText,
            onTap: onFontSmaller,
          ),
          _BarButton(
            icon: Icons.text_increase_rounded,
            tooltip: l10n.terminalTooltipLargerText,
            onTap: onFontLarger,
          ),
          _BarButton(
            icon: Icons.link_off_rounded,
            tooltip: l10n.terminalTooltipDisconnect,
            color: onDisconnect == null
                ? colors.onSurface.withValues(alpha: 0.3)
                : colors.error,
            onTap: onDisconnect,
          ),
        ],
      ),
    );
  }
}

// ─── Tab strip ────────────────────────────────────────────────────────────

/// Horizontal strip of open terminal tabs between the top bar and the status
/// strip. Every open session gets a tab (status dot + server name + close
/// button); a trailing "+" opens the server picker to add another session.
class _TerminalTabStrip extends StatelessWidget {
  const _TerminalTabStrip({
    required this.openIds,
    required this.activeId,
    required this.onSelect,
    required this.onClose,
    required this.onAdd,
  });

  /// Open tab ids in opening order.
  final List<String> openIds;

  /// The visible tab.
  final String activeId;

  final ValueChanged<String> onSelect;
  final ValueChanged<String> onClose;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              itemCount: openIds.length,
              itemBuilder: (BuildContext context, int index) {
                final String id = openIds[index];
                return _TerminalTab(
                  key: ValueKey<String>(id),
                  serverId: id,
                  active: id == activeId,
                  onTap: () => onSelect(id),
                  onClose: () => onClose(id),
                );
              },
            ),
          ),
          IconButton(
            onPressed: onAdd,
            icon: Icon(Icons.add_rounded, size: 20, color: colors.primary),
            tooltip: l10n.terminalTabNewTooltip,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

/// One tab chip: connection status dot, server name, close button.
///
/// Watches [terminalTabStatusProvider] directly so every tab reflects its own
/// session's lifecycle — including background tabs that are reconnecting or
/// have dropped while not visible.
class _TerminalTab extends ConsumerWidget {
  const _TerminalTab({
    super.key,
    required this.serverId,
    required this.active,
    required this.onTap,
    required this.onClose,
  });

  final String serverId;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TerminalTabStatus status =
        ref.watch(terminalTabStatusProvider(serverId));

    String name = serverId;
    for (final ServerConfig config
        in ref.watch(serverConfigListProvider).valueOrNull ??
            const <ServerConfig>[]) {
      if (config.id == serverId) {
        name = config.name;
        break;
      }
    }

    final Color dotColor = switch (status.phase) {
      TerminalTabPhase.connected => context.sem.success,
      TerminalTabPhase.connecting ||
      TerminalTabPhase.reconnecting =>
        context.sem.warning,
      TerminalTabPhase.gaveUp ||
      TerminalTabPhase.error =>
        context.sem.danger,
      TerminalTabPhase.closed => colors.onSurfaceVariant,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: active ? colors.surfaceContainerHighest : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    boxShadow: status.isConnected
                        ? <BoxShadow>[
                            BoxShadow(
                              color: dotColor.withValues(alpha: 0.4),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color:
                          active ? colors.onSurface : colors.onSurfaceVariant,
                    ),
                  ),
                ),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: IconButton(
                    onPressed: onClose,
                    icon: Icon(Icons.close_rounded,
                        size: 14, color: colors.onSurfaceVariant),
                    tooltip: l10n.terminalTabCloseTooltip,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(
        icon,
        size: 18,
        color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      padding: EdgeInsets.zero,
    );
  }
}

// ─── Status strip ─────────────────────────────────────────────────────────

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({
    required this.state,
    required this.connectedAt,
    this.reconnect,
  });

  final SshConnectionState state;
  final DateTime? connectedAt;

  /// Live auto-reconnect progress, when a recovery loop is running for this
  /// session; `null` (or idle) means nothing to surface beyond the status.
  final SshReconnectState? reconnect;

  static Color _colorFor(BuildContext context, SshConnectionStatus status) {
    final ShellMindSemanticColors sem = context.sem;
    return switch (status) {
      SshConnectionStatus.connected => sem.success,
      SshConnectionStatus.connecting => sem.warning,
      SshConnectionStatus.authenticating => sem.warning,
      SshConnectionStatus.error => sem.danger,
      SshConnectionStatus.disconnected =>
        Theme.of(context).colorScheme.onSurfaceVariant,
    };
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Color color = _colorFor(context, state.status);
    final bool pulse = state.isBusy || state.isConnected;
    final String statusLabel = switch (state.status) {
      SshConnectionStatus.connected => l10n.terminalStatusConnected,
      SshConnectionStatus.connecting => l10n.terminalConnecting,
      SshConnectionStatus.authenticating => l10n.terminalAuthenticating,
      SshConnectionStatus.error => l10n.terminalStatusError,
      SshConnectionStatus.disconnected => l10n.terminalStatusOffline,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: <Widget>[
          StatusPill(
            label: statusLabel,
            color: color,
            pulse: pulse,
            size: StatusPillSize.small,
          ),
          const SizedBox(width: 10),
          if (state.isConnected && connectedAt != null)
            _MetaChip(
              icon: Icons.schedule_rounded,
              label: _uptime(connectedAt!),
            )
          else if (state.isError)
            _MetaChip(
              icon: Icons.error_outline_rounded,
              label: l10n.terminalRetryAvailable,
            ),
          const Spacer(),
          _trailingChip(context, l10n),
        ],
      ),
    );
  }

  /// Trailing meta chip: live reconnect progress while a recovery loop is
  /// running, otherwise the static TERM-type badge.
  Widget _trailingChip(BuildContext context, AppLocalizations l10n) {
    final SshReconnectState? live = reconnect;
    if (live != null && live.isReconnecting) {
      return _MetaChip(
        icon: Icons.autorenew_rounded,
        label: l10n.sshReconnectStatusReconnecting(live.attempt),
      );
    }
    return const _MetaChip(
      icon: Icons.shield_outlined,
      label: AppConstants.defaultTermType,
    );
  }

  static String _uptime(DateTime since) {
    final Duration d = DateTime.now().difference(since);
    final int h = d.inHours;
    final int m = d.inMinutes.remainder(60);
    final int s = d.inSeconds.remainder(60);
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '${two(h)}:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 12, color: colors.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.monoFont,
            fontFamilyFallback: AppTheme.monoFallback,
            fontSize: 10,
            letterSpacing: 0.3,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ─── Overlay shell ────────────────────────────────────────────────────────

/// A dimmed, centred panel laid over the terminal for non-live states.
/// Uses a dark semi-transparent background since it sits over the terminal.
class _OverlayShell extends StatelessWidget {
  const _OverlayShell({required this.child, this.opacity = 0.88});

  final Widget child;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kTerminalBg.withValues(alpha: opacity),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: child,
          ),
        ),
      ),
    );
  }
}
