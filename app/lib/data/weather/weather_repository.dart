import '../../core/network/cached_fetcher.dart';
import '../../core/network/provenance.dart';

class HourlySky {
  const HourlySky({
    required this.time,
    required this.cloudCoverPct,
    required this.visibilityM,
    required this.humidityPct,
    required this.temperatureC,
  });

  final DateTime time;
  final double cloudCoverPct;
  final double visibilityM;
  final double humidityPct;
  final double temperatureC;

  /// Rough 0–1 "clear sky" score from clouds, haze and humidity. Not a
  /// seeing/transparency forecast — label it as an estimate in the UI.
  double get clearSkyScore {
    final cloud = 1 - (cloudCoverPct / 100);
    final vis = (visibilityM / 20000).clamp(0.0, 1.0);
    final hum = humidityPct > 90 ? 0.7 : 1.0;
    return (cloud * 0.75 + vis * 0.25) * hum;
  }
}

/// Open-Meteo forecast (free, no key, CC BY 4.0 — attribution required).
class WeatherRepository {
  WeatherRepository(this._fetcher);

  final CachedFetcher _fetcher;

  Future<Sourced<List<HourlySky>>> hourly(
    double lat,
    double lon, {
    int days = 2,
  }) async {
    final r = await _fetcher.getJson(
      url: 'https://api.open-meteo.com/v1/forecast',
      query: {
        'latitude': lat.toStringAsFixed(2),
        'longitude': lon.toStringAsFixed(2),
        'hourly': 'cloud_cover,visibility,relative_humidity_2m,temperature_2m',
        'forecast_days': days,
        'timezone': 'UTC',
      },
      provenance: DataProvenance(
        source: 'Open-Meteo',
        url: 'https://open-meteo.com/',
        license: 'CC BY 4.0',
        fetchedAt: DateTime.now(),
      ),
      ttl: const Duration(minutes: 30),
      mockAsset: 'assets/mock/open_meteo.json',
    );
    return r.map((j) {
      final h = (j as Map)['hourly'] as Map;
      final times = (h['time'] as List).cast<String>();
      double at(String k, int i) =>
          ((h[k] as List)[i] as num?)?.toDouble() ?? 0;
      return [
        for (var i = 0; i < times.length; i++)
          HourlySky(
            time: DateTime.parse('${times[i]}Z'),
            cloudCoverPct: at('cloud_cover', i),
            visibilityM: at('visibility', i),
            humidityPct: at('relative_humidity_2m', i),
            temperatureC: at('temperature_2m', i),
          ),
      ];
    });
  }
}
