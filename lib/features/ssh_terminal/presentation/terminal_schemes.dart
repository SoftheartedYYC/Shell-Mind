import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

/// A named terminal colour preset (16-colour ANSI palette + foreground /
/// background / cursor / selection) selectable from Settings.
///
/// The xterm renderer keeps a fixed dark aesthetic independent of the app
/// theme, but users asked for choice — so the palette is now swappable. The
/// list is a fixed catalogue (no user-defined palettes) to keep the surface
/// simple; each entry has a stable [id] persisted in preferences.
@immutable
class TerminalColorScheme {
  const TerminalColorScheme({
    required this.id,
    required this.name,
    required this.theme,
  });

  /// Stable identifier persisted in [PreferencesService].
  final String id;

  /// Human-facing label (theme names are proper nouns, kept untranslated).
  final String name;

  /// The resolved xterm palette, including the terminal background.
  final TerminalTheme theme;

  /// Background colour of the terminal viewport (mirrors [theme].background).
  Color get background => theme.background;

  static const String defaultId = 'tokyo-night';

  /// All built-in schemes, in picker order.
  static final List<TerminalColorScheme> all = <TerminalColorScheme>[
    tokyoNight,
    oneDark,
    dracula,
    monokai,
    solarizedDark,
    classic,
  ];

  /// Resolves a persisted [id] to a scheme, falling back to [tokyoNight].
  static TerminalColorScheme byId(String? id) {
    for (final TerminalColorScheme scheme in all) {
      if (scheme.id == id) return scheme;
    }
    return tokyoNight;
  }

  static final TerminalColorScheme tokyoNight = TerminalColorScheme(
    id: 'tokyo-night',
    name: 'Tokyo Night',
    theme: _TerminalThemeBuilder(
      background: Color(0xFF1A1B26),
      foreground: Color(0xFFC0CAF5),
      cursor: Color(0xFF7AA2F7),
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
    ).build(),
  );

  static final TerminalColorScheme oneDark = TerminalColorScheme(
    id: 'one-dark',
    name: 'One Dark',
    theme: _TerminalThemeBuilder(
      background: Color(0xFF282C34),
      foreground: Color(0xFFABB2BF),
      cursor: Color(0xFF61AFEF),
      black: Color(0xFF282C34),
      red: Color(0xFFE06C75),
      green: Color(0xFF98C379),
      yellow: Color(0xFFE5C07B),
      blue: Color(0xFF61AFEF),
      magenta: Color(0xFFC678DD),
      cyan: Color(0xFF56B6C2),
      white: Color(0xFFABB2BF),
      brightBlack: Color(0xFF5C6370),
      brightRed: Color(0xFFE06C75),
      brightGreen: Color(0xFF98C379),
      brightYellow: Color(0xFFE5C07B),
      brightBlue: Color(0xFF61AFEF),
      brightMagenta: Color(0xFFC678DD),
      brightCyan: Color(0xFF56B6C2),
      brightWhite: Color(0xFFFFFFFF),
    ).build(),
  );

  static final TerminalColorScheme dracula = TerminalColorScheme(
    id: 'dracula',
    name: 'Dracula',
    theme: _TerminalThemeBuilder(
      background: Color(0xFF282A36),
      foreground: Color(0xFFF8F8F2),
      cursor: Color(0xFFBD93F9),
      black: Color(0xFF21222C),
      red: Color(0xFFFF5555),
      green: Color(0xFF50FA7B),
      yellow: Color(0xFFF1FA8C),
      blue: Color(0xFFBD93F9),
      magenta: Color(0xFFFF79C6),
      cyan: Color(0xFF8BE9FD),
      white: Color(0xFFF8F8F2),
      brightBlack: Color(0xFF6272A4),
      brightRed: Color(0xFFFF6E6E),
      brightGreen: Color(0xFF69FF94),
      brightYellow: Color(0xFFFFFFA5),
      brightBlue: Color(0xFFD6ACFF),
      brightMagenta: Color(0xFFFF92DF),
      brightCyan: Color(0xFFA4FFFF),
      brightWhite: Color(0xFFFFFFFF),
    ).build(),
  );

  static final TerminalColorScheme monokai = TerminalColorScheme(
    id: 'monokai',
    name: 'Monokai',
    theme: _TerminalThemeBuilder(
      background: Color(0xFF272822),
      foreground: Color(0xFFF8F8F2),
      cursor: Color(0xFF66D9EF),
      black: Color(0xFF272822),
      red: Color(0xFFF92672),
      green: Color(0xFFA6E22E),
      yellow: Color(0xFFF4BF75),
      blue: Color(0xFF66D9EF),
      magenta: Color(0xFFAE81FF),
      cyan: Color(0xFFA1EFE4),
      white: Color(0xFFF8F8F2),
      brightBlack: Color(0xFF75715E),
      brightRed: Color(0xFFF92672),
      brightGreen: Color(0xFFA6E22E),
      brightYellow: Color(0xFFF4BF75),
      brightBlue: Color(0xFF66D9EF),
      brightMagenta: Color(0xFFAE81FF),
      brightCyan: Color(0xFFA1EFE4),
      brightWhite: Color(0xFFF9F8F5),
    ).build(),
  );

  static final TerminalColorScheme solarizedDark = TerminalColorScheme(
    id: 'solarized-dark',
    name: 'Solarized Dark',
    theme: _TerminalThemeBuilder(
      background: Color(0xFF002B36),
      foreground: Color(0xFF839496),
      cursor: Color(0xFF93A1A1),
      black: Color(0xFF073642),
      red: Color(0xFFDC322F),
      green: Color(0xFF859900),
      yellow: Color(0xFFB58900),
      blue: Color(0xFF268BD2),
      magenta: Color(0xFFD33682),
      cyan: Color(0xFF2AA198),
      white: Color(0xFFEEE8D5),
      brightBlack: Color(0xFF586E75),
      brightRed: Color(0xFFCB4B16),
      brightGreen: Color(0xFF859900),
      brightYellow: Color(0xFFB58900),
      brightBlue: Color(0xFF268BD2),
      brightMagenta: Color(0xFFD33682),
      brightCyan: Color(0xFF2AA198),
      brightWhite: Color(0xFFFDF6E3),
    ).build(),
  );

  static final TerminalColorScheme classic = TerminalColorScheme(
    id: 'classic',
    name: 'Classic',
    theme: _TerminalThemeBuilder(
      background: Color(0xFF000000),
      foreground: Color(0xFFCCCCCC),
      cursor: Color(0xFFCCCCCC),
      black: Color(0xFF000000),
      red: Color(0xFFCD0000),
      green: Color(0xFF00CD00),
      yellow: Color(0xFFCDCD00),
      blue: Color(0xFF0000EE),
      magenta: Color(0xFFCD00CD),
      cyan: Color(0xFF00CDCD),
      white: Color(0xFFE5E5E5),
      brightBlack: Color(0xFF7F7F7F),
      brightRed: Color(0xFFFF0000),
      brightGreen: Color(0xFF00FF00),
      brightYellow: Color(0xFFFFFF00),
      brightBlue: Color(0xFF5C5CFF),
      brightMagenta: Color(0xFFFF00FF),
      brightCyan: Color(0xFF00FFFF),
      brightWhite: Color(0xFFFFFFFF),
    ).build(),
  );
}

/// Builds a [TerminalTheme] from the 16 ANSI slots plus fg/bg/cursor.
///
/// Selection and search-hit colours are derived from the foreground/background
/// so every palette gets a consistent, readable highlight without hand-tuning.
class _TerminalThemeBuilder {
  const _TerminalThemeBuilder({
    required this.background,
    required this.foreground,
    required this.cursor,
    required this.black,
    required this.red,
    required this.green,
    required this.yellow,
    required this.blue,
    required this.magenta,
    required this.cyan,
    required this.white,
    required this.brightBlack,
    required this.brightRed,
    required this.brightGreen,
    required this.brightYellow,
    required this.brightBlue,
    required this.brightMagenta,
    required this.brightCyan,
    required this.brightWhite,
  });

  final Color background;
  final Color foreground;
  final Color cursor;
  final Color black;
  final Color red;
  final Color green;
  final Color yellow;
  final Color blue;
  final Color magenta;
  final Color cyan;
  final Color white;
  final Color brightBlack;
  final Color brightRed;
  final Color brightGreen;
  final Color brightYellow;
  final Color brightBlue;
  final Color brightMagenta;
  final Color brightCyan;
  final Color brightWhite;

  TerminalTheme build() => TerminalTheme(
        cursor: cursor,
        selection: foreground.withValues(alpha: 0.23),
        foreground: foreground,
        background: background,
        black: black,
        red: red,
        green: green,
        yellow: yellow,
        blue: blue,
        magenta: magenta,
        cyan: cyan,
        white: white,
        brightBlack: brightBlack,
        brightRed: brightRed,
        brightGreen: brightGreen,
        brightYellow: brightYellow,
        brightBlue: brightBlue,
        brightMagenta: brightMagenta,
        brightCyan: brightCyan,
        brightWhite: brightWhite,
        searchHitBackground: const Color(0x55E0AF68),
        searchHitBackgroundCurrent: const Color(0x99E0AF68),
        searchHitForeground: background,
      );
}
