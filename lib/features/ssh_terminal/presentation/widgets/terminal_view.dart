import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

import '../../../../app/theme.dart';

/// Terminal Noir palette for the xterm renderer.
///
/// The 16 ANSI slots are tuned to sit inside the app's cold-blue phosphor
/// identity rather than xterm's stock bright primaries: `blue`/`cyan` reuse the
/// signature phosphor hues, `red`/`green`/`yellow` map to the coral/mint/amber
/// semantic accents, and the background is the near-black [AppTheme.inkVoid].
const TerminalTheme kTerminalNoirTheme = TerminalTheme(
  cursor: AppTheme.phosphor,
  selection: Color(0x3A4FC3F7),
  foreground: AppTheme.textPrimary,
  background: AppTheme.inkVoid,
  black: Color(0xFF2A3350),
  red: Color(0xFFFF6B6B),
  green: Color(0xFF4ADE80),
  yellow: Color(0xFFFFB454),
  blue: Color(0xFF4FC3F7),
  magenta: Color(0xFFC792EA),
  cyan: Color(0xFF7DF9FF),
  white: Color(0xFFDDE5F2),
  brightBlack: Color(0xFF5F6B82),
  brightRed: Color(0xFFFF9A9A),
  brightGreen: Color(0xFF86EFAC),
  brightYellow: Color(0xFFFFCE8B),
  brightBlue: Color(0xFF8FD8FF),
  brightMagenta: Color(0xFFDDA6F0),
  brightCyan: Color(0xFFA5FBFF),
  brightWhite: Color(0xFFFFFFFF),
  searchHitBackground: Color(0x55FFB454),
  searchHitBackgroundCurrent: Color(0x99FFB454),
  searchHitForeground: Color(0xFF0A0E1A),
);

/// Monospace stack used for terminal glyphs — prefers a bundled mono, then
/// falls back through the usual platform monospaced faces.
const List<String> _kMonoFallback = <String>[
  'RobotoMono',
  'JetBrains Mono',
  'Fira Code',
  'Menlo',
  'Consolas',
  'Liberation Mono',
  'monospace',
];

/// The live shell viewport: a styled [TerminalView] wrapped in a faint CRT
/// scanline/vignette overlay for atmosphere.
///
/// Input/output wiring lives in `terminalProvider`; this widget is purely the
/// visual surface. It enables text selection (via [controller]), on-screen
/// keyboard delete detection, and auto-resize — which drives the PTY
/// window-change through [Terminal.onResize].
class ShellTerminalView extends StatelessWidget {
  const ShellTerminalView({
    super.key,
    required this.terminal,
    required this.controller,
    this.fontSize = 14,
    this.readOnly = false,
    this.focusNode,
  });

  final Terminal terminal;
  final TerminalController controller;
  final double fontSize;
  final bool readOnly;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppTheme.inkVoid),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: TerminalView(
              terminal,
              controller: controller,
              focusNode: focusNode,
              theme: kTerminalNoirTheme,
              textStyle: TerminalStyle(
                fontSize: fontSize,
                height: 1.25,
                fontFamily: 'RobotoMono',
                fontFamilyFallback: _kMonoFallback,
              ),
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
              backgroundOpacity: 1,
              autofocus: true,
              alwaysShowCursor: true,
              deleteDetection: true,
              cursorType: TerminalCursorType.block,
              keyboardType: TextInputType.text,
              keyboardAppearance: Brightness.dark,
              readOnly: readOnly,
              mouseCursor: SystemMouseCursors.text,
              simulateScroll: true,
            ),
          ),
          // CRT scanlines + edge vignette — non-interactive, very subtle so it
          // reads as "phosphor glass" without hurting legibility.
          const Positioned.fill(child: IgnorePointer(child: _CrtOverlay())),
        ],
      ),
    );
  }
}

/// Hairline horizontal scanlines with a soft corner vignette, evoking a CRT
/// bezel. Painted above the terminal but ignores all pointer events.
class _CrtOverlay extends StatelessWidget {
  const _CrtOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CrtPainter());
  }
}

class _CrtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    // Scanlines.
    final Paint lines = Paint()
      ..color = const Color(0x0A000000)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), lines);
    }

    // Vignette darkening toward the edges.
    final Paint vignette = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.9,
        colors: <Color>[
          Colors.transparent,
          AppTheme.inkVoid.withValues(alpha: 0.35),
        ],
        stops: const <double>[0.6, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, vignette);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
