import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/app_localizations.dart';
import '../utils/result.dart';

// ─── Loading ──────────────────────────────────────────────────────────────

/// Simple linear progress indicator with optional label.
class AppLoader extends StatelessWidget {
  const AppLoader({
    super.key,
    this.height = 4,
    this.label,
    this.compact = false,
  });

  final double height;
  final String? label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    final Widget bar = ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: LinearProgressIndicator(
          color: colors.primary,
          backgroundColor: colors.surfaceContainerHighest,
        ),
      ),
    );

    if (label == null) return bar;

    final TextStyle labelStyle = Theme.of(context).textTheme.bodySmall!.copyWith(
          color: colors.onSurfaceVariant,
        );

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(width: 80, child: bar),
          const SizedBox(width: 12),
          Text(label!, style: labelStyle),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        bar,
        const SizedBox(height: 8),
        Text(label!, style: labelStyle),
      ],
    );
  }
}

/// Small circular progress indicator for inline use.
class AppSpinner extends StatelessWidget {
  const AppSpinner({super.key, this.size = 20, this.strokeWidth = 2.0});

  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        strokeCap: StrokeCap.round,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

// ─── Legacy aliases (for gradual migration) ───────────────────────────────

/// @deprecated Use [AppLoader] instead.
class PhosphorLoader extends StatelessWidget {
  const PhosphorLoader({
    super.key,
    this.height = 4,
    this.label,
    this.compact = false,
  });

  final double height;
  final String? label;
  final bool compact;

  @override
  Widget build(BuildContext context) =>
      AppLoader(height: height, label: label, compact: compact);
}

/// @deprecated Use [AppSpinner] instead.
class PhosphorSpinner extends StatelessWidget {
  const PhosphorSpinner({super.key, this.size = 20, this.strokeWidth = 2.0});

  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) =>
      AppSpinner(size: size, strokeWidth: strokeWidth);
}

// ─── Error surface ────────────────────────────────────────────────────────

/// Displays an [AppFailure] in a clean Material card.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    super.key,
    required this.failure,
    this.onRetry,
    this.onDismiss,
    this.dense = false,
    this.title,
    this.message,
    this.showCode = true,
  });

  final AppFailure failure;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool dense;

  /// Whether to render the numeric [AppFailure.code] chip (e.g. an HTTP
  /// status). User-facing update surfaces turn this off so no raw protocol
  /// code is shown.
  final bool showCode;

  /// Optional localised heading. When null, falls back to the raw
  /// [FailureKind] token — callers that show this banner to end users should
  /// pass a translated title so the internal enum name never leaks.
  final String? title;

  /// Optional localised body. When null, falls back to [AppFailure.message]
  /// (which is an English, developer-facing string). User-facing surfaces
  /// should supply a translated message.
  final String? message;

  static Color _colorFor(BuildContext context, FailureKind kind) {
    final sem = context.sem;
    return switch (kind) {
      FailureKind.auth => sem.danger,
      FailureKind.permission => sem.danger,
      FailureKind.notFound => sem.warning,
      FailureKind.validation => sem.warning,
      FailureKind.timeout => sem.warning,
      FailureKind.cancelled => Theme.of(context).colorScheme.onSurfaceVariant,
      FailureKind.network => sem.info,
      FailureKind.ssh => sem.info,
      FailureKind.aiProvider => sem.info,
      FailureKind.storage => sem.warning,
      FailureKind.unexpected => sem.danger,
    };
  }

  static IconData _iconFor(FailureKind kind) => switch (kind) {
        FailureKind.auth => Icons.lock_outline_rounded,
        FailureKind.permission => Icons.gpp_maybe_outlined,
        FailureKind.notFound => Icons.search_off_rounded,
        FailureKind.validation => Icons.rule_rounded,
        FailureKind.timeout => Icons.hourglass_top_rounded,
        FailureKind.cancelled => Icons.cancel_outlined,
        FailureKind.network => Icons.wifi_off_rounded,
        FailureKind.ssh => Icons.lan_outlined,
        FailureKind.aiProvider => Icons.bolt_outlined,
        FailureKind.storage => Icons.sd_card_alert_outlined,
        FailureKind.unexpected => Icons.error_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color accent = _colorFor(context, failure.kind);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: isDark
            ? null
            : <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 12 : 16,
          vertical: dense ? 12 : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(_iconFor(failure.kind), size: 18, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title ?? failure.kind.name.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                  ),
                ),
                if (showCode && failure.code != null)
                  Text(
                    '${failure.code}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: AppTheme.monoFont,
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                if (onDismiss != null)
                  IconButton(
                    iconSize: 16,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 28),
                    visualDensity: VisualDensity.compact,
                    onPressed: onDismiss,
                    icon: Icon(Icons.close_rounded,
                        color: colors.onSurfaceVariant),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message ?? failure.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                    height: 1.45,
                  ),
            ),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(AppLocalizations.of(context).commonRetry),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accent,
                    side: BorderSide(color: accent.withValues(alpha: 0.5)),
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Convenience wrapper: if [failure] is non-null, show [ErrorBanner];
/// otherwise render [child].
class ErrorOr extends StatelessWidget {
  const ErrorOr(
      {super.key, required this.failure, required this.child, this.onRetry});
  final AppFailure? failure;
  final Widget child;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final AppFailure? f = failure;
    if (f == null) return child;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ErrorBanner(failure: f, onRetry: onRetry),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────

/// Clean, minimal empty state with icon, title, message and optional action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.title,
    this.message,
    this.prompt,
    this.icon = Icons.inbox_rounded,
    this.action,
    this.compact = false,
  });

  final String? title;
  final String? message;

  /// Kept for API compat — rendered as a subtle hint below the message.
  final String? prompt;

  final IconData icon;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final EdgeInsets pad = EdgeInsets.symmetric(
      horizontal: compact ? 16 : 32,
      vertical: compact ? 24 : 48,
    );

    return Center(
      child: Padding(
        padding: pad,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                width: compact ? 48 : 64,
                height: compact ? 48 : 64,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: compact ? 24 : 32,
                  color: colors.primary,
                ),
              ),
              SizedBox(height: compact ? 12 : 16),
              Text(
                title ?? l10n.commonNoData,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (message != null) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.5,
                      ),
                ),
              ],
              if (prompt != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  prompt!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontFamily: AppTheme.monoFont,
                        fontFamilyFallback: AppTheme.monoFallback,
                        fontSize: 12,
                      ),
                ),
              ],
              if (action != null) ...<Widget>[
                SizedBox(height: compact ? 16 : 24),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section headers ──────────────────────────────────────────────────────

/// Clean section header with optional trailing widget.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.label,
    this.trailing,
    this.leading,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 8),
  });

  final String label;
  final Widget? trailing;
  final Widget? leading;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: Row(
        children: <Widget>[
          if (leading != null) ...<Widget>[
            leading!,
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─── Status pill ──────────────────────────────────────────────────────────

/// Compact status pill with a coloured dot.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.pulse = false,
    this.size = StatusPillSize.regular,
  });

  final String label;
  final Color color;
  final bool pulse;
  final StatusPillSize size;

  @override
  Widget build(BuildContext context) {
    final bool small = size == StatusPillSize.small;
    final double dotSize = small ? 6 : 8;
    final double fontSize = small ? 10 : 11;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: small ? 5 : 7),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

enum StatusPillSize { small, regular }

// ─── Async value helper ───────────────────────────────────────────────────

/// Renders loading / error / data states for a nullable trio.
class LoadingErrorData<T> extends StatelessWidget {
  const LoadingErrorData({
    super.key,
    required this.isLoading,
    required this.data,
    required this.failure,
    required this.builder,
    this.onRetry,
    this.loadingWidget,
    this.errorWidget,
  });

  final bool isLoading;
  final T? data;
  final AppFailure? failure;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (isLoading) {
      return loadingWidget ??
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AppLoader(label: l10n.commonLoading, compact: true),
            ),
          );
    }
    final AppFailure? f = failure;
    if (f != null) {
      return errorWidget ??
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ErrorBanner(failure: f, onRetry: onRetry),
            ),
          );
    }
    final T? d = data;
    if (d == null) {
      return errorWidget ??
          EmptyState(
            title: l10n.commonNoData,
            message: l10n.commonNothingToShow,
          );
    }
    return builder(d);
  }
}

// ─── Timer helper ─────────────────────────────────────────────────────────

/// Small utility for scheduling post-frame work.
void postFrame(VoidCallback cb) {
  Timer.run(cb);
}
