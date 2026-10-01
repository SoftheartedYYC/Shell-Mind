import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shell-Mind visual identity — "Clean Minimal".
///
/// A Material 3 design language with a clean, modern aesthetic.
/// Light theme uses pure whites and subtle greys; dark theme uses
/// deep greys (not pure black) with soft contrast. Blue is the
/// primary accent in both modes.
abstract final class AppTheme {
  // ─── Light palette ─────────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF5F5F5);
  static const Color lightSurfaceVariant = Color(0xFFEEEEEE);
  static const Color lightPrimary = Color(0xFF1976D2);
  static const Color lightPrimaryContainer = Color(0xFFBBDEFB);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF212121);
  static const Color lightTextSecondary = Color(0xFF757575);
  static const Color lightTextTertiary = Color(0xFF9E9E9E);
  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color lightError = Color(0xFFD32F2F);

  // ─── Dark palette ──────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);
  static const Color darkPrimary = Color(0xFF64B5F6);
  static const Color darkPrimaryContainer = Color(0xFF1A3A5C);
  static const Color darkOnPrimary = Color(0xFF0D1B2A);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkTextTertiary = Color(0xFF808080);
  static const Color darkBorder = Color(0xFF2C2C2C);
  static const Color darkError = Color(0xFFEF5350);

  // ─── Semantic colours (shared) ─────────────────────────────────────────
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color danger = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // ─── Typography ────────────────────────────────────────────────────────
  /// Monospace family for terminal output, server addresses, etc.
  static const String monoFont = 'RobotoMono';

  static const List<String> monoFallback = <String>[
    'JetBrains Mono',
    'Fira Code',
    'Menlo',
    'Consolas',
    'monospace',
  ];

  // ─── Themes ────────────────────────────────────────────────────────────
  static ThemeData get lightTheme => _buildLight();
  static ThemeData get darkTheme => _buildDark();

  static ThemeData _buildLight() {
    const ColorScheme scheme = ColorScheme(
      brightness: Brightness.light,
      primary: lightPrimary,
      onPrimary: lightOnPrimary,
      primaryContainer: lightPrimaryContainer,
      onPrimaryContainer: Color(0xFF0D47A1),
      secondary: Color(0xFF26A69A),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFB2DFDB),
      onSecondaryContainer: Color(0xFF004D40),
      tertiary: Color(0xFF7E57C2),
      onTertiary: Colors.white,
      error: lightError,
      onError: Colors.white,
      errorContainer: Color(0xFFFFEBEE),
      onErrorContainer: Color(0xFFB71C1C),
      surface: lightBackground,
      onSurface: lightTextPrimary,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Color(0xFFFAFAFA),
      surfaceContainer: lightSurface,
      surfaceContainerHigh: Color(0xFFEEEEEE),
      surfaceContainerHighest: Color(0xFFE0E0E0),
      onSurfaceVariant: lightTextSecondary,
      outline: Color(0xFFBDBDBD),
      outlineVariant: lightBorder,
      shadow: Colors.black,
      scrim: Colors.black54,
      inverseSurface: Color(0xFF424242),
      onInverseSurface: Colors.white,
      inversePrimary: darkPrimary,
    );

    return _buildBase(scheme, Brightness.light, SystemUiOverlayStyle.dark);
  }

  static ThemeData _buildDark() {
    const ColorScheme scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: darkPrimary,
      onPrimary: darkOnPrimary,
      primaryContainer: darkPrimaryContainer,
      onPrimaryContainer: Color(0xFFBBDEFB),
      secondary: Color(0xFF80CBC4),
      onSecondary: Color(0xFF00382E),
      secondaryContainer: Color(0xFF004D40),
      onSecondaryContainer: Color(0xFFB2DFDB),
      tertiary: Color(0xFFB39DDB),
      onTertiary: Color(0xFF1A0533),
      error: darkError,
      onError: Color(0xFF4A0000),
      errorContainer: Color(0xFF3D1414),
      onErrorContainer: Color(0xFFFFCDD2),
      surface: darkBackground,
      onSurface: darkTextPrimary,
      surfaceContainerLowest: Color(0xFF0A0A0A),
      surfaceContainerLow: Color(0xFF181818),
      surfaceContainer: darkSurface,
      surfaceContainerHigh: Color(0xFF262626),
      surfaceContainerHighest: Color(0xFF333333),
      onSurfaceVariant: darkTextSecondary,
      outline: Color(0xFF616161),
      outlineVariant: darkBorder,
      shadow: Colors.black,
      scrim: Colors.black87,
      inverseSurface: Color(0xFFE0E0E0),
      onInverseSurface: Color(0xFF212121),
      inversePrimary: lightPrimary,
    );

    return _buildBase(scheme, Brightness.dark, SystemUiOverlayStyle.light);
  }

  static ThemeData _buildBase(
    ColorScheme scheme,
    Brightness brightness,
    SystemUiOverlayStyle overlayStyle,
  ) {
    final bool isLight = brightness == Brightness.light;
    final TextTheme text = _buildTextTheme(scheme);

    final ThemeData base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: text,
      primaryTextTheme: text,
    );

    final Color cardBorder = isLight ? lightBorder : darkBorder;

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: overlayStyle,
        iconTheme: IconThemeData(color: scheme.onSurface, size: 24),
      ),
      cardTheme: CardThemeData(
        color: isLight ? Colors.white : darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: isLight ? 1 : 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isLight
              ? BorderSide(color: cardBorder.withValues(alpha: 0.5))
              : BorderSide(color: cardBorder),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: cardBorder,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? Colors.white : darkSurfaceVariant,
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        labelStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        floatingLabelStyle: text.bodyMedium?.copyWith(color: scheme.primary),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: _inputBorder(isLight ? lightBorder : darkBorder),
        enabledBorder: _inputBorder(isLight ? lightBorder : darkBorder),
        focusedBorder: _inputBorder(scheme.primary, width: 2),
        errorBorder: _inputBorder(scheme.error),
        focusedErrorBorder: _inputBorder(scheme.error, width: 2),
        disabledBorder: _inputBorder(
          (isLight ? lightBorder : darkBorder).withValues(alpha: 0.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size(0, 48),
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: scheme.onSurfaceVariant,
          highlightColor: scheme.primary.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        focusElevation: 4,
        hoverElevation: 4,
        highlightElevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isLight ? lightSurface : darkSurfaceVariant,
        selectedColor: scheme.primary.withValues(alpha: 0.12),
        disabledColor: (isLight ? lightSurface : darkSurfaceVariant)
            .withValues(alpha: 0.5),
        side: BorderSide(
          color: isLight ? lightBorder : darkBorder,
        ),
        labelStyle: text.labelMedium,
        secondaryLabelStyle: text.labelMedium?.copyWith(color: scheme.primary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        selectedColor: scheme.primary,
        selectedTileColor: scheme.primary.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isLight ? Colors.white : darkSurface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: 0.1),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: isLight ? 3 : 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final bool selected = states.contains(WidgetState.selected);
          return text.labelSmall?.copyWith(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: isLight ? lightBorder : darkBorder,
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelMedium,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isLight ? Colors.white : darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: isLight ? 4 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isLight
              ? BorderSide.none
              : BorderSide(color: darkBorder),
        ),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isLight ? Colors.white : darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: isLight ? 4 : 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isLight ? const Color(0xFF323232) : const Color(0xFF424242),
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        actionTextColor: scheme.primary,
        behavior: SnackBarBehavior.floating,
        elevation: isLight ? 4 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFF616161) : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: text.bodySmall?.copyWith(
          color: isLight ? Colors.white : const Color(0xFF212121),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: isLight ? lightBorder : darkSurfaceVariant,
        circularTrackColor: isLight ? lightBorder : darkSurfaceVariant,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? scheme.primary
                : (isLight ? Colors.grey.shade100 : Colors.grey.shade700)),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? scheme.primary.withValues(alpha: 0.5)
                : (isLight ? Colors.grey.shade300 : Colors.grey.shade800)),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.outline),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? scheme.primary
                : Colors.transparent),
        checkColor: WidgetStatePropertyAll<Color>(scheme.onPrimary),
        side: BorderSide(color: scheme.outline, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.outline),
        overlayColor:
            WidgetStatePropertyAll(scheme.primary.withValues(alpha: 0.12)),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: isLight ? lightBorder : darkSurfaceVariant,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
        trackHeight: 4,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isLight ? Colors.white : darkSurface,
        surfaceTintColor: Colors.transparent,
        elevation: isLight ? 4 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isLight
              ? BorderSide.none
              : BorderSide(color: darkBorder),
        ),
        textStyle: text.bodyMedium,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          scheme.onSurface.withValues(alpha: 0.2),
        ),
        thickness: const WidgetStatePropertyAll(6),
        radius: const Radius.circular(3),
        crossAxisMargin: 2,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(text.labelMedium),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[
        isLight
            ? ShellMindSemanticColors.light
            : ShellMindSemanticColors.dark,
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
    TextStyle style(double size, FontWeight weight,
            {double ls = 0, Color? color, double? height}) =>
        TextStyle(
          fontSize: size,
          fontWeight: weight,
          letterSpacing: ls,
          height: height,
          color: color ?? scheme.onSurface,
        );

    return TextTheme(
      displayLarge: style(40, FontWeight.w700, ls: -1.0, height: 1.1),
      displayMedium: style(34, FontWeight.w700, ls: -0.8, height: 1.15),
      displaySmall: style(28, FontWeight.w600, ls: -0.5, height: 1.2),
      headlineLarge: style(24, FontWeight.w600, ls: -0.3),
      headlineMedium: style(20, FontWeight.w600, ls: -0.2),
      headlineSmall: style(18, FontWeight.w600),
      titleLarge: style(18, FontWeight.w600, ls: -0.1),
      titleMedium: style(16, FontWeight.w600),
      titleSmall: style(14, FontWeight.w500),
      bodyLarge: style(16, FontWeight.w400, height: 1.5),
      bodyMedium: style(14, FontWeight.w400, height: 1.5),
      bodySmall: style(12, FontWeight.w400, height: 1.5),
      labelLarge: style(14, FontWeight.w600, ls: 0.2),
      labelMedium: style(12, FontWeight.w500, ls: 0.4),
      labelSmall: style(11, FontWeight.w500, ls: 0.4),
    );
  }

  /// Monospaced style for terminal-ish strings.
  static TextStyle monoStyle(BuildContext context,
          {double size = 13, FontWeight weight = FontWeight.w500}) =>
      TextStyle(
        fontFamily: monoFont,
        fontFamilyFallback: monoFallback,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: 0.2,
        height: 1.45,
        color: Theme.of(context).colorScheme.onSurface,
      );
}

/// App-specific semantic colours that don't map onto Material's ColorScheme.
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
  final Color glow;
  final Color grid;

  static const ShellMindSemanticColors light = ShellMindSemanticColors(
    success: Color(0xFF388E3C),
    warning: Color(0xFFF57C00),
    danger: Color(0xFFD32F2F),
    info: Color(0xFF1976D2),
    glow: Color(0xFF2196F3),
    grid: Color(0x0A000000),
  );

  static const ShellMindSemanticColors dark = ShellMindSemanticColors(
    success: Color(0xFF66BB6A),
    warning: Color(0xFFFFB74D),
    danger: Color(0xFFEF5350),
    info: Color(0xFF64B5F6),
    glow: Color(0xFF90CAF9),
    grid: Color(0x0AFFFFFF),
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
  ShellMindSemanticColors lerp(
      covariant ThemeExtension<dynamic>? other, double t) {
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

/// Convenience extension for accessing theme data.
extension ShellMindThemeX on BuildContext {
  ShellMindSemanticColors get sem =>
      Theme.of(this).extension<ShellMindSemanticColors>() ??
      ShellMindSemanticColors.light;

  TextTheme get text => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
}
