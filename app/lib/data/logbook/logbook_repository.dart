import 'package:hive_ce/hive_ce.dart';

/// One observing-log entry. Stored as a plain map so it can be exported as
/// JSON/CSV or synced to a backend later without migrations.
class Observation {
  const Observation({
    required this.id,
    required this.time,
    required this.target,
    required this.latitude,
    required this.longitude,
    this.notes = '',
    this.azimuth,
    this.altitude,
    this.skyQuality,
    this.equipment,
    this.photoPath,
  });

  factory Observation.fromMap(Map<dynamic, dynamic> m) => Observation(
    id: m['id'] as String,
    time: DateTime.parse(m['time'] as String),
    target: m['target'] as String,
    latitude: (m['lat'] as num).toDouble(),
    longitude: (m['lon'] as num).toDouble(),
    notes: m['notes'] as String? ?? '',
    azimuth: (m['az'] as num?)?.toDouble(),
    altitude: (m['alt'] as num?)?.toDouble(),
    skyQuality: m['sky'] as int?,
    equipment: m['equipment'] as String?,
    photoPath: m['photo'] as String?,
  );

  final String id;
  final DateTime time;

  /// What was observed, e.g. "Jupiter" or "Bright meteor".
  final String target;
  final double latitude;
  final double longitude;
  final String notes;
  final double? azimuth;
  final double? altitude;

  /// 1 (poor) – 5 (excellent), user-rated.
  final int? skyQuality;

  /// "Naked eye", "10x50 binoculars", "8\" Dobsonian"...
  final String? equipment;
  final String? photoPath;

  Map<String, dynamic> toMap() => {
    'id': id,
    'time': time.toUtc().toIso8601String(),
    'target': target,
    'lat': latitude,
    'lon': longitude,
    'notes': notes,
    'az': ?azimuth,
    'alt': ?altitude,
    'sky': ?skyQuality,
    'equipment': ?equipment,
    'photo': ?photoPath,
  };
}

class LogbookRepository {
  LogbookRepository(this._box);

  final Box<dynamic> _box;

  List<Observation> all() =>
      _box.values.map((v) => Observation.fromMap(v as Map)).toList()
        ..sort((a, b) => b.time.compareTo(a.time));

  Future<void> save(Observation o) => _box.put(o.id, o.toMap());

  Future<void> delete(String id) => _box.delete(id);

  Stream<List<Observation>> watch() async* {
    yield all();
    await for (final _ in _box.watch()) {
      yield all();
    }
  }

  /// CSV export (for sharing or citizen-science submissions).
  String toCsv() {
    String esc(Object? v) => '"${'${v ?? ''}'.replaceAll('"', '""')}"';
    final rows = [
      'time_utc,target,lat,lon,az,alt,sky_quality,equipment,notes',
      for (final o in all())
        [
          o.time.toUtc().toIso8601String(),
          o.target,
          o.latitude.toStringAsFixed(4),
          o.longitude.toStringAsFixed(4),
          o.azimuth?.toStringAsFixed(1),
          o.altitude?.toStringAsFixed(1),
          o.skyQuality,
          o.equipment,
          o.notes,
        ].map(esc).join(','),
    ];
    return rows.join('\n');
  }
}
