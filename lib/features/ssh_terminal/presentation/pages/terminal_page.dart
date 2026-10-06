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
import '../../data/ssh_client_manager.dart';
import '../../domain/entities/connection_state.dart';
import '../providers/ssh_providers.dart';
import '../providers/terminal_providers.dart';
import '../providers/terminal_tab_providers.dart';
import '../terminal_schemes.dart';
import '../widgets/keyboard_toolbar.dart';
import '../widgets/terminal_chrome.dart';
import '../widgets/terminal_server_picker_sheet.dart';
import '../widgets/tunnel_sheet.dart';
import '../widgets/terminal_view.dart';

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

  @override
  void initState() {
    super.initState();
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

  /// Opens the SFTP file browser for the active tab's server.
  void _openSftp() {
    HapticFeedback.selectionClick();
    context.push(RoutePaths.sftpFor(_activeTabId));
  }

  /// Opens the port-forwarding (SSH tunnel) manager for the active tab.
  void _openTunnels() {
    HapticFeedback.selectionClick();
    TunnelSheet.show(context, _activeTabId);
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
    final TerminalColorScheme scheme = ref.watch(terminalColorSchemeProvider);

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
            TerminalTopBar(
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
              onSftp: live ? _openSftp : null,
              onTunnels: live ? _openTunnels : null,
            ),
            TerminalTabStrip(
              openIds: tabs.openIds,
              activeId: activeId,
              onSelect: _focusTab,
              onClose: _closeTab,
              onAdd: _openServerPicker,
            ),
            StatusStrip(
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
                color: scheme.background,
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
                          scheme: scheme,
                          fontSize: _fontSize,
                          focusNode: _focusNode,
                          readOnly: !live,
                        ),
                      )
                    else
                      Positioned.fill(
                        child: ColoredBox(color: scheme.background),
                      ),
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
      return OverlayShell(
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
        // Host-key failures get a dedicated localised message (D2): a
        // fingerprint change is a security event, not a generic SSH error.
        final String hostKeyHost = _config?.host ?? '';
        final int hostKeyPort = _config?.port ?? 22;
        final String? localisedMessage = switch (tabStatus.failureReason) {
          hostKeyMismatchReason when _config != null =>
            l10n.hostKeyMismatchMessage(hostKeyHost, hostKeyPort),
          hostKeyMismatchReason => l10n.hostKeyMismatchTitle,
          hostKeyRejectionReason => l10n.hostKeyRejectedMessage,
          _ => null,
        };
        final AppFailure failure = AppFailure(
          kind: _kindFromName(tabStatus.failureKind),
          message: localisedMessage ??
              tabStatus.errorMessage ??
              l10n.terminalConnectionFailed,
        );
        return OverlayShell(
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
          return OverlayShell(
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
        return OverlayShell(
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
    return OverlayShell(
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
    return OverlayShell(
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

