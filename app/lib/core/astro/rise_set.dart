/// Generic horizon-crossing solver: works for any body given a function that
/// returns its altitude (degrees) at an instant.
typedef AltitudeFn = double Function(DateTime time);

/// Standard horizon altitudes (refraction + semi-diameter).
abstract final class Horizons {
  static const double sun = -0.833;
  static const double moon = 0.125; // includes mean parallax + semi-diameter
  static const double star = -0.5667;
  static const double civilTwilight = -6;
  static const double nauticalTwilight = -12;
  static const double astronomicalTwilight = -18;
}

class HorizonCrossing {
  const HorizonCrossing(this.time, {required this.rising});

  final DateTime time;
  final bool rising;
}

class RiseSet {
  const RiseSet({
    this.rise,
    this.set,
    required this.transit,
    required this.transitAltitude,
    required this.alwaysUp,
    required this.alwaysDown,
  });

  final DateTime? rise;
  final DateTime? set;
  final DateTime transit;
  final double transitAltitude;
  final bool alwaysUp;
  final bool alwaysDown;
}

/// All crossings of [horizonDeg] between [start] and [end], refined by
/// bisection to [precision].
List<HorizonCrossing> findCrossings(
  AltitudeFn altitude,
  DateTime start,
  DateTime end, {
  double horizonDeg = Horizons.star,
  Duration step = const Duration(minutes: 10),
  Duration precision = const Duration(seconds: 20),
}) {
  final out = <HorizonCrossing>[];
  var t0 = start;
  var a0 = altitude(t0) - horizonDeg;
  while (t0.isBefore(end)) {
    var t1 = t0.add(step);
    if (t1.isAfter(end)) t1 = end;
    final a1 = altitude(t1) - horizonDeg;
    if ((a0 <= 0) != (a1 <= 0)) {
      var lo = t0, hi = t1;
      var aLo = a0;
      while (hi.difference(lo) > precision) {
        final mid = lo.add(hi.difference(lo) ~/ 2);
        final aMid = altitude(mid) - horizonDeg;
        if ((aLo <= 0) == (aMid <= 0)) {
          lo = mid;
          aLo = aMid;
        } else {
          hi = mid;
        }
      }
      out.add(HorizonCrossing(lo.add(hi.difference(lo) ~/ 2), rising: a1 > 0));
    }
    t0 = t1;
    a0 = a1;
  }
  return out;
}

/// Next rise and set within 24 h of [start], plus the highest point.
RiseSet riseSet(
  AltitudeFn altitude,
  DateTime start, {
  double horizonDeg = Horizons.star,
  Duration window = const Duration(hours: 24),
}) {
  final end = start.add(window);
  final crossings = findCrossings(altitude, start, end, horizonDeg: horizonDeg);

  // Transit: coarse scan then golden-section refinement around the peak.
  const coarse = Duration(minutes: 15);
  var best = start;
  var bestAlt = altitude(start);
  for (var t = start.add(coarse); !t.isAfter(end); t = t.add(coarse)) {
    final a = altitude(t);
    if (a > bestAlt) {
      bestAlt = a;
      best = t;
    }
  }
  var lo = best.subtract(coarse), hi = best.add(coarse);
  while (hi.difference(lo) > const Duration(seconds: 30)) {
    final m1 = lo.add(hi.difference(lo) ~/ 3);
    final m2 = hi.subtract(hi.difference(lo) ~/ 3);
    if (altitude(m1) < altitude(m2)) {
      lo = m1;
    } else {
      hi = m2;
    }
  }
  final transit = lo.add(hi.difference(lo) ~/ 2);

  final rise = crossings.where((c) => c.rising).map((c) => c.time).firstOrNull;
  final set = crossings.where((c) => !c.rising).map((c) => c.time).firstOrNull;
  final up = altitude(start) > horizonDeg;
  return RiseSet(
    rise: rise,
    set: set,
    transit: transit,
    transitAltitude: altitude(transit),
    alwaysUp: crossings.isEmpty && up,
    alwaysDown: crossings.isEmpty && !up,
  );
}
