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
      if (p != null) {
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
