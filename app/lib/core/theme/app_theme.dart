import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

// SkyLens "Observatory" design system (docs/DESIGN_TOKENS.md).
//
// - Deep blue-black canvas with two raised tones (surface, surfaceHigh);
//   depth comes from tone and 1px outlines, not shadows.
// - One typeface (Inter) with a real weight hierarchy: 600 for titles,
//   500 for labels, 400 for reading text; tabular figures for numbers.
// - One accent (starlight blue) for primary actions and selection; status
//   colours (success / warning / danger) always come with an icon or word.
// - Every variant is dark: bright screens ruin night vision. Night-vision
//   red and high contrast keep the same roles with accessibility palettes.
//
// All text pairs meet WCAG AA (4.5:1); control borders meet 3:1.

/// Theme variants. (`space` keeps its name so saved settings stay valid.)
enum SkyThemeVariant { space, nightRed, highContrast }

extension SkyThemeVariantLabel on SkyThemeVariant {
  String get label => switch (this) {
    SkyThemeVariant.space => 'Standard',
    SkyThemeVariant.nightRed => 'Night vision',
    SkyThemeVariant.highContrast => 'High contrast',
  };

  IconData get icon => switch (this) {
    SkyThemeVariant.space => Icons.dark_mode_outlined,
    SkyThemeVariant.nightRed => Icons.visibility_outlined,
    SkyThemeVariant.highContrast => Icons.contrast,
  };
}

const kFontFamily = 'Inter';

/// Numbers that update live (coordinates, times) shouldn't jitter.
const kTabularFigures = [FontFeature.tabularFigures()];

/// 4-pt spacing scale.
abstract final class Space {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Horizontal screen gutter.
  static const double gutter = 20;
}

abstract final class Radii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

/// Semantic colour roles. Widgets read these via `SkyTokens.of(context)` so
/// the night-vision theme recolours everything, including canvas drawings.
@immutable
class SkyTokens extends ThemeExtension<SkyTokens> {
  const SkyTokens({
    required this.bg,
    required this.surface,
    required this.surfaceHigh,
    required this.outline,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.success,
    required this.warning,
    required this.danger,
    required this.chartBg,
    required this.chartGrid,
    required this.star,
    required this.planet,
    required this.moon,
    required this.sun,
    required this.constellation,
    required this.horizon,
    required this.accents,
    this.strokeWidth = 1,
  });

  /// Screen background.
  final Color bg;

  /// Cards, list groups.
  final Color surface;

  /// Sheets, dialogs, inputs, selected segments.
  final Color surfaceHigh;

  /// Decorative dividers and card outlines.
  final Color outline;

  /// Interactive control boundaries (inputs, outlined buttons): ≥ 3:1.
  final Color border;

  final Color text;

  /// Secondary text. Still ≥ 4.5:1, so it can carry information.
  final Color textMuted;

  /// Disabled text and placeholders only.
  final Color textFaint;

  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;

  final Color success;
  final Color warning;
  final Color danger;

  // Sky chart and AR overlay.
  final Color chartBg;
  final Color chartGrid;
  final Color star;
  final Color planet;
  final Color moon;
  final Color sun;
  final Color constellation;
  final Color horizon;

  /// Friendly hues for feature tiles and illustrations (one per feature).
  /// Decorative only: never the sole carrier of meaning.
  final List<Color> accents;

  /// Border width for controls (thicker in high contrast).
  final double strokeWidth;

  static SkyTokens of(BuildContext context) =>
      Theme.of(context).extension<SkyTokens>()!;

  static const space = SkyTokens(
    bg: Color(0xFF070A12),
    surface: Color(0xFF0E1424),
    surfaceHigh: Color(0xFF161D30),
    outline: Color(0xFF26304A),
    border: Color(0xFF5B6886),
    text: Color(0xFFEDF1F8),
    textMuted: Color(0xFF9AA5BA),
    textFaint: Color(0xFF6A7590),
    primary: Color(0xFF7EA6FF),
    onPrimary: Color(0xFF07122E),
    primaryContainer: Color(0xFF18284D),
    onPrimaryContainer: Color(0xFFD3E0FF),
    success: Color(0xFF45D49A),
    warning: Color(0xFFF5C15C),
    danger: Color(0xFFFF8080),
    chartBg: Color(0xFF0B1530),
    chartGrid: Color(0x337EA6FF),
    star: Color(0xFFF4F6FB),
    planet: Color(0xFFF5C15C),
    moon: Color(0xFFE9E6DA),
    sun: Color(0xFFFFCF66),
    constellation: Color(0x667EA6FF),
    horizon: Color(0xFF9AA5BA),
    accents: [
      Color(0xFF7EA6FF), // blue
      Color(0xFFB49CFF), // violet
      Color(0xFF4FD1C5), // teal
      Color(0xFFF5C15C), // amber
      Color(0xFFFF8FB8), // pink
      Color(0xFF45D49A), // green
    ],
  );

  /// Red only, low luminance: protects dark adaptation at the eyepiece.
  static const nightRed = SkyTokens(
    bg: Color(0xFF000000),
    surface: Color(0xFF140404),
    surfaceHigh: Color(0xFF1E0606),
    outline: Color(0xFF3A0B0B),
    border: Color(0xFFA02B2B),
    text: Color(0xFFFF5C5C),
    textMuted: Color(0xFFDD5050),
    textFaint: Color(0xFF8A2525),
    primary: Color(0xFFFF5C5C),
    onPrimary: Color(0xFF000000),
    primaryContainer: Color(0xFF3A0B0B),
    onPrimaryContainer: Color(0xFFFF8A8A),
    success: Color(0xFFFF8A8A),
    warning: Color(0xFFFF5C5C),
    danger: Color(0xFFFF3D3D),
    chartBg: Color(0xFF0A0101),
    chartGrid: Color(0x55A02B2B),
    star: Color(0xFFFF6E6E),
    planet: Color(0xFFFF8A80),
    moon: Color(0xFFFF7961),
    sun: Color(0xFFFF5252),
    constellation: Color(0x66B71C1C),
    horizon: Color(0xFFB71C1C),
    accents: [
      Color(0xFFFF5C5C),
      Color(0xFFFF7A7A),
      Color(0xFFE05555),
      Color(0xFFFF8A8A),
      Color(0xFFFF6B6B),
      Color(0xFFFF5C5C),
    ],
  );

  static const highContrast = SkyTokens(
    bg: Color(0xFF000000),
    surface: Color(0xFF000000),
    surfaceHigh: Color(0xFF0D0D0D),
    outline: Color(0xFFFFFFFF),
    border: Color(0xFFFFFFFF),
    text: Color(0xFFFFFFFF),
    textMuted: Color(0xFFE6E6E6),
    textFaint: Color(0xFFBDBDBD),
    primary: Color(0xFFFFD60A),
    onPrimary: Color(0xFF000000),
    primaryContainer: Color(0xFF3D3300),
    onPrimaryContainer: Color(0xFFFFE97A),
    success: Color(0xFF5CFF9D),
    warning: Color(0xFFFFD60A),
    danger: Color(0xFFFF6B6B),
    chartBg: Color(0xFF000000),
    chartGrid: Color(0x99FFFFFF),
    star: Color(0xFFFFFFFF),
    planet: Color(0xFFFFD60A),
    moon: Color(0xFFFFFFFF),
    sun: Color(0xFFFFD60A),
    constellation: Color(0xCC00E5FF),
    horizon: Color(0xFFFFFFFF),
    accents: [
      Color(0xFFFFD60A),
      Color(0xFF00E5FF),
      Color(0xFFFFFFFF),
      Color(0xFFFFD60A),
      Color(0xFF00E5FF),
      Color(0xFFFFFFFF),
    ],
    strokeWidth: 2,
  );

  @override
  SkyTokens copyWith() => this;

  @override
  SkyTokens lerp(SkyTokens? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}

TextStyle _t(double size, double height, FontWeight w, [double ls = 0]) =>
    TextStyle(
      fontFamily: kFontFamily,
      fontSize: size,
      height: height / size,
      fontWeight: w,
      letterSpacing: ls,
    );

const _regular = FontWeight.w400;
const _medium = FontWeight.w500;
const _semi = FontWeight.w600;

/// Type scale (size / line height / weight / tracking).
TextTheme _textTheme(SkyTokens t) => TextTheme(
  displaySmall: _t(32, 40, _semi, -0.6),
  headlineMedium: _t(28, 36, _semi, -0.4),
  headlineSmall: _t(24, 32, _semi, -0.3),
  titleLarge: _t(20, 28, _semi, -0.2),
  titleMedium: _t(16, 24, _semi),
  titleSmall: _t(14, 20, _semi),
  bodyLarge: _t(16, 24, _regular),
  bodyMedium: _t(14, 20, _regular, 0.1),
  bodySmall: _t(12, 16, _regular, 0.2).copyWith(color: t.textMuted),
  labelLarge: _t(14, 20, _semi, 0.1),
  labelMedium: _t(12, 16, _medium, 0.3),
  labelSmall: _t(11, 16, _semi, 0.8),
).apply(bodyColor: t.text, displayColor: t.text);

ThemeData buildSkyTheme(SkyThemeVariant variant) {
  final t = switch (variant) {
    SkyThemeVariant.space => SkyTokens.space,
    SkyThemeVariant.nightRed => SkyTokens.nightRed,
    SkyThemeVariant.highContrast => SkyTokens.highContrast,
  };
  final text = _textTheme(t);
  final scheme = ColorScheme.dark(
    surface: t.bg,
    surfaceContainerLowest: t.bg,
    surfaceContainerLow: t.surface,
    surfaceContainer: t.surface,
    surfaceContainerHigh: t.surfaceHigh,
    surfaceContainerHighest: t.surfaceHigh,
    primary: t.primary,
    onPrimary: t.onPrimary,
    primaryContainer: t.primaryContainer,
    onPrimaryContainer: t.onPrimaryContainer,
    secondary: t.primary,
    onSecondary: t.onPrimary,
    secondaryContainer: t.primaryContainer,
    onSecondaryContainer: t.onPrimaryContainer,
    tertiary: t.success,
    onSurface: t.text,
    onSurfaceVariant: t.textMuted,
    error: t.danger,
    onError: t.bg,
    outline: t.border,
    outlineVariant: t.outline,
  );
  final outlineSide = BorderSide(color: t.outline, width: t.strokeWidth);
  final borderSide = BorderSide(color: t.border, width: t.strokeWidth);
  final overlay = WidgetStatePropertyAll(t.text.withValues(alpha: 0.08));
  final rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Radii.md),
  );
  // 48 dp minimum: usable with gloves and cold fingers.
  const buttonSize = Size(64, 48);
  const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 12);

  OutlineInputBorder input(Color c, [double extra = 0]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(Radii.md),
    borderSide: BorderSide(color: c, width: t.strokeWidth + extra),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    fontFamily: kFontFamily,
    textTheme: text,
    scaffoldBackgroundColor: t.bg,
    canvasColor: t.bg,
    splashFactory: InkRipple.splashFactory,
    dividerColor: t.outline,
    extensions: [t],
    visualDensity: VisualDensity.standard,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: t.bg,
      foregroundColor: t.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleSpacing: 4,
      titleTextStyle: text.titleLarge,
      shape: Border(bottom: outlineSide),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: t.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      indicatorColor: t.primaryContainer,
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? t.onPrimaryContainer
              : t.textMuted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => text.labelMedium!.copyWith(
          color: s.contains(WidgetState.selected) ? t.text : t.textMuted,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: t.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
        side: outlineSide,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: t.primary,
        foregroundColor: t.onPrimary,
        disabledBackgroundColor: t.surfaceHigh,
        disabledForegroundColor: t.textFaint,
        minimumSize: buttonSize,
        padding: buttonPadding,
        shape: rounded,
        textStyle: text.labelLarge,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: t.primaryContainer,
        foregroundColor: t.onPrimaryContainer,
        elevation: 0,
        minimumSize: buttonSize,
        padding: buttonPadding,
        shape: rounded,
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: t.text,
        disabledForegroundColor: t.textFaint,
        side: borderSide,
        minimumSize: buttonSize,
        padding: buttonPadding,
        shape: rounded,
        textStyle: text.labelLarge,
      ).copyWith(overlayColor: overlay),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: t.primary,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: rounded,
        textStyle: text.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: t.text,
        minimumSize: const Size(48, 48),
      ).copyWith(overlayColor: overlay),
    ),
    iconTheme: IconThemeData(color: t.text, size: 24),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: t.primary,
      foregroundColor: t.onPrimary,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      extendedTextStyle: text.labelLarge,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: t.textMuted,
      textColor: t.text,
      titleTextStyle: text.titleSmall,
      subtitleTextStyle: text.bodyMedium!.copyWith(color: t.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.lg),
      minVerticalPadding: Space.md,
      shape: rounded,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: t.surfaceHigh,
      modalBackgroundColor: t.surfaceHigh,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      modalElevation: 0,
      showDragHandle: true,
      dragHandleColor: t.border,
      modalBarrierColor: Colors.black.withValues(alpha: 0.6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: t.surfaceHigh,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.xl),
        side: outlineSide,
      ),
      titleTextStyle: text.titleLarge,
      contentTextStyle: text.bodyMedium!.copyWith(color: t.textMuted),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: t.surfaceHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: text.bodyLarge!.copyWith(color: t.textMuted),
      floatingLabelStyle: text.bodyMedium!.copyWith(color: t.primary),
      hintStyle: text.bodyLarge!.copyWith(color: t.textFaint),
      helperStyle: text.bodySmall,
      border: input(t.border),
      enabledBorder: input(t.border),
      focusedBorder: input(t.primary, 1),
      errorBorder: input(t.danger),
      focusedErrorBorder: input(t.danger, 1),
      errorStyle: text.bodySmall!.copyWith(color: t.danger),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: t.primary,
      selectionColor: t.primary.withValues(alpha: 0.3),
      selectionHandleColor: t.primary,
    ),
    dividerTheme: DividerThemeData(color: t.outline, space: 1, thickness: 1),
    chipTheme: ChipThemeData(
      backgroundColor: t.surface,
      selectedColor: t.primaryContainer,
      disabledColor: t.surface,
      checkmarkColor: t.onPrimaryContainer,
      showCheckmark: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      side: WidgetStateBorderSide.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? BorderSide(color: t.primaryContainer, width: t.strokeWidth)
            : borderSide,
      ),
      // M3 chips use labelStyle unselected, secondaryLabelStyle selected.
      labelStyle: text.labelLarge!.copyWith(color: t.text),
      secondaryLabelStyle: text.labelLarge!.copyWith(
        color: t.onPrimaryContainer,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    ),
    sliderTheme: SliderThemeData(
      trackHeight: 4,
      activeTrackColor: t.primary,
      inactiveTrackColor: t.surfaceHigh,
      thumbColor: t.primary,
      overlayColor: t.primary.withValues(alpha: 0.12),
      activeTickMarkColor: Colors.transparent,
      inactiveTickMarkColor: Colors.transparent,
      valueIndicatorColor: t.primaryContainer,
      valueIndicatorTextStyle: text.labelLarge!.copyWith(
        color: t.onPrimaryContainer,
      ),
      showValueIndicator: ShowValueIndicator.onDrag,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        foregroundColor: t.textMuted,
        selectedForegroundColor: t.onPrimaryContainer,
        selectedBackgroundColor: t.primaryContainer,
        side: borderSide,
        textStyle: text.labelLarge,
        minimumSize: const Size(0, 48),
        shape: rounded,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? t.onPrimary : t.textMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? t.primary : t.surfaceHigh,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? t.primary : t.border,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: t.primary,
      linearTrackColor: t.surfaceHigh,
      circularTrackColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: t.surfaceHigh,
      contentTextStyle: text.bodyMedium,
      actionTextColor: t.primary,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: outlineSide,
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: t.surfaceHigh,
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.fromBorderSide(outlineSide),
      ),
      textStyle: text.bodySmall!.copyWith(color: t.text),
    ),
  );
}
