import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../theme/app_theme.dart';

class AppSettings {
  const AppSettings({
    this.theme = SkyThemeVariant.space,
    this.textScale = 1.0,
    this.compassOffsetDeg = 0,
    this.cameraFovDeg = 60,
    this.manualLat,
    this.manualLon,
  });

  factory AppSettings.fromMap(Map<dynamic, dynamic> m) => AppSettings(
    theme:
        SkyThemeVariant.values.asNameMap()[m['theme']] ?? SkyThemeVariant.space,
    textScale: (m['textScale'] as num?)?.toDouble() ?? 1.0,
    compassOffsetDeg: (m['compassOffset'] as num?)?.toDouble() ?? 0,
    cameraFovDeg: (m['cameraFov'] as num?)?.toDouble() ?? 60,
    manualLat: (m['manualLat'] as num?)?.toDouble(),
    manualLon: (m['manualLon'] as num?)?.toDouble(),
  );

  final SkyThemeVariant theme;
  final double textScale;

  /// Added to the magnetic azimuth: declination + user calibration.
  final double compassOffsetDeg;

  /// Vertical FOV of the camera preview, tuned per device.
  final double cameraFovDeg;
  final double? manualLat;
  final double? manualLon;

  bool get hasManualLocation => manualLat != null && manualLon != null;

  AppSettings copyWith({
    SkyThemeVariant? theme,
    double? textScale,
    double? compassOffsetDeg,
    double? cameraFovDeg,
    double? manualLat,
    double? manualLon,
    bool clearManualLocation = false,
  }) => AppSettings(
    theme: theme ?? this.theme,
    textScale: textScale ?? this.textScale,
    compassOffsetDeg: compassOffsetDeg ?? this.compassOffsetDeg,
    cameraFovDeg: cameraFovDeg ?? this.cameraFovDeg,
    manualLat: clearManualLocation ? null : (manualLat ?? this.manualLat),
    manualLon: clearManualLocation ? null : (manualLon ?? this.manualLon),
  );

  Map<String, dynamic> toMap() => {
    'theme': theme.name,
    'textScale': textScale,
    'compassOffset': compassOffsetDeg,
    'cameraFov': cameraFovDeg,
    'manualLat': manualLat,
    'manualLon': manualLon,
  };
}

class AppSettingsNotifier extends Notifier<AppSettings> {
  static const _key = 'app_settings';

  @override
  AppSettings build() {
    final raw = ref.watch(localStoreProvider).settings.get(_key) as Map?;
    return raw == null ? const AppSettings() : AppSettings.fromMap(raw);
  }

  void update(AppSettings Function(AppSettings s) change) {
    state = change(state);
    ref.read(localStoreProvider).settings.put(_key, state.toMap());
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);
