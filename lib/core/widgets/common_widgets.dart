import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../utils/result.dart';

// ─── Loading ──────────────────────────────────────────────────────────────

/// Horizontal phosphor scanline — a slim bar with a bright cyan segment
/// sweeping across it, evoking a CRT refresh rather than a Material spinner.
///
/// Use as a drop-in replacement for [LinearProgressIndicator] when the
/// indeterminate state should feel "alive" instead of generic.
class PhosphorLoader extends StatefulWidget {
  const PhosphorLoader({
    super.key,
    this.height = 2,
    this.label,
    this.compact = false,
  });

  /// Track height in logical pixels.
  final double height;

  /// Optional monospace caption rendered beneath the bar.
  final String? label;

  /// When true, the label sits inline to the right instead of below.
  final bool compact;

  @override
  State<PhosphorLoader> createState() => _PhosphorLoaderState();
}

class _PhosphorLoaderState extends State<PhosphorLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget bar = AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(
        size: Size.infinite,
        painter: _ScanlinePainter(progress: _c.value, height: widget.height),
      ),
    );

    final Widget sized = SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.height / 2),
        child: bar,
      ),
    );

    if (widget.label == null) return sized;

    final TextStyle labelStyle = TextStyle(
      fontFamily: AppTheme.monoFont,
      fontFamilyFallback: const <String>['JetBrains Mono', 'Menlo', 'monospace'],
      fontSize: 10,
      letterSpacing: 1.2,
      color: AppTheme.textTertiary,
    );

    if (widget.compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(width: 60, child: sized),
          const SizedBox(width: 10),
          Text(widget.label!.toUpperCase(), style: labelStyle),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        sized,
        const SizedBox(height: 8),
        Text(widget.label!.toUpperCase(), style: labelStyle),
      ],
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  _ScanlinePainter({required this.progress, required this.height});
  final double progress;
  final double height;

  @override
  void paint(Canvas canvas, Size size) {
    // Base track.
    final Paint track = Paint()
      ..color = AppTheme.inkElevated
      ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, track);

    // Sweeping bright segment (~28% of the track).
    final double span = size.width * 0.28;
    // Eased: fast in the middle, slow at edges — feels like a real scan.
    final double t = _easeInOutSine(progress);
    final double left = (size.width + span) * t - span;

    final Paint head = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          AppTheme.phosphor.withValues(alpha: 0.0),
          AppTheme.phosphor,
          AppTheme.phosphorGlow,
          AppTheme.phosphor.withValues(alpha: 0.0),
        ],
        stops: const <double>[0.0, 0.35, 0.55, 1.0],
      ).createShader(Rect.fromLTWH(left, 0, span, size.height));
    canvas.drawRect(Rect.fromLTWH(left, 0, span, size.height), head);
  }

  static double _easeInOutSine(double t) =>
      -(math.cos(math.pi * t) - 1) / 2;

  @override
  bool shouldRepaint(_ScanlinePainter old) =>
      old.progress != progress || old.height != height;
}

/// Small circular loader with a phosphor glow — for buttons and inline use.
class PhosphorSpinner extends StatelessWidget {
  const PhosphorSpinner({super.key, this.size = 18, this.strokeWidth = 1.6});

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
        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.phosphor),
        backgroundColor: AppTheme.inkElevated,
      ),
    );
  }
}

// ─── Error surface ────────────────────────────────────────────────────────

/// Displays an [AppFailure] in a compact, terminal-flavoured banner.
///
/// The left rule is colour-coded by [FailureKind]; the failure code is
/// rendered monospaced like a stderr line.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    super.key,
    required this.failure,
    this.onRetry,
    this.onDismiss,
    this.dense = false,
  });

  final AppFailure failure;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool dense;

  static Color _colorFor(FailureKind kind) => switch (kind) {
        FailureKind.auth => AppTheme.coral,
        FailureKind.permission => AppTheme.coral,
        FailureKind.notFound => AppTheme.amber,
        FailureKind.validation => AppTheme.amber,
        FailureKind.timeout => AppTheme.amber,
        FailureKind.cancelled => AppTheme.textSecondary,
        FailureKind.network => AppTheme.phosphor,
        FailureKind.ssh => AppTheme.phosphor,
        FailureKind.aiProvider => AppTheme.phosphorGlow,
        FailureKind.storage => AppTheme.amber,
        FailureKind.unexpected => AppTheme.coral,
      };

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
    final Color accent = _colorFor(failure.kind);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.inkSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.inkBorderSoft),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Colour-coded left rule.
            Container(width: 3, color: accent),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: dense ? 12 : 14,
                  vertical: dense ? 10 : 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(_iconFor(failure.kind), size: 14, color: accent),
                        const SizedBox(width: 8),
                        Text(
                          failure.kind.name.toUpperCase(),
                          style: TextStyle(
                            fontFamily: AppTheme.monoFont,
                            fontFamilyFallback: const <String>[
                              'JetBrains Mono',
                              'Menlo',
                              'monospace',
                            ],
                            fontSize: 10,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w600,
                            color: accent,
                          ),
                        ),
                        if (failure.code != null) ...<Widget>[
                          const SizedBox(width: 8),
                          Text(
                            '· ${failure.code}',
                            style: TextStyle(
                              fontFamily: AppTheme.monoFont,
                              fontSize: 10,
                              letterSpacing: 0.6,
                              color: AppTheme.textTertiary,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (onDismiss != null)
                          IconButton(
                            iconSize: 14,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 22,
                              minHeight: 22,
                            ),
                            visualDensity: VisualDensity.compact,
                            onPressed: onDismiss,
                            icon: const Icon(Icons.close_rounded,
                                color: AppTheme.textTertiary),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      failure.message,
                      style: context.text.bodyMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        height: 1.45,
                      ),
                    ),
                    if (onRetry != null) ...<Widget>[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh_rounded, size: 14),
                          label: const Text('Retry'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: accent,
                            side: BorderSide(color: accent.withValues(alpha: 0.5)),
                            minimumSize: const Size(0, 32),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            textStyle: context.text.labelMedium,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Convenience wrapper: if [failure] is non-null, show [ErrorBanner];
/// otherwise render [child].
class ErrorOr extends StatelessWidget {
  const ErrorOr({super.key, required this.failure, required this.child, this.onRetry});
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

/// Terminal-flavoured empty state — an ASCII-ish panel with a `~/` prompt
/// instead of the usual Material "inbox" icon.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.title = 'no rows returned',
    this.message,
    this.prompt,
    this.icon = Icons.terminal_rounded,
    this.action,
    this.compact = false,
  });

  /// Monospaced headline (lowercase, no punctuation — reads like a
  /// shell error message).
  final String title;

  /// Sans-serif supporting copy.
  final String? message;

  /// Optional `$`-prefixed command hint shown in the terminal window.
  final String? prompt;

  final IconData icon;

  /// Optional CTA rendered beneath the copy.
  final Widget? action;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets pad = EdgeInsets.symmetric(
      horizontal: compact ? 16 : 32,
      vertical: compact ? 24 : 48,
    );

    return Center(
      child: Padding(
        padding: pad,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _TerminalGlyph(icon: icon, compact: compact),
              SizedBox(height: compact ? 14 : 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.monoFont,
                  fontFamilyFallback: const <String>[
                    'JetBrains Mono',
                    'Menlo',
                    'monospace',
                  ],
                  fontSize: compact ? 12 : 14,
                  letterSpacing: 0.4,
                  color: AppTheme.textSecondary,
                ),
              ),
              if (message != null) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: context.text.bodySmall?.copyWith(
                    color: AppTheme.textTertiary,
                    height: 1.55,
                  ),
                ),
              ],
              if (prompt != null) ...<Widget>[
                SizedBox(height: compact ? 14 : 18),
                _PromptHint(text: prompt!),
              ],
              if (action != null) ...<Widget>[
                SizedBox(height: compact ? 16 : 22),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TerminalGlyph extends StatelessWidget {
  const _TerminalGlyph({required this.icon, required this.compact});
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double size = compact ? 40 : 56;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.inkSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.inkBorder),
      ),
      child: Center(
        child: Icon(icon, size: size * 0.44, color: AppTheme.phosphorDim),
      ),
    );
  }
}

class _PromptHint extends StatelessWidget {
  const _PromptHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1120),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.inkBorderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            '\$',
            style: TextStyle(
              fontFamily: AppTheme.monoFont,
              fontSize: 11.5,
              color: AppTheme.phosphor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: AppTheme.monoFont,
                fontFamilyFallback: <String>[
                  'JetBrains Mono',
                  'Menlo',
                  'monospace',
                ],
                fontSize: 11.5,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section headers ──────────────────────────────────────────────────────

/// Small-caps monospace section header with an optional trailing widget.
///
/// Used to break up long lists (server groups, chat threads, settings
/// sections) with a terminal-ish "chapter" marker instead of Material's
/// default `ListTile` header look.
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
              style: TextStyle(
                fontFamily: AppTheme.monoFont,
                fontFamilyFallback: const <String>[
                  'JetBrains Mono',
                  'Menlo',
                  'monospace',
                ],
                fontSize: 10.5,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w600,
                color: AppTheme.textTertiary,
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

/// Compact status pill with a pulsing dot — used for server connectivity,
/// streaming state, etc.
class StatusPill extends StatefulWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.pulse = false,
    this.size = StatusPillSize.regular,
  });

  final String label;
  final Color color;

  /// When true, the leading dot animates with a soft bloom.
  final bool pulse;

  final StatusPillSize size;

  @override
  State<StatusPill> createState() => _StatusPillState();
}

enum StatusPillSize { small, regular }

class _StatusPillState extends State<StatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant StatusPill old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.pulse && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool small = widget.size == StatusPillSize.small;
    final double dotSize = small ? 5 : 6;
    final double fontSize = small ? 9.5 : 10.5;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 7 : 9,
        vertical: small ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: widget.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final double t = widget.pulse ? _c.value : 1.0;
              return Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.35 + 0.4 * t),
                      blurRadius: 4 + 4 * t,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(width: small ? 5 : 7),
          Text(
            widget.label,
            style: TextStyle(
              fontFamily: AppTheme.monoFont,
              fontFamilyFallback: const <String>[
                'JetBrains Mono',
                'Menlo',
                'monospace',
              ],
              fontSize: fontSize,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
              color: widget.color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Async value helper ───────────────────────────────────────────────────

/// Renders `loading` / `error` / `data` for a nullable trio — a lightweight
/// alternative to Riverpod's AsyncValue when working with plain futures.
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
    if (isLoading) {
      return loadingWidget ??
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: PhosphorLoader(label: 'loading', compact: true),
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
          const EmptyState(
            title: 'no data',
            message: 'Nothing to show here yet.',
          );
    }
    return builder(d);
  }
}

// ─── Timer helper (re-exported for widgets that need one) ─────────────────

/// Small utility used by feature widgets to schedule post-frame work
/// without pulling in `dart:async` explicitly at every call site.
void postFrame(VoidCallback cb) {
  Timer.run(cb);
}
