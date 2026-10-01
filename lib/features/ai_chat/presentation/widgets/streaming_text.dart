import 'package:flutter/material.dart';

import 'markdown_view.dart';

/// Renders assistant text as it streams in, with a blinking cursor at
/// the tail while [isStreaming] is true.
///
/// The "typewriter" feel comes for free from the token stream growing the
/// [text]; this widget layers the caret on top so the live edge reads as
/// *active* rather than static.
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

/// A simple blinking block cursor shown while the model is still emitting.
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
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _c,
      builder: (BuildContext context, Widget? child) {
        final double opacity = 0.2 + 0.8 * _c.value;
        return Opacity(opacity: opacity, child: child);
      },
      child: Container(
        width: 8 * widget.scale,
        height: 16 * widget.scale,
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
