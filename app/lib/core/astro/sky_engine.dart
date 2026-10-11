import 'astro_time.dart';
import 'coordinates.dart';
import 'planets.dart';
import 'rise_set.dart';
import 'sky_catalog.dart';
import 'sun_moon.dart';

enum SkyObjectKind { sun, moon, planet, star }

enum Twilight { day, civil, nautical, astronomical, night }

extension TwilightLabel on Twilight {
  String get label => switch (this) {
    Twilight.day => 'Daytime',
    Twilight.civil => 'Civil twilight',
    Twilight.nautical => 'Nautical twilight',
    Twilight.astronomical => 'Astronomical twilight',
    Twilight.night => 'Dark night',
  };
}

Twilight twilightFor(double sunAltDeg) {
  if (sunAltDeg > Horizons.sun) return Twilight.day;
  if (sunAltDeg > Horizons.civilTwilight) return Twilight.civil;
  if (sunAltDeg > Horizons.nauticalTwilight) return Twilight.nautical;
  if (sunAltDeg > Horizons.astronomicalTwilight) return Twilight.astronomical;
  return Twilight.night;
}

/// A body placed in the observer's sky at one instant.
class SkyObject {
  const SkyObject({
    required this.id,
    required this.name,
    required this.kind,
    required this.equatorial,
    required this.horizontal,
    required this.magnitude,
    this.distanceKm,
    this.constellation,
    this.colorIndex,
    this.planet,
  });

  final String id;
  final String name;
  final SkyObjectKind kind;

  /// Apparent coordinates of date.
  final Equatorial equatorial;

  /// Topocentric, refracted azimuth/altitude.
  final Horizontal horizontal;
  final double magnitude;
  final double? distanceKm;
  final String? constellation;
  final double? colorIndex;
  final Planet? planet;

  bool get isAboveHorizon => horizontal.alt > 0;
}

class SkySnapshot {
  const SkySnapshot({
    required this.time,
    required this.observer,
    required this.objects,
    required this.moonPhase,
  });

  final DateTime time;
  final Observer observer;

  /// Sun, Moon, planets, then stars (brightest first).
  final List<SkyObject> objects;
  final MoonPhase moonPhase;

  SkyObject get sun => objects.firstWhere((o) => o.kind == SkyObjectKind.sun);
  SkyObject get moon => objects.firstWhere((o) => o.kind == SkyObjectKind.moon);
  Twilight get twilight => twilightFor(sun.horizontal.alt);

  Iterable<SkyObject> get aboveHorizon =>
      objects.where((o) => o.isAboveHorizon);

  SkyObject? byId(String id) => objects.where((o) => o.id == id).firstOrNull;
}

/// Facade over the astronomy modules. Pure Dart; safe to run in an isolate.
class SkyEngine {
  const SkyEngine(this.catalog);

  final SkyCatalog catalog;

  SkySnapshot compute(
    Observer observer,
    DateTime time, {
    double maxStarMagnitude = 5.5,
  }) {
    final jd = julianDate(time);
    final jdTT = julianDateTT(time);

    Horizontal place(Equatorial eq, {double? distanceKm}) {
      final h = equatorialToHorizontal(eq, observer, jd);
      var alt = h.alt;
      if (distanceKm != null) alt = topocentricAltitude(alt, distanceKm);
      return Horizontal(h.az, alt + refractionDeg(alt));
    }

    final sun = sunPosition(jdTT);
    final moon = moonPosition(jdTT);
    final objects = <SkyObject>[
      SkyObject(
        id: 'sun',
        name: 'Sun',
        kind: SkyObjectKind.sun,
        equatorial: sun.equatorial,
        horizontal: place(sun.equatorial),
        magnitude: -26.7,
        distanceKm: sun.distanceKm,
      ),
      SkyObject(
        id: 'moon',
        name: 'Moon',
        kind: SkyObjectKind.moon,
        equatorial: moon.equatorial,
        horizontal: place(moon.equatorial, distanceKm: moon.distanceKm),
        magnitude: -12.7,
        distanceKm: moon.distanceKm,
      ),
      for (final p in Planet.values)
        if (planetPosition(p, jdTT) case final pos)
          SkyObject(
            id: p.name,
            name: p.displayName,
            kind: SkyObjectKind.planet,
            equatorial: pos.equatorial,
            horizontal: place(pos.equatorial),
            magnitude: pos.magnitude,
            distanceKm: pos.distanceKm,
            planet: p,
          ),
      for (final s in catalog.stars)
        if (s.magnitude <= maxStarMagnitude)
          if (precessFromJ2000(s.position, jdTT) case final eq)
            SkyObject(
              id: s.id,
              name: s.displayName,
              kind: SkyObjectKind.star,
              equatorial: eq,
              horizontal: place(eq),
              magnitude: s.magnitude,
              constellation: s.constellation,
              colorIndex: s.colorIndex,
            ),
    ];

    return SkySnapshot(
      time: time,
      observer: observer,
      objects: objects,
      moonPhase: moonPhase(jdTT),
    );
  }

  /// Altitude function for rise/set searches. [id] is 'sun', 'moon', a
  /// [Planet.name], or a star id (e.g. 'HIP27989').
  AltitudeFn altitudeFn(String id, Observer observer) {
    final star = catalog.stars.where((s) => s.id == id).firstOrNull;
    final planet = Planet.values.where((p) => p.name == id).firstOrNull;
    return (DateTime t) {
      final jd = julianDate(t);
      final jdTT = julianDateTT(t);
      if (id == 'moon') {
        final m = moonPosition(jdTT);
        return topocentricAltitude(
          equatorialToHorizontal(m.equatorial, observer, jd).alt,
          m.distanceKm,
        );
      }
      final Equatorial eq;
      if (id == 'sun') {
        eq = sunPosition(jdTT).equatorial;
      } else if (planet != null) {
        eq = planetPosition(planet, jdTT).equatorial;
      } else if (star != null) {
        eq = precessFromJ2000(star.position, jdTT);
      } else {
        throw ArgumentError.value(id, 'id', 'Unknown sky object');
      }
      return equatorialToHorizontal(eq, observer, jd).alt;
    };
  }

  RiseSet riseSetFor(String id, Observer observer, DateTime start) => riseSet(
    altitudeFn(id, observer),
    start,
    horizonDeg: switch (id) {
      'sun' => Horizons.sun,
      'moon' => Horizons.moon,
      _ => Horizons.star,
    },
  );

  /// Times the Sun crosses a twilight threshold in the next 24 h (e.g.
  /// [Horizons.astronomicalTwilight] gives when true darkness begins/ends).
  List<HorizonCrossing> sunCrossings(
    Observer observer,
    DateTime start,
    double horizonDeg,
  ) => findCrossings(
    altitudeFn('sun', observer),
    start,
    start.add(const Duration(hours: 24)),
    horizonDeg: horizonDeg,
  );
}
