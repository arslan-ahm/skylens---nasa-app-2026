import 'astro_math.dart';
import 'astro_time.dart';

/// Where the observer stands. Longitude is east-positive (degrees).
class Observer {
  const Observer({
    required this.latitude,
    required this.longitude,
    this.elevationM = 0,
  });

  final double latitude;
  final double longitude;
  final double elevationM;

  @override
  String toString() =>
      'Observer(${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})';
}

/// Right ascension / declination in degrees.
class Equatorial {
  const Equatorial(this.ra, this.dec);

  final double ra;
  final double dec;

  double get raHours => ra / 15;

  @override
  String toString() =>
      'Equatorial(ra: ${ra.toStringAsFixed(4)}°, dec: ${dec.toStringAsFixed(4)}°)';
}

/// Azimuth (degrees from true north, clockwise) and altitude above the horizon.
class Horizontal {
  const Horizontal(this.az, this.alt);

  final double az;
  final double alt;

  bool get isAboveHorizon => alt > 0;

  /// Unit vector in a local East-North-Up frame.
  Vec3 toEnu() {
    final c = cosD(alt);
    return Vec3(c * sinD(az), c * cosD(az), sinD(alt));
  }

  static Horizontal fromEnu(Vec3 v) {
    final n = v.normalized();
    return Horizontal(norm360(atan2D(n.x, n.y)), asinD(n.z));
  }

  /// 16-point compass name for the azimuth, e.g. "SSE".
  String get compassPoint => compassPointFor(az);

  @override
  String toString() =>
      'Horizontal(az: ${az.toStringAsFixed(3)}°, alt: ${alt.toStringAsFixed(3)}°)';
}

const _points = [
  'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', //
  'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW',
];

String compassPointFor(double azDeg) =>
    _points[((norm360(azDeg) + 11.25) / 22.5).floor() % 16];

/// Converts equatorial coordinates (of date) to horizontal for an observer.
Horizontal equatorialToHorizontal(Equatorial eq, Observer obs, double jdUt) {
  final ha = lstDegrees(jdUt, obs.longitude) - eq.ra;
  final lat = obs.latitude;
  final alt = asinD(
    sinD(lat) * sinD(eq.dec) + cosD(lat) * cosD(eq.dec) * cosD(ha),
  );
  // Azimuth measured from north through east.
  final az = atan2D(
    -cosD(eq.dec) * sinD(ha),
    sinD(eq.dec) * cosD(lat) - cosD(eq.dec) * sinD(lat) * cosD(ha),
  );
  return Horizontal(norm360(az), alt);
}

/// Inverse of [equatorialToHorizontal].
Equatorial horizontalToEquatorial(Horizontal hz, Observer obs, double jdUt) {
  final lat = obs.latitude;
  final dec = asinD(
    sinD(lat) * sinD(hz.alt) + cosD(lat) * cosD(hz.alt) * cosD(hz.az),
  );
  final ha = atan2D(
    -sinD(hz.az) * cosD(hz.alt),
    sinD(hz.alt) * cosD(lat) - cosD(hz.alt) * sinD(lat) * cosD(hz.az),
  );
  return Equatorial(norm360(lstDegrees(jdUt, obs.longitude) - ha), dec);
}

/// Mean obliquity of the ecliptic in degrees (Meeus 22.2).
double meanObliquity(double jdTT) {
  final t = julianCenturies(jdTT);
  return 23.4392911 -
      0.0130041667 * t -
      1.6389e-7 * t * t +
      5.0361e-7 * t * t * t;
}

Equatorial eclipticToEquatorial(double lonDeg, double latDeg, double epsDeg) {
  final ra = atan2D(
    sinD(lonDeg) * cosD(epsDeg) - tanD(latDeg) * sinD(epsDeg),
    cosD(lonDeg),
  );
  final dec = asinD(
    sinD(latDeg) * cosD(epsDeg) + cosD(latDeg) * sinD(epsDeg) * sinD(lonDeg),
  );
  return Equatorial(norm360(ra), dec);
}

/// Precesses J2000.0 mean coordinates to the mean equinox of [jdTT]
/// (Meeus 21.2/21.4, IAU 1976). Needed because ~26 years of precession
/// already shifts stars by ~0.35°.
Equatorial precessFromJ2000(Equatorial eq, double jdTT) {
  final t = julianCenturies(jdTT);
  final zeta = (2306.2181 * t + 0.30188 * t * t + 0.017998 * t * t * t) / 3600;
  final z = (2306.2181 * t + 1.09468 * t * t + 0.018203 * t * t * t) / 3600;
  final theta = (2004.3109 * t - 0.42665 * t * t - 0.041833 * t * t * t) / 3600;

  final a = cosD(eq.dec) * sinD(eq.ra + zeta);
  final b =
      cosD(theta) * cosD(eq.dec) * cosD(eq.ra + zeta) -
      sinD(theta) * sinD(eq.dec);
  final c =
      sinD(theta) * cosD(eq.dec) * cosD(eq.ra + zeta) +
      cosD(theta) * sinD(eq.dec);
  return Equatorial(norm360(atan2D(a, b) + z), asinD(c));
}

/// Great-circle separation between two directions, in degrees.
double angularSeparation(Equatorial a, Equatorial b) => acosD(
  sinD(a.dec) * sinD(b.dec) + cosD(a.dec) * cosD(b.dec) * cosD(a.ra - b.ra),
);

/// Standard atmospheric refraction (Bennett/Saemundsson), degrees to add to a
/// geometric altitude. Matters near the horizon (~0.5° at 0°).
double refractionDeg(double altDeg) {
  if (altDeg < -1.9) return 0;
  return 1.02 / tanD(altDeg + 10.3 / (altDeg + 5.11)) / 60;
}
