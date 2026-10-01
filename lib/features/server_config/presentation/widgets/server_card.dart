import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme.dart';
import '../../domain/entities/server_config.dart';

/// A single row in the fleet list — dense, terminal-flavoured, tappable.
///
/// Visual grammar: a phosphor accent rule on the leading edge, a monogram
/// "sigil", the `user@host:port` identity in monospace, an auth badge, an
/// optional group tag, and a last-seen timestamp. Tap connects, long-press
/// (or the ⋮ button) opens the action sheet.
class ServerCard extends StatelessWidget {
  const ServerCard({
    super.key,
    required this.config,
    required this.onConnect,
    required this.onEdit,
    required this.onDelete,
    this.connected = false,
  });

  final ServerConfig config;
  final VoidCallback onConnect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Live-session hint. Drives the mint accent + status dot. Defaults to
  /// false; the terminal feature flips it while a socket is open.
  final bool connected;

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
            content: Text('copied · ${config.address}'),
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
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) => _ActionSheet(
        config: config,
        onAction: (_CardAction action) {
          Navigator.of(sheetContext).pop();
          _run(context, action);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = connected ? AppTheme.mint : AppTheme.phosphor;

    return Material(
      color: AppTheme.inkSurface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onConnect,
        onLongPress: () => _openSheet(context),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: connected ? accent.withValues(alpha: 0.4) : AppTheme.inkBorderSoft,
            ),
          ),
          child: Stack(
            children: <Widget>[
              // Leading accent rule.
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        accent.withValues(alpha: 0.9),
                        accent.withValues(alpha: 0.25),
                      ],
                    ),
                  ),
                ),
              ),
              // Faint corner bloom for depth.
              Positioned(
                right: -30,
                top: -30,
                child: _IgnorePointerGlow(color: accent),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 12, 6, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    _Sigil(label: _monogram(config), connected: connected),
                    const SizedBox(width: 12),
                    Expanded(child: _CardBody(config: config, connected: connected)),
                    _OverflowMenu(onSelected: (_CardAction a) => _run(context, a)),
                  ],
                ),
              ),
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
  const _CardBody({required this.config, required this.connected});

  final ServerConfig config;
  final bool connected;

  @override
  Widget build(BuildContext context) {
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
                style: context.text.titleLarge?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _AuthBadge(authType: config.authType),
          ],
        ),
        const SizedBox(height: 5),
        // user@host:port — the terminal identity line.
        Text.rich(
          TextSpan(
            children: <InlineSpan>[
              TextSpan(
                text: '${config.username}@${config.host}',
                style: _mono(13, AppTheme.phosphorGlow, FontWeight.w500),
              ),
              TextSpan(
                text: ':${config.port}',
                style: _mono(13, AppTheme.textTertiary, FontWeight.w500),
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 9),
        Row(
          children: <Widget>[
            _StatusDot(connected: connected),
            const SizedBox(width: 6),
            Text(
              connected ? 'online' : _relativeTime(config.lastConnectedAt),
              style: _mono(10, AppTheme.textTertiary, FontWeight.w500, ls: 0.5),
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

  static TextStyle _mono(
    double size,
    Color color,
    FontWeight weight, {
    double ls = 0.2,
  }) =>
      TextStyle(
        fontFamily: AppTheme.monoFont,
        fontFamilyFallback: const <String>[
          'JetBrains Mono',
          'Menlo',
          'Consolas',
          'monospace',
        ],
        fontSize: size,
        fontWeight: weight,
        letterSpacing: ls,
        color: color,
        height: 1.35,
      );
}

/// Leading monogram tile with a phosphor glow.
class _Sigil extends StatelessWidget {
  const _Sigil({required this.label, required this.connected});

  final String label;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    final Color tint = connected ? AppTheme.mint : AppTheme.phosphor;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF0E1322),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: tint.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.monoFont,
          fontFamilyFallback: const <String>[
            'JetBrains Mono',
            'Menlo',
            'monospace',
          ],
          fontSize: 17,
          fontWeight: FontWeight.w700,
          height: 1,
          color: tint,
          shadows: <Shadow>[
            Shadow(color: tint.withValues(alpha: 0.55), blurRadius: 8),
          ],
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
    final IconData icon = authType == AuthType.password
        ? Icons.lock_rounded
        : Icons.vpn_key_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.inkElevated,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppTheme.inkBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 10, color: AppTheme.phosphor),
          const SizedBox(width: 4),
          Text(
            authType.token.toUpperCase(),
            style: TextStyle(
              fontFamily: AppTheme.monoFont,
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppTheme.textSecondary,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: AppTheme.phosphor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.phosphor.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '#',
            style: TextStyle(
              fontFamily: AppTheme.monoFont,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.phosphorDim,
            ),
          ),
          const SizedBox(width: 1),
          Flexible(
            child: Text(
              group,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTheme.monoFont,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: AppTheme.phosphor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    final Color color = connected ? AppTheme.mint : AppTheme.textDisabled;
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withValues(alpha: connected ? 0.7 : 0.0),
            blurRadius: connected ? 6 : 0,
          ),
        ],
      ),
    );
  }
}

class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu({required this.onSelected});

  final ValueChanged<_CardAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_CardAction>(
      onSelected: onSelected,
      tooltip: 'Server actions',
      position: PopupMenuPosition.under,
      icon: const Icon(Icons.more_vert_rounded,
          size: 18, color: AppTheme.textTertiary),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<_CardAction>>[
        _menuEntry(_CardAction.connect, Icons.terminal_rounded, 'Connect'),
        _menuEntry(_CardAction.edit, Icons.edit_rounded, 'Edit'),
        _menuEntry(_CardAction.copy, Icons.copy_all_rounded, 'Copy SSH command'),
        const PopupMenuDivider(height: 8),
        _menuEntry(
          _CardAction.delete,
          Icons.delete_outline_rounded,
          'Delete',
          danger: true,
        ),
      ],
    );
  }
}

PopupMenuItem<_CardAction> _menuEntry(
  _CardAction action,
  IconData icon,
  String label, {
  bool danger = false,
}) {
  final Color tint = danger ? AppTheme.coral : AppTheme.textPrimary;
  return PopupMenuItem<_CardAction>(
    value: action,
    height: 42,
    child: Row(
      children: <Widget>[
        Icon(
          icon,
          size: 16,
          color: danger ? AppTheme.coral : AppTheme.textSecondary,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: tint,
          ),
        ),
      ],
    ),
  );
}

class _IgnorePointerGlow extends StatelessWidget {
  const _IgnorePointerGlow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Action sheet (long-press) ────────────────────────────────────────────

enum _CardAction { connect, edit, copy, delete }

class _ActionSheet extends StatelessWidget {
  const _ActionSheet({required this.config, required this.onAction});

  final ServerConfig config;
  final ValueChanged<_CardAction> onAction;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: AppTheme.inkSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.inkBorder),
        ),
        clipBehavior: Clip.antiAlias,
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
                  color: AppTheme.inkBorder,
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
                    '${config.identity}:${config.port}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.monoFont,
                      fontSize: 11.5,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.inkBorderSoft),
            _SheetTile(
              icon: Icons.terminal_rounded,
              label: 'Connect',
              color: AppTheme.phosphor,
              onTap: () => onAction(_CardAction.connect),
            ),
            _SheetTile(
              icon: Icons.edit_rounded,
              label: 'Edit details',
              onTap: () => onAction(_CardAction.edit),
            ),
            _SheetTile(
              icon: Icons.copy_all_rounded,
              label: 'Copy SSH command',
              onTap: () => onAction(_CardAction.copy),
            ),
            const Divider(height: 1, color: AppTheme.inkBorderSoft),
            _SheetTile(
              icon: Icons.delete_outline_rounded,
              label: 'Delete server',
              color: AppTheme.coral,
              onTap: () => onAction(_CardAction.delete),
            ),
            const SizedBox(height: 6),
          ],
        ),
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
    final Color tint = color ?? AppTheme.textPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 18, color: tint),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: context.text.bodyLarge?.copyWith(
                    fontSize: 14.5,
                    color: tint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────

/// Coarse "time since" formatter for the card's last-seen line.
String _relativeTime(DateTime? at) {
  if (at == null) return 'never connected';
  final Duration diff = DateTime.now().difference(at);
  if (diff.isNegative || diff.inSeconds < 45) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${at.year}/${at.month.toString().padLeft(2, '0')}/'
      '${at.day.toString().padLeft(2, '0')}';
}
