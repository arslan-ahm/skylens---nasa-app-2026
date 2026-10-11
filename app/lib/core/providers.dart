import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/logbook/logbook_repository.dart';
import '../data/nasa/nasa_repository.dart';
import '../data/weather/weather_repository.dart';
import 'astro/coordinates.dart';
import 'astro/sky_catalog.dart';
import 'astro/sky_engine.dart';
import 'network/cached_fetcher.dart';
import 'sensors/location_service.dart';
import 'sensors/orientation_service.dart';
import 'sensors/pointing_math.dart';
import 'settings/app_settings.dart';
import 'storage/local_store.dart';

// --- Infrastructure --------------------------------------------------------

/// Overridden in main() after Hive has opened.
final localStoreProvider = Provider<LocalStore>(
  (ref) => throw UnimplementedError('Override localStoreProvider in main()'),
);

final dioProvider = Provider<Dio>((ref) => createDio());

final fetcherProvider = Provider<CachedFetcher>(
  (ref) => CachedFetcher(
    ref.watch(dioProvider),
    ref.watch(localStoreProvider).cache,
  ),
);

// --- Repositories ----------------------------------------------------------

final nasaRepositoryProvider = Provider(
  (ref) => NasaRepository(ref.watch(fetcherProvider)),
);
final weatherRepositoryProvider = Provider(
  (ref) => WeatherRepository(ref.watch(fetcherProvider)),
);
final logbookRepositoryProvider = Provider(
  (ref) => LogbookRepository(ref.watch(localStoreProvider).logbook),
);

// --- Sky -------------------------------------------------------------------

final skyCatalogProvider = FutureProvider<SkyCatalog>((ref) async {
  final stars = await rootBundle.loadString('assets/catalog/stars.json');
  final consts = await rootBundle.loadString(
    'assets/catalog/constellations.json',
  );
  return SkyCatalog.fromJson(stars, consts);
});

final skyEngineProvider = Provider<SkyEngine>(
  (ref) => SkyEngine(ref.watch(skyCatalogProvider).value ?? SkyCatalog.empty),
);

final locationServiceProvider = Provider((ref) => const LocationService());

/// Observer location; manual override from settings wins over GPS.
final observerLocationProvider = FutureProvider<ObserverLocation>((ref) async {
  final s = ref.watch(appSettingsProvider);
  if (s.hasManualLocation) {
    return ObserverLocation(
      Observer(latitude: s.manualLat!, longitude: s.manualLon!),
      LocationSource.manual,
    );
  }
  return ref.watch(locationServiceProvider).current();
});

/// Optional time travel: null = live clock.
final timeOverrideProvider = NotifierProvider<TimeOverride, DateTime?>(
  TimeOverride.new,
);

class TimeOverride extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;
  void set(DateTime? t) => state = t;
}

/// Ticks once a second (positions change ~0.004°/s — plenty for AR).
final clockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

final skyTimeProvider = Provider<DateTime>(
  (ref) =>
      ref.watch(timeOverrideProvider) ??
      ref.watch(clockProvider).value ??
      DateTime.now(),
);

/// The whole sky for the current observer and time.
final skySnapshotProvider = Provider<AsyncValue<SkySnapshot>>((ref) {
  final catalog = ref.watch(skyCatalogProvider);
  final loc = ref.watch(observerLocationProvider);
  if (catalog.isLoading || loc.isLoading) return const AsyncLoading();
  if (catalog.hasError) return AsyncError(catalog.error!, catalog.stackTrace!);
  final engine = ref.watch(skyEngineProvider);
  final observer = (loc.value ?? LocationService.fallback).observer;
  return AsyncData(engine.compute(observer, ref.watch(skyTimeProvider)));
});

// --- Sensors ---------------------------------------------------------------

final orientationServiceProvider = Provider((ref) => OrientationService());

final devicePoseProvider = StreamProvider<DevicePose>((ref) {
  final offset = ref.watch(
    appSettingsProvider.select((s) => s.compassOffsetDeg),
  );
  return ref.watch(orientationServiceProvider).poses(declinationDeg: offset);
});
