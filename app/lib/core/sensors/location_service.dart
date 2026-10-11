import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../astro/coordinates.dart';

enum LocationSource { gps, lastKnown, manual, fallback }

class ObserverLocation {
  const ObserverLocation(
    this.observer,
    this.source, {
    this.label,
    this.accuracyM,
  });

  final Observer observer;
  final LocationSource source;
  final String? label;
  final double? accuracyM;

  String get sourceLabel => switch (source) {
    LocationSource.gps => 'GPS',
    LocationSource.lastKnown => 'Last known',
    LocationSource.manual => 'Set manually',
    LocationSource.fallback => 'Default location',
  };
}

/// Location with graceful degradation: precise fix -> last known -> a
/// default, so sky calculations always have an observer. Astronomy only
/// needs ~1 km precision, so we ask for medium accuracy (faster, less power).
class LocationService {
  const LocationService();

  /// Used when permission is denied or there's no fix (Greenwich).
  static const fallback = ObserverLocation(
    Observer(latitude: 51.4779, longitude: -0.0015, elevationM: 46),
    LocationSource.fallback,
    label: 'Greenwich, UK',
  );

  /// Rejects fixes that would silently put the sky in the wrong place:
  /// NaN/out-of-range values, the (0, 0) "null island" some devices report
  /// before a real fix, and accuracies worse than ~50 km.
  static bool isUsableFix(double lat, double lon, double? accuracyM) {
    if (!lat.isFinite || !lon.isFinite) return false;
    if (lat.abs() > 90 || lon.abs() > 180) return false;
    if (lat == 0 && lon == 0) return false;
    if (accuracyM != null && accuracyM > 50000) return false;
    return true;
  }

  Future<ObserverLocation> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return await _lastKnownOrFallback();
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return await _lastKnownOrFallback();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!isUsableFix(pos.latitude, pos.longitude, pos.accuracy)) {
        return await _lastKnownOrFallback();
      }
      return ObserverLocation(
        Observer(
          latitude: pos.latitude,
          longitude: pos.longitude,
          elevationM: pos.altitude,
        ),
        LocationSource.gps,
        accuracyM: pos.accuracy,
      );
    } catch (e) {
      debugPrint('LocationService: $e');
      return _lastKnownOrFallback();
    }
  }

  Future<ObserverLocation> _lastKnownOrFallback() async {
    if (kIsWeb) return fallback; // not supported on web
    try {
      final p = await Geolocator.getLastKnownPosition();
      if (p != null && isUsableFix(p.latitude, p.longitude, p.accuracy)) {
        return ObserverLocation(
          Observer(
            latitude: p.latitude,
            longitude: p.longitude,
            elevationM: p.altitude,
          ),
          LocationSource.lastKnown,
          accuracyM: p.accuracy,
        );
      }
    } catch (_) {}
    return fallback;
  }

  Future<bool> openSettings() => Geolocator.openAppSettings();
}
