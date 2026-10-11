// Minimal, defensive models for the NASA endpoints we use. Fields the UI
// doesn't need are left out; parsing never throws on missing optional keys.

class Apod {
  const Apod({
    required this.date,
    required this.title,
    required this.explanation,
    required this.url,
    required this.mediaType,
    this.hdUrl,
    this.copyright,
    this.degraded = false,
  });

  /// Since APOD moved to science.nasa.gov (2026) the API scrapes the site
  /// chrome: title "NASA Science" and the NASA logo as the image, while the
  /// explanation is still correct. Detect that and degrade gracefully.
  factory Apod.fromJson(Map<String, dynamic> j) {
    final url = j['url'] as String? ?? '';
    final rawTitle = (j['title'] as String?)?.trim() ?? '';
    final degraded = url.contains('nasa-logo') || rawTitle == 'NASA Science';
    return Apod(
      date: j['date'] as String? ?? '',
      title: degraded || rawTitle.isEmpty
          ? 'Astronomy Picture of the Day'
          : rawTitle,
      explanation: j['explanation'] as String? ?? '',
      url: url,
      hdUrl: j['hdurl'] as String?,
      mediaType: j['media_type'] as String? ?? 'image',
      copyright: (j['copyright'] as String?)?.trim(),
      degraded: degraded,
    );
  }

  static const webPage = 'https://science.nasa.gov/apod/';

  final String date;
  final String title;
  final String explanation;
  final String url;
  final String? hdUrl;
  final String mediaType;

  /// Null means public domain (NASA); otherwise credit the holder.
  final String? copyright;

  /// True when the API returned site chrome instead of the real image/title.
  final bool degraded;

  bool get isImage => mediaType == 'image';
  bool get hasUsableImage => isImage && !degraded && url.isNotEmpty;
}

class NearEarthObject {
  const NearEarthObject({
    required this.id,
    required this.name,
    required this.diameterMinM,
    required this.diameterMaxM,
    required this.isPotentiallyHazardous,
    required this.closeApproach,
    required this.missDistanceKm,
    required this.missDistanceLunar,
    required this.velocityKmS,
    this.jplUrl,
  });

  factory NearEarthObject.fromJson(Map<String, dynamic> j) {
    final dia =
        (j['estimated_diameter'] as Map?)?['meters'] as Map? ?? const {};
    final ca = ((j['close_approach_data'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();
    final first = ca.isEmpty ? const <String, dynamic>{} : ca.first;
    double num0(Object? v) => v == null ? 0 : double.tryParse('$v') ?? 0;
    return NearEarthObject(
      id: '${j['id']}',
      name: (j['name'] as String? ?? '').replaceAll(RegExp(r'[()]'), '').trim(),
      jplUrl: j['nasa_jpl_url'] as String?,
      diameterMinM: num0(dia['estimated_diameter_min']),
      diameterMaxM: num0(dia['estimated_diameter_max']),
      isPotentiallyHazardous:
          j['is_potentially_hazardous_asteroid'] as bool? ?? false,
      closeApproach: first['epoch_date_close_approach'] == null
          ? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)
          : DateTime.fromMillisecondsSinceEpoch(
              (first['epoch_date_close_approach'] as num).toInt(),
              isUtc: true,
            ),
      missDistanceKm: num0((first['miss_distance'] as Map?)?['kilometers']),
      missDistanceLunar: num0((first['miss_distance'] as Map?)?['lunar']),
      velocityKmS: num0(
        (first['relative_velocity'] as Map?)?['kilometers_per_second'],
      ),
    );
  }

  final String id;
  final String name;
  final String? jplUrl;
  final double diameterMinM;
  final double diameterMaxM;
  final bool isPotentiallyHazardous;
  final DateTime closeApproach;
  final double missDistanceKm;
  final double missDistanceLunar;
  final double velocityKmS;
}

/// A DONKI space-weather notification (flares, CMEs, geomagnetic storms...).
class SpaceWeatherNotice {
  const SpaceWeatherNotice({
    required this.id,
    required this.type,
    required this.issued,
    required this.body,
    this.url,
  });

  factory SpaceWeatherNotice.fromJson(Map<String, dynamic> j) =>
      SpaceWeatherNotice(
        id: j['messageID'] as String? ?? '',
        type: j['messageType'] as String? ?? 'Report',
        issued:
            DateTime.tryParse(j['messageIssueTime'] as String? ?? '') ??
            DateTime(1970),
        body: j['messageBody'] as String? ?? '',
        url: j['messageURL'] as String?,
      );

  final String id;
  final String type;
  final DateTime issued;
  final String body;
  final String? url;

  String get typeLabel => switch (type) {
    'FLR' => 'Solar flare',
    'CME' => 'Coronal mass ejection',
    'GST' => 'Geomagnetic storm',
    'IPS' => 'Interplanetary shock',
    'SEP' => 'Solar energetic particles',
    'RBE' => 'Radiation belt enhancement',
    'MPC' => 'Magnetopause crossing',
    'Report' => 'Weekly report',
    _ => type,
  };
}

class NasaImage {
  const NasaImage({
    required this.nasaId,
    required this.title,
    required this.previewUrl,
    this.description,
    this.center,
    this.dateCreated,
  });

  final String nasaId;
  final String title;
  final String previewUrl;
  final String? description;
  final String? center;
  final DateTime? dateCreated;

  static List<NasaImage> listFromSearch(Map<String, dynamic> j) {
    final items = ((j['collection'] as Map?)?['items'] as List?) ?? const [];
    return [
      for (final it in items.cast<Map<String, dynamic>>())
        if (((it['data'] as List?) ?? const [])
                .cast<Map<String, dynamic>>()
                .firstOrNull
            case final d?)
          if (((it['links'] as List?) ?? const [])
                  .cast<Map<String, dynamic>>()
                  .firstOrNull
              case final l?)
            NasaImage(
              nasaId: d['nasa_id'] as String? ?? '',
              title: d['title'] as String? ?? '',
              description: d['description'] as String?,
              center: d['center'] as String?,
              dateCreated: DateTime.tryParse(
                d['date_created'] as String? ?? '',
              ),
              previewUrl: l['href'] as String? ?? '',
            ),
    ];
  }
}
