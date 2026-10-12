import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../astro/astro_time.dart';
import '../astro/coordinates.dart';
import '../astro/sky_catalog.dart';
import '../astro/sky_engine.dart';
import '../theme/app_theme.dart';
import 'object_sheet.dart';

/// Whole-sky chart (azimuthal equidistant: rim = horizon, centre = zenith),
/// drawn as if held overhead: north at top, east on the LEFT, like a
/// planisphere. Tap to pick the nearest object.
class SkyDome extends StatelessWidget {
  const SkyDome({
    super.key,
    required this.snapshot,
    this.constellations = const [],
    this.rotationDeg = 0,
    this.maxStarMagnitude = 4.5,
    this.selectedId,
    this.onSelect,
  });

  final SkySnapshot snapshot;
  final List<Constellation> constellations;

  /// Rotates the chart so the user's facing azimuth can be at the bottom.
  final double rotationDeg;
  final double maxStarMagnitude;
  final String? selectedId;
  final ValueChanged<SkyObject>? onSelect;

  @override
  Widget build(BuildContext context) {
    final t = SkyTokens.of(context);
    final lines = _constellationLines();
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size.square(box.biggest.shortestSide);
        final proj = _DomeProjection(size, rotationDeg);
        final visible = [
          for (final o in snapshot.objects)
            if (o.horizontal.alt > 0 &&
                (o.kind != SkyObjectKind.star ||
                    o.magnitude <= maxStarMagnitude))
              o,
        ];
        return Center(
          child: GestureDetector(
            onTapUp: onSelect == null
                ? null
                : (d) {
                    SkyObject? best;
                    var bestDist = 28.0;
                    for (final o in visible) {
                      final dist =
                          (proj.toScreen(o.horizontal) - d.localPosition)
                              .distance;
                      // Favour bright objects when taps are ambiguous.
                      final score = dist + o.magnitude.clamp(-2, 6) * 2;
                      if (score < bestDist) {
                        bestDist = score;
                        best = o;
                      }
                    }
                    if (best != null) onSelect!(best);
                  },
            child: SizedBox.fromSize(
              size: size,
              child: Semantics(
                label:
                    'Sky chart showing ${visible.length} objects above the horizon',
                child: CustomPaint(
                  painter: _DomePainter(proj, visible, lines, t, selectedId),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<List<Horizontal>> _constellationLines() {
    final jd = julianDate(snapshot.time);
    final jdTT = julianDateTT(snapshot.time);
    return [
      for (final c in constellations)
        for (final seg in c.lines)
          [
            for (final p in seg)
              equatorialToHorizontal(
                precessFromJ2000(p, jdTT),
                snapshot.observer,
                jd,
              ),
          ],
    ];
  }
}

class _DomeProjection {
  _DomeProjection(this.size, this.rotationDeg);

  final Size size;
  final double rotationDeg;

  double get radius => size.shortestSide / 2 - 16;
  Offset get centre => size.center(Offset.zero);

  Offset toScreen(Horizontal h) {
    final rho = radius * (90 - h.alt) / 90;
    final a = (h.az - rotationDeg) * math.pi / 180;
    return centre + Offset(-rho * math.sin(a), -rho * math.cos(a));
  }
}

class _DomePainter extends CustomPainter {
  _DomePainter(this.proj, this.objects, this.lines, this.t, this.selectedId);

  final _DomeProjection proj;
  final List<SkyObject> objects;
  final List<List<Horizontal>> lines;
  final SkyTokens t;
  final String? selectedId;

  @override
  void paint(Canvas canvas, Size size) {
    final c = proj.centre, r = proj.radius;
    // DESIGN_TOKENS.md globe visualization: Deep Navy wash, Concentric Teal rings.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [t.wash, t.wash.withValues(alpha: 0.35)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));

    // Altitude rings at 30° and 60°.
    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = t.diagram;
    canvas.drawCircle(c, r * 2 / 3, grid);
    canvas.drawCircle(c, r / 3, grid);

    final linePaint = Paint()
      ..color = t.constellation
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (final seg in lines) {
      if (seg.every((h) => h.alt < -5)) continue;
      final path = Path();
      for (var i = 0; i < seg.length; i++) {
        final p = proj.toScreen(seg[i]);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, linePaint);
    }

    final labels = <(SkyObject, Offset, double, Color)>[];
    for (final o in objects) {
      final p = proj.toScreen(o.horizontal);
      final color = colorForObject(o, t);
      final radius = switch (o.kind) {
        SkyObjectKind.sun || SkyObjectKind.moon => 7.0,
        SkyObjectKind.planet => 4.0,
        SkyObjectKind.star => math.max(0.7, 3.4 - 0.55 * o.magnitude),
      };
      canvas.drawCircle(p, radius, Paint()..color = color);
      if (o.id == selectedId) {
        canvas.drawCircle(
          p,
          radius + 6,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = t.live,
        );
      }
      if (o.kind != SkyObjectKind.star || o.magnitude < 1.5) {
        labels.add((o, p, radius, color));
      }
    }

    // Brightest (and the selected object) first; each label tries the right
    // side, then the left, and is dropped if both collide or leave the dome.
    labels.sort((a, b) {
      if (a.$1.id == selectedId) return -1;
      if (b.$1.id == selectedId) return 1;
      return a.$1.magnitude.compareTo(b.$1.magnitude);
    });
    final placed = <Rect>[];
    for (final (o, p, radius, color) in labels) {
      final tp = _layout(o.name, color, 11);
      for (final at in [
        p + Offset(radius + 3, -tp.height / 2),
        p + Offset(-radius - 3 - tp.width, -tp.height / 2),
      ]) {
        final rect = (at & tp.size).inflate(1.5);
        final inside =
            (rect.topLeft - c).distance < r &&
            (rect.topRight - c).distance < r &&
            (rect.bottomLeft - c).distance < r &&
            (rect.bottomRight - c).distance < r;
        if (inside && !placed.any(rect.overlaps)) {
          placed.add(rect);
          tp.paint(canvas, at);
          break;
        }
      }
    }
    canvas.restore();

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = t.horizon,
    );
    for (final (label, az) in [
      ('N', 0.0),
      ('E', 90.0),
      ('S', 180.0),
      ('W', 270.0),
    ]) {
      final p = proj.toScreen(Horizontal(az, -10));
      _label(canvas, label, p - const Offset(4, 7), t.ink, 13);
    }
  }

  TextPainter _layout(String s, Color color, double size) => TextPainter(
    text: TextSpan(
      text: s,
      style: skyText(size, 1.2, size * 0.04).copyWith(color: color),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  void _label(Canvas canvas, String s, Offset at, Color color, double size) =>
      _layout(s, color, size).paint(canvas, at);

  @override
  bool shouldRepaint(_DomePainter old) =>
      old.objects != objects || old.selectedId != selectedId || old.t != t;
}
