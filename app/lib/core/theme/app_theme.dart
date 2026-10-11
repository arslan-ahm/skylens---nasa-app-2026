import 'package:flutter/material.dart';

// SkyLens design system (docs/DESIGN_TOKENS.md):
// - near-black canvas, white type doing all the work, one typeface (Geist)
//   at weight 400 only, with positive letter-spacing at every size;
// - flat elevation by tone only: Void #000 -> Carbon #181818 (bars) ->
//   Graphite #1E1F20 (cards); hairlines in Iron #333; no shadows or blur;
// - ghost (outlined) pill buttons, never filled;
// - colour only in diagrams (Concentric Teal, Deep Navy) and Signal Mint
//   reserved for live / active state.
//
// Night-vision red and high-contrast keep the same structure with
// accessibility palettes.

/// Theme variants. All are dark: bright screens ruin night vision.
/// (`space` keeps its name so saved settings stay valid.)
enum SkyThemeVariant { space, nightRed, highContrast }

extension SkyThemeVariantLabel on SkyThemeVariant {
  String get label => switch (this) {
    SkyThemeVariant.space => 'Space',
    SkyThemeVariant.nightRed => 'Night vision (red)',
    SkyThemeVariant.highContrast => 'High contrast',
  };
}

const kFontFamily = 'Geist';

/// Design tokens. Widgets read these via `SkyTokens.of(context)` so the
/// night-red mode can recolour everything, including canvas drawings.
@immutable
class SkyTokens extends ThemeExtension<SkyTokens> {
  const SkyTokens({
    required this.sky,
    required this.carbon,
    required this.surface,
    required this.surfaceRaised,
    required this.hairline,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.accent,
    required this.live,
    required this.diagram,
    required this.wash,
    required this.star,
    required this.planet,
    required this.moon,
    required this.sun,
    required this.constellation,
    required this.horizon,
    required this.warning,
    this.strokeWidth = 1,
  });

  /// Void: page canvas.
  final Color sky;

  /// Carbon: app bars, nav bars, sheets.
  final Color carbon;

  /// Graphite: cards, panels.
  final Color surface;

  /// Inputs and controls sitting on cards.
  final Color surfaceRaised;

  /// Iron: hairline borders and dividers.
  final Color hairline;

  /// Primary text and icon strokes.
  final Color ink;

  /// Slate: genuine de-emphasis only.
  final Color inkMuted;

  /// Fog / Ash: disabled, tertiary metadata, recessed outlines.
  final Color inkFaint;

  /// Primary action colour (white: actions are outlined, not coloured).
  final Color accent;

  /// Signal Mint: live data and active state only.
  final Color live;

  /// Concentric Teal: diagram strokes.
  final Color diagram;

  /// Deep Navy: atmospheric wash behind diagrams only.
  final Color wash;

  // Sky-chart colours (infographic elements).
  final Color star;
  final Color planet;
  final Color moon;
  final Color sun;
  final Color constellation;
  final Color horizon;

  /// Errors. Always paired with text: colour never carries meaning alone.
  final Color warning;

  /// Border width for outlined controls (thicker in high contrast).
  final double strokeWidth;

  static SkyTokens of(BuildContext context) =>
      Theme.of(context).extension<SkyTokens>()!;

  static const space = SkyTokens(
    sky: Color(0xFF000000),
    carbon: Color(0xFF181818),
    surface: Color(0xFF1E1F20),
    surfaceRaised: Color(0xFF1E1F20),
    hairline: Color(0xFF333333),
    ink: Color(0xFFFFFFFF),
    inkMuted: Color(0xFF807F7F),
    inkFaint: Color(0xFF666666),
    accent: Color(0xFFFFFFFF),
    live: Color(0xFF22E2A8),
    diagram: Color(0xFF085556),
    wash: Color(0xFF0A2142),
    star: Color(0xFFFFFFFF),
    planet: Color(0xFFFFFFFF),
    moon: Color(0xFFF1F4F4),
    sun: Color(0xFFFFFFFF),
    constellation: Color(0x59FFFFFF),
    horizon: Color(0xFFFFFFFF),
    warning: Color(0xFFF1F4F4),
  );

  /// Everything in deep red: preserves dark adaptation at the eyepiece.
  static const nightRed = SkyTokens(
    sky: Color(0xFF000000),
    carbon: Color(0xFF0D0000),
    surface: Color(0xFF140303),
    surfaceRaised: Color(0xFF140303),
    hairline: Color(0xFF3A0B0B),
    ink: Color(0xFFE53935),
    inkMuted: Color(0xFF9A2622),
    inkFaint: Color(0xFF6B1A17),
    accent: Color(0xFFE53935),
    live: Color(0xFFFF6E6E),
    diagram: Color(0xFF5C1210),
    wash: Color(0xFF1A0303),
    star: Color(0xFFFF6E6E),
    planet: Color(0xFFFF8A80),
    moon: Color(0xFFFF7961),
    sun: Color(0xFFFF5252),
    constellation: Color(0x66B71C1C),
    horizon: Color(0xFFB71C1C),
    warning: Color(0xFFFF1744),
  );

  static const highContrast = SkyTokens(
    sky: Color(0xFF000000),
    carbon: Color(0xFF000000),
    surface: Color(0xFF000000),
    surfaceRaised: Color(0xFF111111),
    hairline: Color(0xFFFFFFFF),
    ink: Color(0xFFFFFFFF),
    inkMuted: Color(0xFFE0E0E0),
    inkFaint: Color(0xFFBDBDBD),
    accent: Color(0xFFFFFFFF),
    live: Color(0xFFFFEB3B),
    diagram: Color(0xFF00E5FF),
    wash: Color(0xFF000000),
    star: Color(0xFFFFFFFF),
    planet: Color(0xFFFFEB3B),
    moon: Color(0xFFFFFFFF),
    sun: Color(0xFFFFEB3B),
    constellation: Color(0xCC00E5FF),
    horizon: Color(0xFFFFFFFF),
    warning: Color(0xFFFFEB3B),
    strokeWidth: 2,
  );

  @override
  SkyTokens copyWith() => this;

  @override
  SkyTokens lerp(SkyTokens? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}

/// One step of the DESIGN_TOKENS.md type scale: weight 400, positive tracking.
TextStyle skyText(double size, double height, double tracking) => TextStyle(
  fontFamily: kFontFamily,
  fontSize: size,
  height: height,
  letterSpacing: tracking,
  fontWeight: FontWeight.w400,
);

/// DESIGN_TOKENS.md type scale mapped onto Material roles.
TextTheme _textTheme(Color ink) => TextTheme(
  displayLarge: skyText(60, 1.13, 2.4), // display
  displayMedium: skyText(36, 1.13, 0.9), // heading
  displaySmall: skyText(32, 1.25, 0.8), // heading-sm
  headlineLarge: skyText(36, 1.13, 0.9),
  headlineMedium: skyText(32, 1.25, 0.8),
  headlineSmall: skyText(24, 1.33, 0.6), // subheading
  titleLarge: skyText(24, 1.33, 0.6),
  titleMedium: skyText(16, 1.6, 0.4), // body
  titleSmall: skyText(14, 1.43, 0.28),
  bodyLarge: skyText(16, 1.6, 0.4),
  bodyMedium: skyText(14, 1.43, 0.28), // body-sm
  bodySmall: skyText(12, 1.5, 0.24), // caption
  labelLarge: skyText(16, 1.6, 0.4),
  labelMedium: skyText(14, 1.43, 0.28),
  labelSmall: skyText(12, 1.5, 0.24),
).apply(bodyColor: ink, displayColor: ink);

ThemeData buildSkyTheme(SkyThemeVariant variant) {
  final t = switch (variant) {
    SkyThemeVariant.space => SkyTokens.space,
    SkyThemeVariant.nightRed => SkyTokens.nightRed,
    SkyThemeVariant.highContrast => SkyTokens.highContrast,
  };
  final text = _textTheme(t.ink);
  final scheme = ColorScheme.dark(
    surface: t.sky,
    surfaceContainerLowest: t.sky,
    surfaceContainerLow: t.carbon,
    surfaceContainer: t.surface,
    surfaceContainerHigh: t.surface,
    surfaceContainerHighest: t.surface,
    primary: t.accent,
    onPrimary: t.sky,
    secondary: t.ink,
    onSecondary: t.sky,
    tertiary: t.live,
    onSurface: t.ink,
    onSurfaceVariant: t.inkMuted,
    error: t.warning,
    onError: t.sky,
    outline: t.hairline,
    outlineVariant: t.hairline,
  );
  final hairline = BorderSide(color: t.hairline, width: t.strokeWidth);
  final inkLine = BorderSide(color: t.ink, width: t.strokeWidth);
  final overlay = WidgetStatePropertyAll(t.ink.withValues(alpha: 0.08));

  // The canonical action: transparent, 1px white border, pill, 10x30 padding.
  // Min height 48 keeps targets usable with gloves and cold fingers.
  final ghostPill = ButtonStyle(
    foregroundColor: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.disabled) ? t.inkFaint : t.ink,
    ),
    backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
    side: WidgetStateProperty.resolveWith(
      (s) => s.contains(WidgetState.disabled)
          ? BorderSide(color: t.inkFaint, width: t.strokeWidth)
          : inkLine,
    ),
    shape: const WidgetStatePropertyAll(StadiumBorder()),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 30, vertical: 10),
    ),
    minimumSize: const WidgetStatePropertyAll(Size(64, 48)),
    textStyle: WidgetStatePropertyAll(skyText(16, 1.6, 0.4)),
    elevation: const WidgetStatePropertyAll(0),
    overlayColor: overlay,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    fontFamily: kFontFamily,
    textTheme: text,
    scaffoldBackgroundColor: t.sky,
    canvasColor: t.sky,
    splashColor: t.ink.withValues(alpha: 0.06),
    highlightColor: Colors.transparent,
    dividerColor: t.hairline,
    extensions: [t],
    appBarTheme: AppBarTheme(
      backgroundColor: t.carbon,
      foregroundColor: t.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: skyText(16, 1.6, 0.4).copyWith(color: t.ink),
      shape: Border(bottom: hairline),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: t.carbon,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      indicatorColor: t.surface,
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected) ? t.ink : t.inkMuted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => skyText(12, 1.5, 0.24).copyWith(
          color: s.contains(WidgetState.selected) ? t.ink : t.inkMuted,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: t.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: t.strokeWidth > 1 ? hairline : BorderSide.none,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(style: ghostPill),
    outlinedButtonTheme: OutlinedButtonThemeData(style: ghostPill),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ghostPill),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: t.ink,
        textStyle: skyText(16, 1.6, 0.4),
        shape: const StadiumBorder(),
        minimumSize: const Size(48, 48),
      ).copyWith(overlayColor: overlay),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: t.ink,
        minimumSize: const Size(48, 48),
      ).copyWith(overlayColor: overlay),
    ),
    iconTheme: IconThemeData(color: t.ink, size: 24),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: t.sky,
      foregroundColor: t.ink,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: StadiumBorder(side: inkLine),
      extendedTextStyle: skyText(16, 1.6, 0.4),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: t.ink,
      textColor: t.ink,
      titleTextStyle: skyText(16, 1.6, 0.4).copyWith(color: t.ink),
      subtitleTextStyle: skyText(14, 1.43, 0.28).copyWith(color: t.inkMuted),
      minVerticalPadding: 12,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: t.carbon,
      modalBackgroundColor: t.carbon,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      modalElevation: 0,
      showDragHandle: true,
      dragHandleColor: t.inkFaint,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: t.carbon,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: hairline,
      ),
      titleTextStyle: skyText(24, 1.33, 0.6).copyWith(color: t.ink),
      contentTextStyle: skyText(16, 1.6, 0.4).copyWith(color: t.inkMuted),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      labelStyle: skyText(16, 1.6, 0.4).copyWith(color: t.inkMuted),
      floatingLabelStyle: skyText(14, 1.43, 0.28).copyWith(color: t.ink),
      hintStyle: skyText(16, 1.6, 0.4).copyWith(color: t.inkFaint),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: hairline,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: hairline,
      ),
      // Focus is an active state: Signal Mint.
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: t.live, width: t.strokeWidth + 0.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: t.warning, width: t.strokeWidth),
      ),
      errorStyle: skyText(12, 1.5, 0.24).copyWith(color: t.warning),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: t.live,
      selectionColor: t.live.withValues(alpha: 0.3),
      selectionHandleColor: t.live,
    ),
    dividerTheme: DividerThemeData(color: t.hairline, space: 1, thickness: 1),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.transparent,
      selectedColor: Colors.transparent,
      disabledColor: Colors.transparent,
      showCheckmark: false,
      shape: const StadiumBorder(),
      side: WidgetStateBorderSide.resolveWith(
        (s) => s.contains(WidgetState.selected) ? inkLine : hairline,
      ),
      // M3 chips use labelStyle when unselected, secondaryLabelStyle when
      // selected.
      labelStyle: skyText(14, 1.43, 0.28).copyWith(color: t.inkMuted),
      secondaryLabelStyle: skyText(14, 1.43, 0.28).copyWith(color: t.ink),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    sliderTheme: SliderThemeData(
      trackHeight: 2,
      activeTrackColor: t.ink,
      inactiveTrackColor: t.hairline,
      thumbColor: t.ink,
      overlayColor: t.ink.withValues(alpha: 0.1),
      activeTickMarkColor: Colors.transparent,
      inactiveTickMarkColor: Colors.transparent,
      valueIndicatorColor: t.surface,
      valueIndicatorTextStyle: skyText(14, 1.43, 0.28).copyWith(color: t.ink),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        foregroundColor: t.inkMuted,
        selectedForegroundColor: t.ink,
        selectedBackgroundColor: t.surface,
        side: hairline,
        textStyle: skyText(14, 1.43, 0.28),
        shape: const StadiumBorder(),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStatePropertyAll(t.ink),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? t.live : t.surface,
      ),
      trackOutlineColor: WidgetStatePropertyAll(t.hairline),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: t.ink,
      linearTrackColor: t.hairline,
      circularTrackColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: t.surface,
      contentTextStyle: skyText(14, 1.43, 0.28).copyWith(color: t.ink),
      actionTextColor: t.ink,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: skyText(12, 1.5, 0.24).copyWith(color: t.ink),
    ),
  );
}
