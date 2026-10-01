import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shell-Mind visual identity — "Terminal Noir".
///
/// A CRT-phosphor inspired command-console aesthetic: near-black surfaces
/// tinted with cold blue, an electric cyan signal colour, and a warm amber
/// accent used sparingly for warnings. Sharp corners, hairline borders, and
/// monospaced type carry the terminal metaphor into every screen.
abstract final class AppTheme {
  // ─── Palette ────────────────────────────────────────────────────────────
  /// Deep near-black with a cold blue undertone. Base layer of the app.
  static const Color inkVoid = Color(0xFF0A0E1A);

  /// Slightly raised surface — cards, sheets, list tiles.
  static const Color inkSurface = Color(0xFF111624);

  /// Elevated surface — dialogs, popovers, active tab indicators.
  static const Color inkElevated = Color(0xFF1A2033);

  /// Hairline border, used at 1px to suggest CRT bezels.
  static const Color inkBorder = Color(0xFF232B42);
  static const Color inkBorderSoft = Color(0xFF1B2237);

  /// Primary phosphor signal — the "live" colour of the app.
  static const Color phosphor = Color(0xFF4FC3F7);
  static const Color phosphorDim = Color(0xFF2E7FA8);
  static const Color phosphorGlow = Color(0xFF7DF9FF);

  /// Warm amber for warnings, running processes, high-value highlights.
  static const Color amber = Color(0xFFFFB454);

  /// Mint for successful operations / connected servers.
  static const Color mint = Color(0xFF4ADE80);

  /// Coral for destructive actions / disconnected states.
  static const Color coral = Color(0xFFFF6B6B);

  /// Text hierarchy — cold greys tinted toward the base colour.
  static const Color textPrimary = Color(0xFFE6EDF7);
  static const Color textSecondary = Color(0xFF9BA7BD);
  static const Color textTertiary = Color(0xFF5F6B82);
  static const Color textDisabled = Color(0xFF3A4257);

  // ─── Typography ─────────────────────────────────────────────────────────
  /// Sans-serif family for chrome / UI copy.
  static const String uiFont = 'Inter';

  /// Monospace family for anything that looks like terminal output,
  /// server addresses, ports, hashes, etc.
  static const String monoFont = 'RobotoMono';

  static ThemeData get darkTheme => _build();

  static ThemeData _build() {
    const ColorScheme scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: phosphor,
      onPrimary: inkVoid,
      primaryContainer: Color(0xFF143A52),
      onPrimaryContainer: phosphorGlow,
      secondary: amber,
      onSecondary: inkVoid,
      secondaryContainer: Color(0xFF3A2A12),
      onSecondaryContainer: amber,
      tertiary: phosphorGlow,
      onTertiary: inkVoid,
      error: coral,
      onError: inkVoid,
      errorContainer: Color(0xFF3A1A1E),
      onErrorContainer: coral,
      surface: inkSurface,
      onSurface: textPrimary,
      surfaceContainerLowest: inkVoid,
      surfaceContainerLow: Color(0xFF0E1322),
      surfaceContainer: inkSurface,
      surfaceContainerHigh: inkElevated,
      surfaceContainerHighest: Color(0xFF222A42),
      onSurfaceVariant: textSecondary,
      outline: inkBorder,
      outlineVariant: inkBorderSoft,
      shadow: Colors.black,
      scrim: Color(0xCC050810),
      inverseSurface: Color(0xFFE6EDF7),
      onInverseSurface: inkVoid,
      inversePrimary: Color(0xFF0F5C82),
    );

    final TextTheme text = _buildTextTheme(scheme);

    final ThemeData base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: inkVoid,
      canvasColor: inkVoid,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.compact,
      fontFamily: uiFont,
      fontFamilyFallback: const <String>[
        'SF Pro Text',
        'Segoe UI',
        'Roboto',
        'Helvetica Neue',
        'Arial',
      ],
      textTheme: text,
      primaryTextTheme: text,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: inkVoid,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: textPrimary, size: 22),
      ),
      cardTheme: CardThemeData(
        color: inkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: inkBorderSoft),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: inkBorderSoft,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0E1322),
        hintStyle: text.bodyMedium?.copyWith(color: textTertiary),
        labelStyle: text.bodyMedium?.copyWith(color: textSecondary),
        floatingLabelStyle: text.bodyMedium?.copyWith(color: phosphor),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: _inputBorder(inkBorder),
        enabledBorder: _inputBorder(inkBorder),
        focusedBorder: _inputBorder(phosphor, width: 1.4),
        errorBorder: _inputBorder(coral),
        focusedErrorBorder: _inputBorder(coral, width: 1.4),
        disabledBorder: _inputBorder(inkBorderSoft),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: phosphor,
          foregroundColor: inkVoid,
          disabledBackgroundColor: inkElevated,
          disabledForegroundColor: textDisabled,
          elevation: 0,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: phosphor,
          foregroundColor: inkVoid,
          elevation: 0,
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          minimumSize: const Size(0, 44),
          side: const BorderSide(color: inkBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: phosphor,
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textSecondary,
          highlightColor: phosphor.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: phosphor,
        foregroundColor: inkVoid,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: inkElevated,
        selectedColor: phosphor.withValues(alpha: 0.16),
        disabledColor: inkSurface,
        side: const BorderSide(color: inkBorder),
        labelStyle: text.labelMedium,
        secondaryLabelStyle: text.labelMedium?.copyWith(color: phosphor),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        selectedColor: phosphor,
        selectedTileColor: phosphor.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0C1120),
        surfaceTintColor: Colors.transparent,
        indicatorColor: phosphor.withValues(alpha: 0.14),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final bool selected = states.contains(WidgetState.selected);
          return text.labelSmall?.copyWith(
            color: selected ? phosphor : textTertiary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: 0.6,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? phosphor : textTertiary,
          );
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: phosphor,
        unselectedLabelColor: textTertiary,
        indicatorColor: phosphor,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: inkBorderSoft,
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelMedium,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: inkElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: inkBorder),
        ),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: inkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: inkElevated,
        contentTextStyle: text.bodyMedium?.copyWith(color: textPrimary),
        actionTextColor: phosphor,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: inkBorder),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: inkElevated,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: inkBorder),
        ),
        textStyle: text.bodySmall?.copyWith(color: textPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: phosphor,
        linearTrackColor: inkElevated,
        circularTrackColor: inkElevated,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? inkVoid : textTertiary),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? phosphor : inkElevated),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? phosphor
                : inkBorder),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? phosphor : Colors.transparent),
        checkColor: WidgetStatePropertyAll<Color>(inkVoid),
        side: const BorderSide(color: inkBorder, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? phosphor : textTertiary),
        overlayColor: WidgetStatePropertyAll(phosphor.withValues(alpha: 0.12)),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: phosphor,
        inactiveTrackColor: inkElevated,
        thumbColor: phosphor,
        overlayColor: Color(0x294FC3F7),
        trackHeight: 2,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: inkElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: inkBorder),
        ),
        textStyle: text.bodyMedium,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(inkBorder),
        thickness: const WidgetStatePropertyAll(4),
        radius: const Radius.circular(2),
        crossAxisMargin: 2,
      ),
      extensions: const <ThemeExtension<dynamic>>[
        ShellMindSemanticColors.dark,
      ],
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static TextTheme _buildTextTheme(ColorScheme scheme) {
    // Base sizes follow a slightly tightened scale so dense terminal
    // UIs (server lists, chat transcripts) don't feel airy.
    TextStyle ui(double size, FontWeight weight,
            {double ls = 0, Color? color, double? height}) =>
        TextStyle(
          fontSize: size,
          fontWeight: weight,
          letterSpacing: ls,
          height: height,
          color: color ?? scheme.onSurface,
        );

    TextStyle mono(double size, FontWeight weight,
            {double ls = 0, Color? color, double? height}) =>
        TextStyle(
          fontFamily: monoFont,
          fontFamilyFallback: const <String>[
            'JetBrains Mono',
            'Fira Code',
            'Menlo',
            'Consolas',
            'monospace',
          ],
          fontSize: size,
          fontWeight: weight,
          letterSpacing: ls,
          height: height,
          color: color ?? scheme.onSurface,
        );

    return TextTheme(
      displayLarge: ui(46, FontWeight.w700, ls: -1.4, height: 1.05),
      displayMedium: ui(38, FontWeight.w700, ls: -1.0, height: 1.08),
      displaySmall: ui(30, FontWeight.w600, ls: -0.6, height: 1.14),
      headlineLarge: ui(26, FontWeight.w600, ls: -0.4),
      headlineMedium: ui(22, FontWeight.w600, ls: -0.2),
      headlineSmall: ui(19, FontWeight.w600, ls: -0.1),
      titleLarge: ui(17, FontWeight.w600, ls: 0.1),
      titleMedium: mono(14, FontWeight.w600, ls: 0.4),
      titleSmall: mono(12.5, FontWeight.w500, ls: 0.6),
      bodyLarge: ui(15.5, FontWeight.w400, height: 1.5),
      bodyMedium: ui(13.5, FontWeight.w400, height: 1.55),
      bodySmall: ui(11.5, FontWeight.w400, height: 1.5),
      labelLarge: ui(13, FontWeight.w600, ls: 0.6),
      labelMedium: ui(11.5, FontWeight.w500, ls: 0.8),
      labelSmall: mono(10, FontWeight.w500, ls: 1.0),
    );
  }

  /// Convenience: monospaced style for terminal-ish strings (hostnames,
  /// ports, hashes, log lines). Callers compose with `Theme.of(context)`.
  static TextStyle monoStyle(BuildContext context,
          {double size = 13, FontWeight weight = FontWeight.w500}) =>
      TextStyle(
        fontFamily: monoFont,
        fontFamilyFallback: const <String>[
          'JetBrains Mono',
          'Fira Code',
          'Menlo',
          'Consolas',
          'monospace',
        ],
        fontSize: size,
        fontWeight: weight,
        letterSpacing: 0.2,
        height: 1.45,
        color: Theme.of(context).colorScheme.onSurface,
      );
}

/// App-specific semantic colours that don't map cleanly onto Material's
/// ColorScheme (e.g. status colours used across servers, chat, terminal).
@immutable
class ShellMindSemanticColors
    extends ThemeExtension<ShellMindSemanticColors> {
  const ShellMindSemanticColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.glow,
    required this.grid,
  });

  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  /// Phosphor bloom used behind active/live elements.
  final Color glow;

  /// Ultra-subtle grid line colour for atmospheric backgrounds.
  final Color grid;

  static const ShellMindSemanticColors dark = ShellMindSemanticColors(
    success: AppTheme.mint,
    warning: AppTheme.amber,
    danger: AppTheme.coral,
    info: AppTheme.phosphor,
    glow: AppTheme.phosphorGlow,
    grid: Color(0x142B3554),
  );

  @override
  ShellMindSemanticColors copyWith({
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? glow,
    Color? grid,
  }) {
    return ShellMindSemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      glow: glow ?? this.glow,
      grid: grid ?? this.grid,
    );
  }

  @override
  ShellMindSemanticColors lerp(covariant ThemeExtension<dynamic>? other, double t) {
    if (other is! ShellMindSemanticColors) return this;
    return ShellMindSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      grid: Color.lerp(grid, other.grid, t)!,
    );
  }
}

/// Convenience accessor so widgets can write `context.sem.success` instead of
/// fishing the extension out of ThemeData every time.
extension ShellMindThemeX on BuildContext {
  ShellMindSemanticColors get sem =>
      Theme.of(this).extension<ShellMindSemanticColors>() ??
      ShellMindSemanticColors.dark;

  TextTheme get text => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
}
