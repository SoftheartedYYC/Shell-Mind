import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../core/services/update_service.dart';
import '../../../../core/utils/result.dart';
import '../../../../l10n/app_localizations.dart';

/// Reusable UI primitives shared by the update panel in Settings
/// and the launch-time update prompt. Clean Material 3 style.

// ─── Progress bar ─────────────────────────────────────────────────────────

/// Standard Material linear progress indicator for download progress.
class BlockProgressBar extends StatelessWidget {
  const BlockProgressBar({
    super.key,
    this.progress,
    this.segments = 28,
    this.height = 8,
    this.accent,
  });

  /// `0.0`–`1.0`, or null for indeterminate.
  final double? progress;
  final int segments;
  final double height;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: LinearProgressIndicator(
          value: progress,
          color: accent ?? colors.primary,
          backgroundColor: colors.surfaceContainerHighest,
        ),
      ),
    );
  }
}

// ─── Action button ────────────────────────────────────────────────────────

/// Clean Material action button used in update flows.
class TerminalActionButton extends StatelessWidget {
  const TerminalActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.glyph,
    this.accent,
    this.filled = false,
    this.busy = false,
    this.expand = true,
    this.height = 40,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? glyph;
  final Color? accent;
  final bool filled;
  final bool busy;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color color = accent ?? colors.primary;
    final bool enabled = onPressed != null && !busy;

    if (filled) {
      return SizedBox(
        height: height,
        width: expand ? double.infinity : null,
        child: FilledButton.icon(
          onPressed: enabled ? onPressed : null,
          icon: busy
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.onPrimary,
                  ),
                )
              : Icon(glyph, size: 16),
          label: Text(label),
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: colors.onPrimary,
            minimumSize: Size(0, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      width: expand ? double.infinity : null,
      child: OutlinedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: busy
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Icon(glyph, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: enabled ? color : colors.outline),
          minimumSize: Size(0, height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

// ─── Panel furniture ──────────────────────────────────────────────────────

/// Coloured icon chip used as the leading marker of a status heading.
class UpdateStatusGlyph extends StatelessWidget {
  const UpdateStatusGlyph({
    super.key,
    required this.icon,
    required this.color,
    this.size = 28,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, size: size * 0.55, color: color),
    );
  }
}

/// Heading row: icon chip + title + optional trailing widget.
class UpdatePanelHeading extends StatelessWidget {
  const UpdatePanelHeading({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.trailing,
    this.children = const <Widget>[],
  });

  final IconData icon;
  final Color color;
  final String title;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            UpdateStatusGlyph(icon: icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        ...children,
      ],
    );
  }
}

/// `v1.0.0 → v1.1.0` version transition display.
class UpdateVersionArrow extends StatelessWidget {
  const UpdateVersionArrow({
    super.key,
    required this.from,
    required this.to,
    this.fontSize = 12,
  });

  final String from;
  final String to;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextStyle base = TextStyle(
      fontFamily: AppTheme.monoFont,
      fontFamilyFallback: AppTheme.monoFallback,
      fontSize: fontSize,
      letterSpacing: 0.3,
      height: 1.3,
    );
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: 'v$from',
            style: base.copyWith(color: colors.onSurfaceVariant),
          ),
          TextSpan(
            text: '  →  ',
            style: base.copyWith(color: colors.primary),
          ),
          TextSpan(
            text: 'v$to',
            style: base.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// One caption/value pair in the download readout.
class UpdateReadout extends StatelessWidget {
  const UpdateReadout({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '$label ',
          style: TextStyle(
            fontFamily: AppTheme.monoFont,
            fontSize: 10,
            letterSpacing: 0.5,
            color: colors.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTheme.monoFont,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
      ],
    );
  }
}

/// A single chip in the metadata strip.
class UpdateMeta {
  const UpdateMeta(this.icon, this.text);
  final IconData icon;
  final String text;
}

/// Row of small chips (file size, publish date, asset name).
class UpdateMetaStrip extends StatelessWidget {
  const UpdateMetaStrip({
    super.key,
    required this.items,
    this.maxTextWidth = 170,
  });

  final List<UpdateMeta> items;
  final double maxTextWidth;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: <Widget>[
        for (final UpdateMeta m in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(m.icon, size: 12, color: colors.onSurfaceVariant),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxTextWidth),
                  child: Text(
                    m.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.monoFont,
                      fontSize: 10,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Tinted one-liner used for warnings.
class UpdateInlineHint extends StatelessWidget {
  const UpdateInlineHint({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Release notes ────────────────────────────────────────────────────────

/// GitHub release body rendered in a clean scrollable panel.
class UpdateNotesPanel extends StatelessWidget {
  const UpdateNotesPanel({
    super.key,
    required this.notes,
    this.tag,
    this.maxHeight = 176,
    this.command,
  });

  final String notes;
  final String? tag;
  final double maxHeight;
  final String? command;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final List<String> lines = notes.split('\n');
    final String header = command ?? l10n.updateReleaseNotes(tag ?? 'notes');

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.outlineVariant),
              ),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    header,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.monoFont,
                      fontSize: 10,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  l10n.updateNotesLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (final String line in lines) _NotesLine(raw: line),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesLine extends StatelessWidget {
  const _NotesLine({required this.raw});

  final String raw;

  static final RegExp _heading = RegExp(r'^#{1,6}\s+(.*)$');
  static final RegExp _bullet = RegExp(r'^\s*[-*+]\s+(.*)$');
  static final RegExp _ordered = RegExp(r'^\s*(\d+)[.)]\s+(.*)$');

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String line = raw.trimRight();
    if (line.trim().isEmpty) return const SizedBox(height: 6);

    final RegExpMatch? heading = _heading.firstMatch(line);
    if (heading != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4, top: 2),
        child: Text(
          heading.group(1)!.trim().toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
            color: colors.primary,
          ),
        ),
      );
    }

    final RegExpMatch? bullet = _bullet.firstMatch(line);
    if (bullet != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '•',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: _body(bullet.group(1)!.trim(), context)),
          ],
        ),
      );
    }

    final RegExpMatch? ordered = _ordered.firstMatch(line);
    if (ordered != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${ordered.group(1)}.',
              style: TextStyle(
                fontFamily: AppTheme.monoFont,
                fontSize: 11,
                height: 1.5,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(child: _body(ordered.group(2)!.trim(), context)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: _body(line.trim(), context),
    );
  }

  Widget _body(String text, BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Text(
      _stripInline(text),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.5,
          ),
    );
  }

  static String _stripInline(String s) => s
      .replaceAllMapped(
        RegExp(r'\[([^\]]+)\]\([^)]*\)'),
        (Match m) => m.group(1)!,
      )
      .replaceAllMapped(
        RegExp(r'(\*\*|__)(.+?)\1'),
        (Match m) => m.group(2)!,
      )
      .replaceAllMapped(RegExp(r'`([^`]*)`'), (Match m) => m.group(1)!)
      .replaceAllMapped(
        RegExp(r'(^|\W)(\*|_)([^*_]+)\2'),
        (Match m) => '${m.group(1)}${m.group(3)}',
      );
}

// ─── Localised error mapping ──────────────────────────────────

/// Maps a transport-level [AppFailure] from the update flow onto a short,
/// user-facing heading. The raw [FailureKind] enum name (e.g. `NOTFOUND`) is
/// never shown — only translated copy.
String updateFailureTitle(BuildContext context, AppFailure failure) {
  final AppLocalizations l10n = AppLocalizations.of(context);
  if (_isNoReleases(failure)) return l10n.updateErrorTitleNoReleases;
  return l10n.updateErrorTitleGeneric;
}

/// Maps a transport-level [AppFailure] from the update flow onto a full,
/// localised explanation. Prefers the machine-readable `reason` marker set by
/// [UpdateService], then falls back to the [FailureKind].
String describeUpdateFailure(BuildContext context, AppFailure failure) {
  final AppLocalizations l10n = AppLocalizations.of(context);
  final Object? reason = failure.details['reason'];

  if (reason == UpdateFailureReason.noReleases) return l10n.updateErrNoReleases;
  if (reason == UpdateFailureReason.rateLimit) return l10n.updateErrRateLimit;

  return switch (failure.kind) {
    FailureKind.notFound => l10n.updateErrNoReleases,
    FailureKind.timeout => l10n.updateErrTimeout,
    FailureKind.network => l10n.updateErrNetwork,
    FailureKind.auth => l10n.updateErrAuth,
    FailureKind.permission => l10n.updateErrPermission,
    FailureKind.storage => l10n.updateErrStorage,
    _ => l10n.updateCheckFailed,
  };
}

bool _isNoReleases(AppFailure failure) =>
    failure.details['reason'] == UpdateFailureReason.noReleases ||
    failure.kind == FailureKind.notFound;
