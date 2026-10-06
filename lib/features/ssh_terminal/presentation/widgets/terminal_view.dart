import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

import '../terminal_schemes.dart';

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
    required this.scheme,
    this.fontSize = 14,
    this.readOnly = false,
    this.focusNode,
  });

  final Terminal terminal;
  final TerminalController controller;
  final TerminalColorScheme scheme;
  final double fontSize;
  final bool readOnly;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: scheme.background,
      child: TerminalView(
        terminal,
        controller: controller,
        focusNode: focusNode,
        theme: scheme.theme,
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
