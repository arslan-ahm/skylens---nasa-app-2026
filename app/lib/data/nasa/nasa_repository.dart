import 'package:intl/intl.dart';

import '../../core/config/app_config.dart';
import '../../core/network/cached_fetcher.dart';
import '../../core/network/provenance.dart';
import 'nasa_models.dart';

/// NASA open APIs with caching, offline fallback and attribution baked in.
class NasaRepository {
  NasaRepository(this._fetcher);

  final CachedFetcher _fetcher;
  static final _day = DateFormat('yyyy-MM-dd');

  static const _apiBase = 'https://api.nasa.gov';

  DataProvenance _p(String source, String url, {String? note}) =>
      DataProvenance(
        source: source,
        url: url,
        license: 'NASA open data (public domain unless noted)',
        fetchedAt: DateTime.now(),
        note: note,
      );

  /// Astronomy Picture of the Day. [date] defaults to today.
  Future<Sourced<Apod>> apod({DateTime? date}) async {
    final r = await _fetcher.getJson(
      url: '$_apiBase/planetary/apod',
      query: {
        'api_key': AppConfig.nasaApiKey,
        'date': ?(date == null ? null : _day.format(date)),
      },
      provenance: _p('NASA APOD', 'https://apod.nasa.gov/'),
      ttl: const Duration(hours: 6),
      mockAsset: 'assets/mock/apod.json',
    );
    return r.map((j) => Apod.fromJson(j as Map<String, dynamic>));
  }

  /// Near-Earth objects with close approaches in [start, start + days) (max 7).
  Future<Sourced<List<NearEarthObject>>> closeApproaches({
    required DateTime start,
    int days = 7,
  }) async {
    final end = start.add(Duration(days: (days - 1).clamp(0, 6)));
    final r = await _fetcher.getJson(
      url: '$_apiBase/neo/rest/v1/feed',
      query: {
        'api_key': AppConfig.nasaApiKey,
        'start_date': _day.format(start),
        'end_date': _day.format(end),
      },
      provenance: _p('NASA NeoWs (JPL CNEOS data)', 'https://api.nasa.gov/'),
      ttl: const Duration(hours: 12),
      mockAsset: 'assets/mock/neo_feed.json',
    );
    return r.map((j) {
      final byDate = ((j as Map)['near_earth_objects'] as Map?) ?? const {};
      final all = [
        for (final list in byDate.values)
          for (final o in (list as List).cast<Map<String, dynamic>>())
            NearEarthObject.fromJson(o),
      ]..sort((a, b) => a.closeApproach.compareTo(b.closeApproach));
      return all;
    });
  }

  /// DONKI space-weather notifications for the last [days] days.
  ///
  /// Since Sep 2026 DONKI is served directly by CCMC (no key); the old
  /// api.nasa.gov/DONKI path redirects to an HTML announcement page.
  Future<Sourced<List<SpaceWeatherNotice>>> spaceWeather({int days = 7}) async {
    final now = DateTime.now().toUtc();
    final r = await _fetcher.getJson(
      url: 'https://ccmc.gsfc.nasa.gov/DONKI/WS/get/notifications',
      query: {
        'startDate': _day.format(now.subtract(Duration(days: days))),
        'endDate': _day.format(now),
        'type': 'all',
      },
      provenance: _p('NASA DONKI (CCMC)', 'https://ccmc.gsfc.nasa.gov/DONKI/'),
      ttl: const Duration(hours: 1),
      mockAsset: 'assets/mock/donki_notifications.json',
    );
    return r.map((j) {
      final list = [
        for (final o in ((j as List?) ?? const []).cast<Map<String, dynamic>>())
          SpaceWeatherNotice.fromJson(o),
      ]..sort((a, b) => b.issued.compareTo(a.issued));
      return list;
    });
  }

  /// NASA Image and Video Library search (no API key needed).
  Future<Sourced<List<NasaImage>>> searchImages(
    String query, {
    int pageSize = 24,
  }) async {
    final r = await _fetcher.getJson(
      url: 'https://images-api.nasa.gov/search',
      query: {'q': query, 'media_type': 'image', 'page_size': pageSize},
      provenance: _p(
        'NASA Image and Video Library',
        'https://images.nasa.gov/',
        note: 'Check each image for third-party copyright before reuse.',
      ),
      ttl: const Duration(days: 7),
      mockAsset: 'assets/mock/images_search.json',
    );
    return r.map((j) => NasaImage.listFromSearch(j as Map<String, dynamic>));
  }
}
