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
import '../../../server_config/domain/entities/server_config.dart';
import '../../../server_config/presentation/providers/server_config_providers.dart';
import '../../domain/entities/connection_state.dart';
import '../providers/ssh_providers.dart';
import '../providers/terminal_providers.dart';
import '../widgets/keyboard_toolbar.dart';
import '../widgets/terminal_view.dart';

/// Live SSH terminal for a single server.
///
/// Mounted from `/terminal/:serverId`. On first frame it resolves the
/// [ServerConfig] and opens an interactive shell; the xterm [Terminal] is wired
/// bidirectionally to the socket by `terminalProvider`. The chrome around it —
/// status bar, phosphor status strip, auxiliary keyboard — reflects the
/// reactive [SshConnectionState], and the socket is torn down automatically
/// when the page unmounts (the SSH providers are `autoDispose`).
class TerminalPage extends ConsumerStatefulWidget {
  const TerminalPage({super.key, required this.serverId});

  /// Server identifier pulled from `/terminal/:serverId`.
  final String serverId;

  @override
  ConsumerState<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends ConsumerState<TerminalPage> {
  final FocusNode _focusNode = FocusNode();

  /// Resolved target server (null until the fleet lookup completes).
  ServerConfig? _config;

  /// Set when [widget.serverId] matches no saved server.
  bool _notFound = false;

  /// Latches once a shell has gone live, so a later drop shows the
  /// "session closed / reconnect" surface instead of the initial spinner.
  bool _hasConnectedOnce = false;

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
    // Kick the connection off after the first frame so the terminal widget is
    // laid out (and its size known) before the PTY opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_startConnection());
    });
  }

  @override
  void dispose() {
    _uptimeTicker?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  // ─── Connection control ───────────────────────────────────────────────────

  /// Resolves the server (once) and opens the shell. Safe to call again to
  /// retry — the manager tears down any prior attempt before dialing.
  Future<void> _startConnection() async {
    if (_config == null) {
      final ServerConfig? resolved = await ref
          .read(serverConfigListProvider.notifier)
          .resolveById(widget.serverId);
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
    await ref.read(sshConnectionStateProvider.notifier).connect(_config!);
  }

  void _disconnectAndPop() {
    // Graceful close before the route pops; autoDispose is the safety net.
    unawaited(ref.read(sshConnectionStateProvider.notifier).disconnect());
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.servers);
    }
  }

  void _sendInput(String data) {
    ref.read(sshRepositoryProvider).sendInput(data);
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

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Track first successful connection to switch the idle surface.
    ref.listen<SshConnectionState>(sshConnectionStateProvider, (_, next) {
      if (next.isConnected && !_hasConnectedOnce) {
        setState(() => _hasConnectedOnce = true);
      }
    });

    final SshConnectionState conn = ref.watch(sshConnectionStateProvider);
    final Terminal terminal = ref.watch(terminalProvider);
    final TerminalController controller = ref.watch(terminalControllerProvider);

    return Scaffold(
      backgroundColor: AppTheme.inkVoid,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _TerminalTopBar(
                serverName: _config?.name ?? conn.serverName ?? widget.serverId,
                identity: _config?.identity,
                fontSize: _fontSize,
                onBack: _disconnectAndPop,
                onDisconnect: conn.isConnected
                    ? () => unawaited(
                        ref.read(sshConnectionStateProvider.notifier).disconnect())
                    : null,
                onFontSmaller: () => _bumpFontSize(-1),
                onFontLarger: () => _bumpFontSize(1),
              ),
              _StatusStrip(state: conn, connectedAt: conn.connectedAt),
              Expanded(
                child: Stack(
                  children: <Widget>[
                    // The terminal is always mounted so its I/O stays wired and
                    // output paints even beneath a transient overlay.
                    Positioned.fill(
                      child: ShellTerminalView(
                        terminal: terminal,
                        controller: controller,
                        fontSize: _fontSize,
                        focusNode: _focusNode,
                        readOnly: !conn.isConnected,
                      ),
                    ),
                    if (!conn.isConnected)
                      Positioned.fill(
                        child: _buildIdleSurface(conn),
                      ),
                  ],
                ),
              ),
              KeyboardToolbar(
                onSend: _sendInput,
                enabled: conn.isConnected,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Chooses the overlay shown while the shell is not live: loading, error,
  /// "session closed", or "host not found".
  Widget _buildIdleSurface(SshConnectionState conn) {
    if (_notFound) {
      return _OverlayShell(
        child: EmptyState(
          title: 'host not found',
          message: 'No saved server matches id "${widget.serverId}". '
              'It may have been deleted.',
          icon: Icons.dns_outlined,
          action: OutlinedButton.icon(
            onPressed: _disconnectAndPop,
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('Back to servers'),
          ),
        ),
      );
    }

    if (conn.isError) {
      final AppFailure failure = AppFailure(
        kind: _kindFromName(conn.failureKind),
        message: conn.errorMessage ?? 'Connection failed.',
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
                onRetry: () => unawaited(_startConnection()),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: _disconnectAndPop,
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Back to servers'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // A previously-live shell that has since dropped → offer a reconnect.
    if (conn.isDisconnected && _hasConnectedOnce) {
      return _OverlayShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.link_off_rounded,
                size: 40, color: AppTheme.textTertiary),
            const SizedBox(height: 14),
            Text(
              'session closed',
              style: TextStyle(
                fontFamily: AppTheme.monoFont,
                fontSize: 13,
                letterSpacing: 0.4,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'The connection to ${_config?.name ?? 'the host'} was terminated.',
              textAlign: TextAlign.center,
              style: context.text.bodySmall
                  ?.copyWith(color: AppTheme.textTertiary),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => unawaited(_startConnection()),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reconnect'),
            ),
          ],
        ),
      );
    }

    // Otherwise: dialing / handshaking (or the brief pre-connect frame).
    final String label = switch (conn.status) {
      SshConnectionStatus.authenticating => 'authenticating',
      _ => 'connecting',
    };
    return _OverlayShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const PhosphorSpinner(size: 26, strokeWidth: 2),
          const SizedBox(height: 18),
          PhosphorLoader(label: label, compact: true),
          const SizedBox(height: 14),
          Text(
            _config == null
                ? 'resolving host…'
                : '${_config!.identity}:${_config!.port}',
            style: TextStyle(
              fontFamily: AppTheme.monoFont,
              fontSize: 11,
              letterSpacing: 0.6,
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

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
    required this.onDisconnect,
    required this.onFontSmaller,
    required this.onFontLarger,
  });

  final String serverName;
  final String? identity;
  final double fontSize;
  final VoidCallback onBack;
  final VoidCallback? onDisconnect;
  final VoidCallback onFontSmaller;
  final VoidCallback onFontLarger;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 6, 4),
      decoration: const BoxDecoration(
        color: Color(0xFF0C1120),
        border: Border(bottom: BorderSide(color: AppTheme.inkBorderSoft)),
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded,
                size: 18, color: AppTheme.textSecondary),
            tooltip: 'Disconnect & back',
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
                  style: context.text.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontSize: 13.5,
                    fontFamily: AppTheme.uiFont,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
                if (identity != null)
                  Text(
                    identity!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.monoFont,
                      fontSize: 9.5,
                      letterSpacing: 0.6,
                      color: AppTheme.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          _BarButton(
            icon: Icons.text_decrease_rounded,
            tooltip: 'Smaller text',
            onTap: onFontSmaller,
          ),
          _BarButton(
            icon: Icons.text_increase_rounded,
            tooltip: 'Larger text',
            onTap: onFontLarger,
          ),
          _BarButton(
            icon: Icons.link_off_rounded,
            tooltip: 'Disconnect',
            color: onDisconnect == null
                ? AppTheme.textDisabled
                : AppTheme.coral,
            onTap: onDisconnect,
          ),
        ],
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
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              icon,
              size: 16,
              color: color ?? AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Status strip ─────────────────────────────────────────────────────────

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.state, required this.connectedAt});

  final SshConnectionState state;
  final DateTime? connectedAt;

  static Color _colorFor(SshConnectionStatus status) => switch (status) {
        SshConnectionStatus.connected => AppTheme.mint,
        SshConnectionStatus.connecting => AppTheme.amber,
        SshConnectionStatus.authenticating => AppTheme.amber,
        SshConnectionStatus.error => AppTheme.coral,
        SshConnectionStatus.disconnected => AppTheme.textTertiary,
      };

  @override
  Widget build(BuildContext context) {
    final Color color = _colorFor(state.status);
    final bool pulse = state.isBusy || state.isConnected;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: const BoxDecoration(
        color: AppTheme.inkVoid,
        border: Border(bottom: BorderSide(color: AppTheme.inkBorderSoft)),
      ),
      child: Row(
        children: <Widget>[
          StatusPill(
            label: state.status.token,
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
            const _MetaChip(
              icon: Icons.error_outline_rounded,
              label: 'retry available',
            ),
          const Spacer(),
          const _MetaChip(
            icon: Icons.shield_outlined,
            label: AppConstants.defaultTermType,
          ),
        ],
      ),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 11, color: AppTheme.textTertiary),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.monoFont,
            fontSize: 10,
            letterSpacing: 0.4,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─── Overlay shell ────────────────────────────────────────────────────────

/// A dimmed, centred panel laid over the terminal for non-live states. The
/// background is near-opaque so the empty buffer doesn't distract, but keeps a
/// hint of the phosphor surface behind it.
class _OverlayShell extends StatelessWidget {
  const _OverlayShell({required this.child, this.opacity = 0.88});

  final Widget child;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.inkVoid.withValues(alpha: opacity),
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
