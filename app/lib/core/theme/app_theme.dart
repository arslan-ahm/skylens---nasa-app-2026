import 'package:flutter/material.dart';

/// Theme variants. All are dark: bright screens ruin night vision.
enum SkyThemeVariant { space, nightRed, highContrast }

extension SkyThemeVariantLabel on SkyThemeVariant {
  String get label => switch (this) {
    SkyThemeVariant.space => 'Space',
    SkyThemeVariant.nightRed => 'Night vision (red)',
    SkyThemeVariant.highContrast => 'High contrast',
  };
}

/// Design tokens. Widgets read these via `SkyTokens.of(context)` so the
/// night-red mode can recolour everything, including canvas drawings.
@immutable
class SkyTokens extends ThemeExtension<SkyTokens> {
  const SkyTokens({
    required this.sky,
    required this.surface,
    required this.surfaceRaised,
    required this.ink,
    required this.inkMuted,
    required this.accent,
    required this.star,
    required this.planet,
    required this.moon,
    required this.sun,
    required this.constellation,
    required this.horizon,
    required this.warning,
  });

  final Color sky;
  final Color surface;
  final Color surfaceRaised;
  final Color ink;
  final Color inkMuted;
  final Color accent;
  final Color star;
  final Color planet;
  final Color moon;
  final Color sun;
  final Color constellation;
  final Color horizon;
  final Color warning;

  static SkyTokens of(BuildContext context) =>
      Theme.of(context).extension<SkyTokens>()!;

  static const space = SkyTokens(
    sky: Color(0xFF05070D),
    surface: Color(0xFF0D1220),
    surfaceRaised: Color(0xFF161D31),
    ink: Color(0xFFE8ECF6),
    inkMuted: Color(0xFF8D97B0),
    accent: Color(0xFF7CC4FF),
    star: Color(0xFFF4F1E8),
    planet: Color(0xFFFFC870),
    moon: Color(0xFFDCE3F0),
    sun: Color(0xFFFFB347),
    constellation: Color(0x667CC4FF),
    horizon: Color(0xFF3FB27F),
    warning: Color(0xFFFF8A65),
  );

  /// Everything in deep red: preserves dark adaptation at the eyepiece.
  static const nightRed = SkyTokens(
    sky: Color(0xFF000000),
    surface: Color(0xFF0E0000),
    surfaceRaised: Color(0xFF1A0202),
    ink: Color(0xFFE53935),
    inkMuted: Color(0xFF9A2622),
    accent: Color(0xFFFF5252),
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
    surface: Color(0xFF000000),
    surfaceRaised: Color(0xFF1C1C1C),
    ink: Color(0xFFFFFFFF),
    inkMuted: Color(0xFFD0D0D0),
    accent: Color(0xFFFFEB3B),
    star: Color(0xFFFFFFFF),
    planet: Color(0xFFFFEB3B),
    moon: Color(0xFFFFFFFF),
    sun: Color(0xFFFFEB3B),
    constellation: Color(0xCC00E5FF),
    horizon: Color(0xFF00E676),
    warning: Color(0xFFFF9100),
  );

  @override
  SkyTokens copyWith() => this;

  @override
  SkyTokens lerp(SkyTokens? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}

ThemeData buildSkyTheme(SkyThemeVariant variant) {
  final t = switch (variant) {
    SkyThemeVariant.space => SkyTokens.space,
    SkyThemeVariant.nightRed => SkyTokens.nightRed,
    SkyThemeVariant.highContrast => SkyTokens.highContrast,
  };
  final scheme = ColorScheme.dark(
    surface: t.surface,
    surfaceContainerHighest: t.surfaceRaised,
    primary: t.accent,
    onPrimary: t.sky,
    secondary: t.planet,
    onSurface: t.ink,
    onSurfaceVariant: t.inkMuted,
    error: t.warning,
    outline: t.inkMuted.withValues(alpha: 0.4),
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: Brightness.dark,
  );
  final borderWidth = variant == SkyThemeVariant.highContrast ? 2.0 : 1.0;

  return base.copyWith(
    scaffoldBackgroundColor: t.sky,
    extensions: [t],
    textTheme: base.textTheme.apply(bodyColor: t.ink, displayColor: t.ink),
    appBarTheme: AppBarTheme(
      backgroundColor: t.sky,
      foregroundColor: t.ink,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: t.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outline, width: borderWidth),
      ),
    ),
    // Large targets: gloves, cold fingers, one-handed use in the dark.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 52),
        side: BorderSide(color: scheme.outline, width: borderWidth),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: t.inkMuted,
      minVerticalPadding: 12,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: t.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: t.surfaceRaised,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.outline, space: 1),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: t.surfaceRaised,
      side: BorderSide(color: scheme.outline, width: borderWidth),
    ),
  );
}
