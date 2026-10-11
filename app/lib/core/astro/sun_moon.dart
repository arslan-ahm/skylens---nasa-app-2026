import 'dart:math' as math;

import 'astro_math.dart';
import 'astro_time.dart';
import 'coordinates.dart';

const double auKm = 149597870.7;
const double earthRadiusKm = 6378.14;

/// Geocentric apparent position of a Solar System body of date.
class BodyPosition {
  const BodyPosition({
    required this.equatorial,
    required this.eclipticLon,
    required this.eclipticLat,
    required this.distanceKm,
  });

  final Equatorial equatorial;
  final double eclipticLon;
  final double eclipticLat;
  final double distanceKm;

  double get distanceAu => distanceKm / auKm;
}

/// Nutation in longitude and obliquity, degrees (Meeus ch. 22, low accuracy,
/// ~0.5" in Δψ). Returns (dPsi, dEps).
(double, double) nutation(double jdTT) {
  final t = julianCenturies(jdTT);
  final omega = 125.04452 - 1934.136261 * t;
  final lSun = 280.4665 + 36000.7698 * t;
  final lMoon = 218.3165 + 481267.8813 * t;
  final dPsi =
      (-17.20 * sinD(omega) -
          1.32 * sinD(2 * lSun) -
          0.23 * sinD(2 * lMoon) +
          0.21 * sinD(2 * omega)) /
      3600;
  final dEps =
      (9.20 * cosD(omega) +
          0.57 * cosD(2 * lSun) +
          0.10 * cosD(2 * lMoon) -
          0.09 * cosD(2 * omega)) /
      3600;
  return (dPsi, dEps);
}

/// Apparent geocentric Sun, accurate to ~0.01° (Meeus ch. 25).
BodyPosition sunPosition(double jdTT) {
  final t = julianCenturies(jdTT);
  final l0 = 280.46646 + 36000.76983 * t + 0.0003032 * t * t;
  final m = 357.52911 + 35999.05029 * t - 0.0001537 * t * t;
  final e = 0.016708634 - 0.000042037 * t - 0.0000001267 * t * t;
  final c =
      (1.914602 - 0.004817 * t - 0.000014 * t * t) * sinD(m) +
      (0.019993 - 0.000101 * t) * sinD(2 * m) +
      0.000289 * sinD(3 * m);
  final trueLon = l0 + c;
  final nu = m + c;
  final rAu = 1.000001018 * (1 - e * e) / (1 + e * cosD(nu));
  final omega = 125.04 - 1934.136 * t;
  final lambda = norm360(trueLon - 0.00569 - 0.00478 * sinD(omega));
  final eps = meanObliquity(jdTT) + 0.00256 * cosD(omega);
  return BodyPosition(
    equatorial: eclipticToEquatorial(lambda, 0, eps),
    eclipticLon: lambda,
    eclipticLat: 0,
    distanceKm: rAu * auKm,
  );
}

// Meeus table 47.A: D, M, M', F, Σl (1e-6 deg), Σr (1e-3 km).
const _moonLr = <List<int>>[
  [0, 0, 1, 0, 6288774, -20905355],
  [2, 0, -1, 0, 1274027, -3699111],
  [2, 0, 0, 0, 658314, -2955968],
  [0, 0, 2, 0, 213618, -569925],
  [0, 1, 0, 0, -185116, 48888],
  [0, 0, 0, 2, -114332, -3149],
  [2, 0, -2, 0, 58793, 246158],
  [2, -1, -1, 0, 57066, -152138],
  [2, 0, 1, 0, 53322, -170733],
  [2, -1, 0, 0, 45758, -204586],
  [0, 1, -1, 0, -40923, -129620],
  [1, 0, 0, 0, -34720, 108743],
  [0, 1, 1, 0, -30383, 104755],
  [2, 0, 0, -2, 15327, 10321],
  [0, 0, 1, 2, -12528, 0],
  [0, 0, 1, -2, 10980, 79661],
  [4, 0, -1, 0, 10675, -34782],
  [0, 0, 3, 0, 10034, -23210],
  [4, 0, -2, 0, 8548, -21636],
  [2, 1, -1, 0, -7888, 24208],
  [2, 1, 0, 0, -6766, 30824],
  [1, 0, -1, 0, -5163, -8379],
  [1, 1, 0, 0, 4987, -16675],
  [2, -1, 1, 0, 4036, -12831],
  [2, 0, 2, 0, 3994, -10445],
  [4, 0, 0, 0, 3861, -11650],
  [2, 0, -3, 0, 3665, 14403],
  [0, 1, -2, 0, -2689, -7003],
  [2, 0, -1, 2, -2602, 0],
  [2, -1, -2, 0, 2390, 10056],
  [1, 0, 1, 0, -2348, 6322],
  [2, -2, 0, 0, 2236, -9884],
];

// Meeus table 47.B: D, M, M', F, Σb (1e-6 deg).
const _moonB = <List<int>>[
  [0, 0, 0, 1, 5128122],
  [0, 0, 1, 1, 280602],
  [0, 0, 1, -1, 277693],
  [2, 0, 0, -1, 173237],
  [2, 0, -1, 1, 55413],
  [2, 0, -1, -1, 46271],
  [2, 0, 0, 1, 32573],
  [0, 0, 2, 1, 17198],
  [2, 0, 1, -1, 9266],
  [0, 0, 2, -1, 8822],
  [2, -1, 0, -1, 8216],
  [2, 0, -2, -1, 4324],
  [2, 0, 1, 1, 4200],
  [2, 1, 0, -1, -3359],
  [2, -1, -1, 1, 2463],
  [2, -1, 0, 1, 2211],
  [2, -1, -1, -1, 2065],
  [0, 1, -1, -1, -1870],
  [4, 0, -1, -1, 1828],
  [0, 1, 0, 1, -1794],
];

/// Apparent geocentric Moon using the main terms of Meeus ch. 47
/// (~0.01–0.05° accuracy). Apply [topocentricAltitude] for the observer.
BodyPosition moonPosition(double jdTT) {
  final t = julianCenturies(jdTT);
  final t2 = t * t, t3 = t2 * t, t4 = t3 * t;
  final lp =
      218.3164477 +
      481267.88123421 * t -
      0.0015786 * t2 +
      t3 / 538841 -
      t4 / 65194000;
  final d =
      297.8501921 +
      445267.1114034 * t -
      0.0018819 * t2 +
      t3 / 545868 -
      t4 / 113065000;
  final m = 357.5291092 + 35999.0502909 * t - 0.0001536 * t2 + t3 / 24490000;
  final mp =
      134.9633964 +
      477198.8675055 * t +
      0.0087414 * t2 +
      t3 / 69699 -
      t4 / 14712000;
  final f =
      93.2720950 +
      483202.0175233 * t -
      0.0036539 * t2 -
      t3 / 3526000 +
      t4 / 863310000;
  final a1 = 119.75 + 131.849 * t;
  final a2 = 53.09 + 479264.290 * t;
  final a3 = 313.45 + 481266.484 * t;
  final e = 1 - 0.002516 * t - 0.0000074 * t2;

  double eFactor(int mCoeff) =>
      mCoeff.abs() == 1 ? e : (mCoeff.abs() == 2 ? e * e : 1);

  var sl = 0.0, sr = 0.0, sb = 0.0;
  for (final row in _moonLr) {
    final arg = row[0] * d + row[1] * m + row[2] * mp + row[3] * f;
    final k = eFactor(row[1]);
    sl += row[4] * k * sinD(arg);
    sr += row[5] * k * cosD(arg);
  }
  for (final row in _moonB) {
    final arg = row[0] * d + row[1] * m + row[2] * mp + row[3] * f;
    sb += row[4] * eFactor(row[1]) * sinD(arg);
  }
  sl += 3958 * sinD(a1) + 1962 * sinD(lp - f) + 318 * sinD(a2);
  sb +=
      -2235 * sinD(lp) +
      382 * sinD(a3) +
      175 * sinD(a1 - f) +
      175 * sinD(a1 + f) +
      127 * sinD(lp - mp) -
      115 * sinD(lp + mp);

  final (dPsi, dEps) = nutation(jdTT);
  final lambda = norm360(lp + sl / 1e6 + dPsi);
  final beta = sb / 1e6;
  final eps = meanObliquity(jdTT) + dEps;
  return BodyPosition(
    equatorial: eclipticToEquatorial(lambda, beta, eps),
    eclipticLon: lambda,
    eclipticLat: beta,
    distanceKm: 385000.56 + sr / 1000,
  );
}

/// Corrects a geocentric altitude for parallax (essential for the Moon,
/// up to ~1°). Uses the spherical-Earth approximation.
double topocentricAltitude(double geocentricAltDeg, double distanceKm) {
  final hp = asinD(earthRadiusKm / distanceKm);
  return geocentricAltDeg - asinD(sinD(hp) * cosD(geocentricAltDeg));
}

class MoonPhase {
  const MoonPhase({
    required this.illuminatedFraction,
    required this.elongationDeg,
    required this.waxing,
  });

  /// 0 = new, 1 = full.
  final double illuminatedFraction;

  /// Sun–Moon ecliptic longitude difference in [0, 360): 0 new, 180 full.
  final double elongationDeg;
  final bool waxing;

  /// Age-like progress through the lunation, 0..1.
  double get cycle => elongationDeg / 360;

  String get name {
    final e = elongationDeg;
    if (e < 10 || e >= 350) return 'New Moon';
    if (e < 80) return 'Waxing Crescent';
    if (e < 100) return 'First Quarter';
    if (e < 170) return 'Waxing Gibbous';
    if (e < 190) return 'Full Moon';
    if (e < 260) return 'Waning Gibbous';
    if (e < 280) return 'Last Quarter';
    return 'Waning Crescent';
  }
}

/// Moon phase from the geocentric Sun and Moon (Meeus ch. 48).
MoonPhase moonPhase(double jdTT) {
  final sun = sunPosition(jdTT);
  final moon = moonPosition(jdTT);
  final psi = acosD(
    cosD(moon.eclipticLat) * cosD(moon.eclipticLon - sun.eclipticLon),
  );
  final i = atan2D(
    sun.distanceKm * sinD(psi),
    moon.distanceKm - sun.distanceKm * cosD(psi),
  );
  final elong = norm360(moon.eclipticLon - sun.eclipticLon);
  return MoonPhase(
    illuminatedFraction: (1 + cosD(i)) / 2,
    elongationDeg: elong,
    waxing: elong < 180,
  );
}

/// Apparent angular diameter in degrees for a body of [radiusKm].
double angularDiameterDeg(double radiusKm, double distanceKm) =>
    2 * math.asin(radiusKm / distanceKm) * rad2deg;
