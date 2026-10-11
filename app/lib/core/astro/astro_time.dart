import 'astro_math.dart';

/// Julian Date for J2000.0 (2000-01-01 12:00 TT).
const double jdJ2000 = 2451545.0;

/// Julian Date of a UTC instant (Meeus ch. 7, via the Unix epoch).
double julianDate(DateTime time) =>
    time.toUtc().microsecondsSinceEpoch / 86400e6 + 2440587.5;

DateTime dateTimeFromJulian(double jd) => DateTime.fromMicrosecondsSinceEpoch(
  ((jd - 2440587.5) * 86400e6).round(),
  isUtc: true,
);

/// Approximate TT - UT in seconds. ~69 s around 2020-2030; good to a second,
/// which is far below the accuracy of everything that uses it.
double deltaTSeconds(DateTime time) {
  final y = time.toUtc().year + (time.toUtc().month - 0.5) / 12;
  final t = y - 2000;
  // Espenak & Meeus polynomial, valid 2005-2050.
  return 62.92 + 0.32217 * t + 0.005589 * t * t;
}

/// Julian Date in Terrestrial Time, used for planetary/lunar theories.
double julianDateTT(DateTime time) =>
    julianDate(time) + deltaTSeconds(time) / 86400;

/// Julian centuries since J2000.0 for a given Julian Date.
double julianCenturies(double jd) => (jd - jdJ2000) / 36525;

/// Greenwich mean sidereal time in degrees (Meeus 12.4).
double gmstDegrees(double jdUt) {
  final t = julianCenturies(jdUt);
  return norm360(
    280.46061837 +
        360.98564736629 * (jdUt - jdJ2000) +
        0.000387933 * t * t -
        t * t * t / 38710000,
  );
}

/// Local mean sidereal time in degrees; [longitudeDeg] is east-positive.
double lstDegrees(double jdUt, double longitudeDeg) =>
    norm360(gmstDegrees(jdUt) + longitudeDeg);
