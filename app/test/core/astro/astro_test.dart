// Reference values from Jean Meeus, "Astronomical Algorithms" (2nd ed.)
// worked examples, unless noted.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:skylens/core/astro/astro_math.dart';
import 'package:skylens/core/astro/astro_time.dart';
import 'package:skylens/core/astro/coordinates.dart';
import 'package:skylens/core/astro/planets.dart';
import 'package:skylens/core/astro/sky_catalog.dart';
import 'package:skylens/core/astro/sky_engine.dart';
import 'package:skylens/core/astro/sun_moon.dart';

double hms(num h, num m, num s) => (h + m / 60 + s / 3600) * 15;
double dms(num d, num m, num s) => d.sign * (d.abs() + m / 60 + s / 3600);

/// Julian Date of a TT instant expressed as a calendar date.
double jdOf(int y, int mo, int d, [int h = 0, int mi = 0, int s = 0]) =>
    julianDate(DateTime.utc(y, mo, d, h, mi, s));

void main() {
  group('time', () {
    test('Julian date (Meeus 7.a: 1957 Oct 4.81)', () {
      final jd = julianDate(DateTime.utc(1957, 10, 4, 19, 26, 24));
      expect(jd, closeTo(2436116.31, 1e-5));
    });

    test('round-trips through DateTime', () {
      final t = DateTime.utc(2026, 10, 11, 21, 30);
      // Doubles hold a JD to ~20 µs.
      expect(
        dateTimeFromJulian(julianDate(t)).difference(t).inMilliseconds.abs(),
        lessThan(1),
      );
    });

    test('GMST (Meeus 12.a: 1987 Apr 10 0h UT)', () {
      expect(
        gmstDegrees(jdOf(1987, 4, 10)),
        closeTo(hms(13, 10, 46.3668), 1e-5),
      );
    });
  });

  group('coordinates', () {
    test('equatorial -> horizontal (Meeus 13.b: Venus from Washington)', () {
      const obs = Observer(latitude: 38.921389, longitude: -77.065556);
      // Meeus uses apparent sidereal time; nutation in RA is ~0.001°.
      final eq = Equatorial(hms(23, 9, 16.641), dms(-6, 43, 11.61));
      final h = equatorialToHorizontal(eq, obs, jdOf(1987, 4, 10, 19, 21));
      expect(h.alt, closeTo(15.1249, 0.01));
      // Meeus measures azimuth from south; we measure from north.
      expect(h.az, closeTo(norm360(68.0337 + 180), 0.01));
    });

    test('horizontal -> equatorial is the inverse', () {
      const obs = Observer(latitude: 31.5, longitude: 74.3);
      final jd = jdOf(2026, 10, 11, 18);
      const eq = Equatorial(88.79, 7.41);
      final back = horizontalToEquatorial(
        equatorialToHorizontal(eq, obs, jd),
        obs,
        jd,
      );
      expect(back.ra, closeTo(eq.ra, 1e-6));
      expect(back.dec, closeTo(eq.dec, 1e-6));
    });

    test('precession (Meeus 21.b: θ Persei to 2028 Nov 13.19)', () {
      // Meeus applies proper motion first; these are the J2000 values with
      // proper motion for 28.86 y already added.
      final j2000 = Equatorial(
        hms(2, 44, 11.986) + 0.03425 * 28.86717 * 15 / 3600,
        dms(49, 13, 42.48) - 0.0895 * 28.86717 / 3600,
      );
      final jd = 2462088.69;
      final p = precessFromJ2000(j2000, jd);
      expect(p.ra, closeTo(41.547214, 1e-4));
      expect(p.dec, closeTo(49.348483, 1e-4));
    });

    test('ENU vector round-trip and compass points', () {
      const h = Horizontal(123.4, 56.7);
      final back = Horizontal.fromEnu(h.toEnu());
      expect(back.az, closeTo(h.az, 1e-9));
      expect(back.alt, closeTo(h.alt, 1e-9));
      expect(compassPointFor(0), 'N');
      expect(compassPointFor(359), 'N');
      expect(compassPointFor(135), 'SE');
      expect(compassPointFor(200), 'SSW');
    });

    test('refraction lifts a body at true altitude 0° by ~29 arcmin', () {
      // Saemundsson takes the true (airless) altitude; 34' is the figure for
      // an apparent altitude of 0°.
      expect(refractionDeg(0) * 60, closeTo(29.0, 0.5));
      expect(refractionDeg(90), closeTo(0, 0.001));
    });
  });

  group('sun and moon', () {
    test('Sun (Meeus 25.a: 1992 Oct 13 0h TD)', () {
      final s = sunPosition(2448908.5);
      expect(s.equatorial.ra, closeTo(198.38083, 0.01));
      expect(s.equatorial.dec, closeTo(-7.78507, 0.01));
      expect(s.distanceAu, closeTo(0.99766, 1e-4));
    });

    test('Moon (Meeus 47.a: 1992 Apr 12 0h TD)', () {
      final m = moonPosition(2448724.5);
      expect(m.eclipticLon, closeTo(133.167265, 0.02));
      expect(m.eclipticLat, closeTo(-3.229126, 0.02));
      expect(m.distanceKm, closeTo(368409.7, 30));
      expect(m.equatorial.ra, closeTo(134.688470, 0.03));
      expect(m.equatorial.dec, closeTo(13.768368, 0.03));
    });

    test('Moon phase (Meeus 48.a: 1992 Apr 12 0h TD, k = 0.6786)', () {
      final p = moonPhase(2448724.5);
      expect(p.illuminatedFraction, closeTo(0.6786, 0.005));
      expect(p.waxing, isTrue);
    });

    test('topocentric parallax lowers the Moon by up to ~1°', () {
      expect(topocentricAltitude(0, 384400), closeTo(-0.95, 0.02));
      expect(topocentricAltitude(90, 384400), closeTo(90, 1e-9));
    });
  });

  group('planets', () {
    test('Venus (Meeus 33.a: 1992 Dec 20 0h TD)', () {
      final v = planetPosition(Planet.venus, 2448976.5);
      expect(v.equatorial.ra, closeTo(hms(21, 4, 41.454), 0.05));
      expect(v.equatorial.dec, closeTo(dms(-18, 53, 16.84), 0.05));
      expect(v.distanceKm / auKm, closeTo(0.910947, 0.001));
      expect(v.magnitude, closeTo(-4.2, 0.2));
    });

    test('all planets have plausible magnitudes today', () {
      final jd = julianDateTT(DateTime.utc(2026, 10, 11));
      const ranges = {
        Planet.mercury: (-2.5, 6.0),
        Planet.venus: (-4.9, -3.7),
        Planet.mars: (-3.0, 2.0),
        Planet.jupiter: (-3.0, -1.5),
        Planet.saturn: (-0.6, 1.6),
        Planet.uranus: (5.3, 6.1),
        Planet.neptune: (7.6, 8.0),
      };
      for (final p in Planet.values) {
        final mag = planetPosition(p, jd).magnitude;
        final (lo, hi) = ranges[p]!;
        expect(mag, inInclusiveRange(lo, hi), reason: p.displayName);
      }
    });
  });

  group('rise/set', () {
    // Sun at Greenwich, 2026-06-21: sunrise 03:43 UTC, sunset 20:21 UTC
    // (timeanddate.com, rounded to the minute).
    const greenwich = Observer(latitude: 51.4769, longitude: 0);
    final engine = SkyEngine(SkyCatalog.empty);

    test('sunrise and sunset at Greenwich on the solstice', () {
      final rs = engine.riseSetFor('sun', greenwich, DateTime.utc(2026, 6, 21));
      expect(
        rs.rise!.difference(DateTime.utc(2026, 6, 21, 3, 43)).inSeconds.abs(),
        lessThan(120),
      );
      expect(
        rs.set!.difference(DateTime.utc(2026, 6, 21, 20, 21)).inSeconds.abs(),
        lessThan(120),
      );
      expect(rs.transitAltitude, closeTo(90 - 51.4769 + 23.44, 0.1));
    });

    test('midnight sun is reported as always up', () {
      const tromso = Observer(latitude: 69.65, longitude: 18.96);
      final rs = engine.riseSetFor('sun', tromso, DateTime.utc(2026, 6, 21));
      expect(rs.alwaysUp, isTrue);
      expect(rs.rise, isNull);
    });

    test('twilight classification', () {
      expect(twilightFor(10), Twilight.day);
      expect(twilightFor(-3), Twilight.civil);
      expect(twilightFor(-15), Twilight.astronomical);
      expect(twilightFor(-30), Twilight.night);
    });
  });

  group('catalog + engine', () {
    late SkyCatalog catalog;
    setUpAll(() {
      catalog = SkyCatalog.fromJson(
        File('assets/catalog/stars.json').readAsStringSync(),
        File('assets/catalog/constellations.json').readAsStringSync(),
      );
    });

    test('bundled catalog loads', () {
      expect(catalog.stars.length, greaterThan(2500));
      expect(catalog.constellations.length, greaterThanOrEqualTo(88));
      expect(catalog.starByName('Sirius')!.magnitude, closeTo(-1.44, 0.01));
      expect(
        catalog.constellations.firstWhere((c) => c.id == 'Ori').name,
        'Orion',
      );
    });

    test('Polaris sits at altitude ≈ latitude, due north', () {
      const obs = Observer(latitude: 31.52, longitude: 74.36); // Lahore
      final snap = SkyEngine(catalog)
          .compute(obs, DateTime.utc(2026, 10, 11, 18));
      final polaris = snap.objects.firstWhere((o) => o.name == 'Polaris');
      expect(polaris.horizontal.alt, closeTo(31.52, 1.0));
      expect(norm180(polaris.horizontal.az), closeTo(0, 1.5));
      expect(snap.objects.first.kind, SkyObjectKind.sun);
    });

    test('snapshot runs fast enough for a 1 Hz AR refresh', () {
      final engine = SkyEngine(catalog);
      const obs = Observer(latitude: 40.7, longitude: -74);
      final sw = Stopwatch()..start();
      for (var i = 0; i < 10; i++) {
        engine.compute(obs, DateTime.utc(2026, 10, 11, 2, i));
      }
      expect(sw.elapsedMilliseconds / 10, lessThan(100));
    });
  });
}
