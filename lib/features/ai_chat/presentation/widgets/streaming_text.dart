import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import 'markdown_view.dart';

/// Renders assistant text as it streams in, with a blinking block cursor at
/// the tail while [isStreaming] is true.
///
/// The "typewriter" feel comes for free from the token stream growing the
/// [text]; this widget layers the caret and a subtle fade-in on top so the
/// live edge reads as *active* rather than static.
class StreamingText extends StatelessWidget {
  const StreamingText({
    super.key,
    required this.text,
    required this.isStreaming,
    this.selectable = true,
    this.textScale = 1.0,
  });

  final String text;
  final bool isStreaming;
  final bool selectable;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    final bool hasContent = text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (hasContent)
          MarkdownView(
            text: text,
            selectable: selectable && !isStreaming,
            textScale: textScale,
          ),
        if (isStreaming) ...<Widget>[
          if (hasContent) const SizedBox(height: 4),
          _BlinkingCursor(scale: textScale),
        ],
      ],
    );
  }
}

/// The phosphor "▊" caret that pulses while the model is still emitting.
class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor({this.scale = 1.0});

  final double scale;

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, Widget? child) {
        // Hold near-full opacity, dip quickly — reads as a hard terminal blink.
        final double t = Curves.easeInOut.transform(_c.value);
        final double opacity = 0.25 + 0.75 * t;
        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '▊',
            style: TextStyle(
              fontFamily: AppTheme.monoFont,
              fontFamilyFallback: const <String>[
                'JetBrains Mono',
                'Menlo',
                'monospace',
              ],
              fontSize: 14 * widget.scale,
              height: 1.2,
              color: AppTheme.phosphorGlow,
              shadows: <Shadow>[
                Shadow(
                  color: AppTheme.phosphorGlow.withValues(alpha: 0.6),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
