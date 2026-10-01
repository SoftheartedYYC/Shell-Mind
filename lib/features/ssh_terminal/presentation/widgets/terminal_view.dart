import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

/// Terminal background — always dark regardless of app theme.
const Color _kTerminalBg = Color(0xFF1A1B26);

/// A clean dark palette for the xterm renderer.
///
/// The 16 ANSI slots use a modern, readable palette (Tokyo Night inspired)
/// that works well on dark backgrounds.
const TerminalTheme kTerminalTheme = TerminalTheme(
  cursor: Color(0xFF7AA2F7),
  selection: Color(0x3A7AA2F7),
  foreground: Color(0xFFC0CAF5),
  background: _kTerminalBg,
  black: Color(0xFF15161E),
  red: Color(0xFFF7768E),
  green: Color(0xFF9ECE6A),
  yellow: Color(0xFFE0AF68),
  blue: Color(0xFF7AA2F7),
  magenta: Color(0xFFBB9AF7),
  cyan: Color(0xFF7DCFFF),
  white: Color(0xFFA9B1D6),
  brightBlack: Color(0xFF414868),
  brightRed: Color(0xFFF7768E),
  brightGreen: Color(0xFF9ECE6A),
  brightYellow: Color(0xFFE0AF68),
  brightBlue: Color(0xFF7AA2F7),
  brightMagenta: Color(0xFFBB9AF7),
  brightCyan: Color(0xFF7DCFFF),
  brightWhite: Color(0xFFC0CAF5),
  searchHitBackground: Color(0x55E0AF68),
  searchHitBackgroundCurrent: Color(0x99E0AF68),
  searchHitForeground: Color(0xFF1A1B26),
);

/// Monospace stack used for terminal glyphs.
const List<String> _kMonoFallback = <String>[
  'RobotoMono',
  'JetBrains Mono',
  'Fira Code',
  'Menlo',
  'Consolas',
  'Liberation Mono',
  'monospace',
];

/// The live shell viewport: a styled [TerminalView] with a clean dark background.
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
    return ColoredBox(
      color: _kTerminalBg,
      child: TerminalView(
        terminal,
        controller: controller,
        focusNode: focusNode,
        theme: kTerminalTheme,
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
    );
  }
}
