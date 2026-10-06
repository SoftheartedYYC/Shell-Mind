import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/ssh/ssh_reconnect_coordinator.dart';
import '../../../server_config/domain/entities/server_config.dart';
import '../../../server_config/presentation/providers/server_config_providers.dart';
import '../../domain/entities/connection_state.dart';
import '../providers/terminal_tab_providers.dart';
import 'terminal_view.dart';

// ─── Top bar ──────────────────────────────────────────────────────────────

class TerminalTopBar extends StatelessWidget {
  const TerminalTopBar({
    super.key,
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
class TerminalTabStrip extends StatelessWidget {
  const TerminalTabStrip({
    super.key,
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
        in ref.watch(serverConfigListProvider).value ??
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

class StatusStrip extends StatelessWidget {
  const StatusStrip({
    super.key,
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
            _UptimeChip(connectedAt: connectedAt!)
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
}

/// Self-ticking uptime readout: owns a 1s timer and rebuilds only itself, so
/// the terminal page no longer repaints its whole tree every second just to
/// advance the connection timer.
class _UptimeChip extends StatefulWidget {
  const _UptimeChip({required this.connectedAt});

  final DateTime connectedAt;

  @override
  State<_UptimeChip> createState() => _UptimeChipState();
}

class _UptimeChipState extends State<_UptimeChip> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String get _label {
    final Duration d = DateTime.now().difference(widget.connectedAt);
    final int h = d.inHours;
    final int m = d.inMinutes.remainder(60);
    final int s = d.inSeconds.remainder(60);
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '${two(h)}:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    return _MetaChip(icon: Icons.schedule_rounded, label: _label);
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
class OverlayShell extends StatelessWidget {
  const OverlayShell({super.key, required this.child, this.opacity = 0.88});

  final Widget child;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kTerminalTheme.background.withValues(alpha: opacity),
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
