import 'dart:math' as math;

import 'astro_math.dart';
import 'astro_time.dart';
import 'coordinates.dart';
import 'sun_moon.dart';

enum Planet { mercury, venus, mars, jupiter, saturn, uranus, neptune }

extension PlanetInfo on Planet {
  String get displayName => switch (this) {
    Planet.mercury => 'Mercury',
    Planet.venus => 'Venus',
    Planet.mars => 'Mars',
    Planet.jupiter => 'Jupiter',
    Planet.saturn => 'Saturn',
    Planet.uranus => 'Uranus',
    Planet.neptune => 'Neptune',
  };

  double get radiusKm => switch (this) {
    Planet.mercury => 2439.7,
    Planet.venus => 6051.8,
    Planet.mars => 3389.5,
    Planet.jupiter => 69911,
    Planet.saturn => 58232,
    Planet.uranus => 25362,
    Planet.neptune => 24622,
  };
}

/// JPL "Approximate Positions of the Planets" (E.M. Standish), table 1,
/// valid 1800–2050: a, e, I, L, long.peri, long.node and their rates per
/// Julian century. Accuracy is a few arcminutes — fine for naked-eye use.
const _elements = <String, List<double>>{
  'mercury': [
    0.38709927,
    0.20563593,
    7.00497902,
    252.25032350,
    77.45779628,
    48.33076593, //
    0.00000037,
    0.00001906,
    -0.00594749,
    149472.67411175,
    0.16047689,
    -0.12534081,
  ],
  'venus': [
    0.72333566,
    0.00677672,
    3.39467605,
    181.97909950,
    131.60246718,
    76.67984255, //
    0.00000390,
    -0.00004107,
    -0.00078890,
    58517.81538729,
    0.00268329,
    -0.27769418,
  ],
  'earth': [
    1.00000261, 0.01671123, -0.00001531, 100.46457166, 102.93768193, 0.0, //
    0.00000562, -0.00004392, -0.01294668, 35999.37244981, 0.32327364, 0.0,
  ],
  'mars': [
    1.52371034,
    0.09339410,
    1.84969142,
    -4.55343205,
    -23.94362959,
    49.55953891, //
    0.00001847,
    0.00007882,
    -0.00813131,
    19140.30268499,
    0.44441088,
    -0.29257343,
  ],
  'jupiter': [
    5.20288700,
    0.04838624,
    1.30439695,
    34.39644051,
    14.72847983,
    100.47390909, //
    -0.00011607,
    -0.00013253,
    -0.00183714,
    3034.74612775,
    0.21252668,
    0.20469106,
  ],
  'saturn': [
    9.53667594,
    0.05386179,
    2.48599187,
    49.95424423,
    92.59887831,
    113.66242448, //
    -0.00125060,
    -0.00050991,
    0.00193609,
    1222.49362201,
    -0.41897216,
    -0.28867794,
  ],
  'uranus': [
    19.18916464,
    0.04725744,
    0.77263783,
    313.23810451,
    170.95427630,
    74.01692503, //
    -0.00196176, -0.00004397, -0.00242939, 428.48202785, 0.40805281, 0.04240589,
  ],
  'neptune': [
    30.06992276,
    0.00859048,
    1.77004347,
    -55.12002969,
    44.96476227,
    131.78422574, //
    0.00026291, 0.00005105, 0.00035372, 218.45945325, -0.32241464, -0.01262724,
  ],
};

/// Heliocentric ecliptic J2000 position in AU.
Vec3 heliocentricJ2000(String body, double jdTT) {
  final el = _elements[body]!;
  final t = julianCenturies(jdTT);
  final a = el[0] + el[6] * t;
  final e = el[1] + el[7] * t;
  final inc = el[2] + el[8] * t;
  final l = el[3] + el[9] * t;
  final peri = el[4] + el[10] * t;
  final node = el[5] + el[11] * t;

  final w = peri - node;
  final mAnom = norm180(l - peri) * deg2rad;
  // Kepler's equation by Newton iteration.
  var ecc = mAnom + e * math.sin(mAnom);
  for (var i = 0; i < 10; i++) {
    final dE = (ecc - e * math.sin(ecc) - mAnom) / (1 - e * math.cos(ecc));
    ecc -= dE;
    if (dE.abs() < 1e-12) break;
  }
  final xp = a * (math.cos(ecc) - e);
  final yp = a * math.sqrt(1 - e * e) * math.sin(ecc);

  final cw = cosD(w), sw = sinD(w), cn = cosD(node), sn = sinD(node);
  final ci = cosD(inc), si = sinD(inc);
  return Vec3(
    (cw * cn - sw * sn * ci) * xp + (-sw * cn - cw * sn * ci) * yp,
    (cw * sn + sw * cn * ci) * xp + (-sw * sn + cw * cn * ci) * yp,
    (sw * si) * xp + (cw * si) * yp,
  );
}

class PlanetPosition extends BodyPosition {
  const PlanetPosition({
    required super.equatorial,
    required super.eclipticLon,
    required super.eclipticLat,
    required super.distanceKm,
    required this.planet,
    required this.sunDistanceAu,
    required this.phaseAngleDeg,
    required this.magnitude,
  });

  final Planet planet;
  final double sunDistanceAu;
  final double phaseAngleDeg;
  final double magnitude;

  double get illuminatedFraction => (1 + cosD(phaseAngleDeg)) / 2;
}

const _lightTimeDaysPerAu = 0.0057755183;
const _obliquityJ2000 = 23.4392911;

/// Apparent-ish geocentric position of a planet, precessed to date and
/// corrected for light time. Ignores aberration/nutation (< 0.01°).
PlanetPosition planetPosition(Planet planet, double jdTT) {
  final earth = heliocentricJ2000('earth', jdTT);
  var helio = heliocentricJ2000(planet.name, jdTT);
  var geo = helio - earth;
  final lightTime = geo.length * _lightTimeDaysPerAu;
  helio = heliocentricJ2000(planet.name, jdTT - lightTime);
  geo = helio - earth;

  final delta = geo.length;
  final r = helio.length;
  final rEarth = earth.length;
  final lon = norm360(atan2D(geo.y, geo.x));
  final lat = asinD(geo.z / delta);
  final j2000 = eclipticToEquatorial(lon, lat, _obliquityJ2000);
  final phase = acosD(
    (r * r + delta * delta - rEarth * rEarth) / (2 * r * delta),
  );

  return PlanetPosition(
    planet: planet,
    equatorial: precessFromJ2000(j2000, jdTT),
    eclipticLon: lon,
    eclipticLat: lat,
    distanceKm: delta * auKm,
    sunDistanceAu: r,
    phaseAngleDeg: phase,
    magnitude: _magnitude(planet, r, delta, phase),
  );
}

/// Visual magnitude (Meeus ch. 41, Müller-style formulas; Saturn ignores
/// ring tilt, so it can be off by up to ~1 mag when the rings are open).
double _magnitude(Planet p, double r, double delta, double i) {
  final base = 5 * math.log(r * delta) / math.ln10;
  return switch (p) {
    Planet.mercury =>
      -0.42 + base + 0.0380 * i - 0.000273 * i * i + 0.000002 * i * i * i,
    Planet.venus =>
      -4.40 + base + 0.0009 * i + 0.000239 * i * i - 0.00000065 * i * i * i,
    Planet.mars => -1.52 + base + 0.016 * i,
    Planet.jupiter => -9.40 + base + 0.005 * i,
    Planet.saturn => -8.88 + base + 0.044 * i,
    Planet.uranus => -7.19 + base,
    Planet.neptune => -6.87 + base,
  };
}
