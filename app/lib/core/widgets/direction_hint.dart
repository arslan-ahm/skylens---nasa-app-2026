import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../astro/coordinates.dart';
import '../theme/app_theme.dart';

/// Plain-language pointing instructions, e.g. "Face south-east (SE), look
/// about 30° up — roughly three fists above the horizon."
String directionSentence(Horizontal h) {
  if (h.alt < 0) return 'Below the horizon right now (${h.compassPoint}).';
  final up = h.alt.round();
  final fists = (h.alt / 10).round(); // a fist at arm's length ≈ 10°
  final height = h.alt > 80
      ? 'almost straight overhead'
      : 'about $up° up — roughly ${fists <= 1 ? 'one fist' : '$fists fists'} above the horizon';
  return 'Face ${_long[h.compassPoint]} (${h.compassPoint}), look $height.';
}

const _long = {
  'N': 'north',
  'NNE': 'north-north-east',
  'NE': 'north-east',
  'ENE': 'east-north-east',
  'E': 'east',
  'ESE': 'east-south-east',
  'SE': 'south-east',
  'SSE': 'south-south-east',
  'S': 'south',
  'SSW': 'south-south-west',
  'SW': 'south-west',
  'WSW': 'west-south-west',
  'W': 'west',
  'WNW': 'west-north-west',
  'NW': 'north-west',
  'NNW': 'north-north-west',
};

/// Mini compass (rim = horizon, centre = overhead) + the sentence.
class DirectionHint extends StatelessWidget {
  const DirectionHint(this.target, {super.key, this.size = 72});

  final Horizontal target;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = SkyTokens.of(context);
    return Semantics(
      label: directionSentence(target),
      child: ExcludeSemantics(
        child: Row(
          children: [
            SizedBox.square(
              dimension: size,
              child: CustomPaint(painter: _CompassPainter(target, t)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                directionSentence(target),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter(this.target, this.t);

  final Horizontal target;
  final SkyTokens t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 1;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = t.border,
    );
    canvas.drawCircle(
      c,
      r * 0.62,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = t.chartGrid,
    );

    // Altitude as distance from the rim (rim = horizon, centre = zenith).
    final rho = r * (1 - target.alt.clamp(0, 90) / 90);
    final a = (target.az - 90) * math.pi / 180;
    final p = c + Offset(math.cos(a), math.sin(a)) * rho;
    canvas.drawLine(
      c,
      p,
      Paint()
        ..color = t.primary.withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );
    canvas.drawCircle(c, 2, Paint()..color = t.textMuted);
    canvas.drawCircle(p, 5, Paint()..color = t.primary);

    final tp = TextPainter(
      text: TextSpan(
        text: 'N',
        style: TextStyle(
          fontFamily: kFontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: t.textMuted,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - r + 3));
  }

  @override
  bool shouldRepaint(_CompassPainter old) =>
      old.target.az != target.az || old.target.alt != target.alt || old.t != t;
}
