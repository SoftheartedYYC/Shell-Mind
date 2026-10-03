import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/server_config.dart';

/// A single row in the fleet list — clean, minimal, tappable.
///
/// Visual grammar: a monogram avatar, the server name, the `user@host:port`
/// identity in monospace, an auth badge, an optional group tag, and a
/// last-seen timestamp. Tap connects, long-press (or the ⋮ button) opens
/// the action sheet.
class ServerCard extends StatelessWidget {
  const ServerCard({
    super.key,
    required this.config,
    required this.onConnect,
    required this.onEdit,
    required this.onDelete,
    this.connected = false,
    this.connecting = false,
    this.maskAddress = false,
  });

  final ServerConfig config;
  final VoidCallback onConnect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Live-session hint. Drives the green accent + status dot. Defaults to
  /// false; the terminal feature flips it while a socket is open.
  final bool connected;

  /// True while a dial is in flight — renders a spinner status instead of
  /// the online/offline dot.
  final bool connecting;

  /// When true, host/IP addresses render in a masked (privacy) form.
  final bool maskAddress;

  void _run(BuildContext context, _CardAction action) {
    switch (action) {
      case _CardAction.connect:
        onConnect();
      case _CardAction.edit:
        onEdit();
      case _CardAction.copy:
        Clipboard.setData(ClipboardData(text: 'ssh ${config.identity} '
            '-p ${config.port}'));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context).serverCopiedAddress(config.address)),
            duration: const Duration(milliseconds: 1400),
            behavior: SnackBarBehavior.floating,
          ),
        );
      case _CardAction.delete:
        onDelete();
    }
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) => _ActionSheet(
        config: config,
        maskAddress: maskAddress,
        onAction: (_CardAction action) {
          Navigator.of(sheetContext).pop();
          _run(context, action);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onConnect,
        onLongPress: () => _openSheet(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _Avatar(label: _monogram(config), connected: connected),
              const SizedBox(width: 12),
              Expanded(
                child: _CardBody(
                  config: config,
                  connected: connected,
                  connecting: connecting,
                  maskAddress: maskAddress,
                ),
              ),
              _OverflowMenu(onSelected: (_CardAction a) => _run(context, a)),
            ],
          ),
        ),
      ),
    );
  }

  static String _monogram(ServerConfig c) {
    final String source = c.name.trim().isNotEmpty ? c.name.trim() : c.host;
    if (source.isEmpty) return '?';
    return source.substring(0, 1).toUpperCase();
  }
}

// ─── Card internals ───────────────────────────────────────────────────────

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.config,
    required this.connected,
    required this.connecting,
    required this.maskAddress,
  });

  final ServerConfig config;
  final bool connected;
  final bool connecting;
  final bool maskAddress;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Flexible(
              child: Text(
                config.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _AuthBadge(authType: config.authType),
          ],
        ),
        const SizedBox(height: 4),
        // user@host:port — the identity line. Host part is masked when the
        // privacy toggle is on.
        Text(
          '${config.username}@'
          '${maskAddress ? maskHostAddress(config.host) : config.host}'
          ':${config.port}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: AppTheme.monoFont,
            fontFamilyFallback: AppTheme.monoFallback,
            fontSize: 12,
            color: colors.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            _StatusDot(connected: connected, connecting: connecting),
            const SizedBox(width: 6),
            Text(
              connected
                  ? l10n.serverOnline
                  : connecting
                      ? l10n.aiServerConnecting
                      : _relativeTime(l10n, config.lastConnectedAt),
              style: TextStyle(
                fontSize: 11,
                color: colors.onSurfaceVariant,
              ),
            ),
            if (config.group != null && config.group!.isNotEmpty) ...<Widget>[
              const SizedBox(width: 10),
              Flexible(child: _GroupTag(group: config.group!)),
            ],
          ],
        ),
      ],
    );
  }
}

/// Leading monogram avatar.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.label, required this.connected});

  final String label;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color tint = connected ? colors.primary : colors.onSurfaceVariant;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: connected
            ? colors.primary.withValues(alpha: 0.1)
            : colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: tint,
        ),
      ),
    );
  }
}

class _AuthBadge extends StatelessWidget {
  const _AuthBadge({required this.authType});

  final AuthType authType;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final IconData icon = authType == AuthType.password
        ? Icons.lock_rounded
        : Icons.vpn_key_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 10, color: colors.onSurfaceVariant),
          const SizedBox(width: 3),
          Text(
            authType.token.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupTag extends StatelessWidget {
  const _GroupTag({required this.group});

  final String group;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        group,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: colors.primary,
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.connected, required this.connecting});

  final bool connected;
  final bool connecting;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color color = connected
        ? context.sem.success
        : connecting
            ? context.sem.warning
            : colors.onSurfaceVariant.withValues(alpha: 0.4);
    return connecting
        ? SizedBox(
            width: 7,
            height: 7,
            child: CircularProgressIndicator(
              strokeWidth: 1.4,
              color: color,
            ),
          )
        : Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          );
  }
}

class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu({required this.onSelected});

  final ValueChanged<_CardAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return PopupMenuButton<_CardAction>(
      onSelected: onSelected,
      tooltip: l10n.serverActions,
      position: PopupMenuPosition.under,
      icon: Icon(Icons.more_vert_rounded,
          size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<_CardAction>>[
        _menuEntry(
            context, _CardAction.connect, Icons.terminal_rounded, l10n.serverActionConnect),
        _menuEntry(
            context, _CardAction.edit, Icons.edit_rounded, l10n.serverActionEdit),
        _menuEntry(context, _CardAction.copy, Icons.copy_all_rounded,
            l10n.serverActionCopySsh),
        const PopupMenuDivider(height: 8),
        _menuEntry(
          context,
          _CardAction.delete,
          Icons.delete_outline_rounded,
          l10n.serverActionDelete,
          danger: true,
        ),
      ],
    );
  }
}

PopupMenuItem<_CardAction> _menuEntry(
  BuildContext context,
  _CardAction action,
  IconData icon,
  String label, {
  bool danger = false,
}) {
  final ColorScheme colors = Theme.of(context).colorScheme;
  final Color tint = danger ? colors.error : colors.onSurface;
  return PopupMenuItem<_CardAction>(
    value: action,
    height: 42,
    child: Row(
      children: <Widget>[
        Icon(icon, size: 18, color: danger ? colors.error : colors.onSurfaceVariant),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: tint,
          ),
        ),
      ],
    ),
  );
}

// ─── Action sheet (long-press) ────────────────────────────────────────────

enum _CardAction { connect, edit, copy, delete }

class _ActionSheet extends StatelessWidget {
  const _ActionSheet({
    required this.config,
    required this.maskAddress,
    required this.onAction,
  });

  final ServerConfig config;
  final bool maskAddress;
  final ValueChanged<_CardAction> onAction;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  config.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleLarge?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 3),
                Text(
                  '${maskAddress ? maskHostAddress(config.host) : config.host}'
                  ':${config.port}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.monoFont,
                    fontFamilyFallback: AppTheme.monoFallback,
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _SheetTile(
            icon: Icons.terminal_rounded,
            label: l10n.serverActionConnect,
            color: colors.primary,
            onTap: () => onAction(_CardAction.connect),
          ),
          _SheetTile(
            icon: Icons.edit_rounded,
            label: l10n.serverActionEditDetails,
            onTap: () => onAction(_CardAction.edit),
          ),
          _SheetTile(
            icon: Icons.copy_all_rounded,
            label: l10n.serverActionCopySsh,
            onTap: () => onAction(_CardAction.copy),
          ),
          const Divider(height: 1),
          _SheetTile(
            icon: Icons.delete_outline_rounded,
            label: l10n.serverActionDeleteServer,
            color: colors.error,
            onTap: () => onAction(_CardAction.delete),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color tint = color ?? colors.onSurface;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 20, color: tint),
      title: Text(
        label,
        style: context.text.bodyLarge?.copyWith(
          fontSize: 15,
          color: tint,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────

/// Coarse "time since" formatter for the card's last-seen line.
String _relativeTime(AppLocalizations l10n, DateTime? at) {
  if (at == null) return l10n.serverNeverConnected;
  final Duration diff = DateTime.now().difference(at);
  if (diff.isNegative || diff.inSeconds < 45) return l10n.serverJustNow;
  if (diff.inMinutes < 60) return l10n.serverMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.serverHoursAgo(diff.inHours);
  if (diff.inDays < 7) return l10n.serverDaysAgo(diff.inDays);
  return '${at.year}/${at.month.toString().padLeft(2, '0')}/'
      '${at.day.toString().padLeft(2, '0')}';
}
