import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Motion system. Every interactive or changing element animates, using
// these tokens, and every animation respects the OS "reduce motion" setting
// (see docs/DESIGN_TOKENS.md, "Motion").

abstract final class Motion {
  /// Press feedback, toggles, small state changes.
  static const fast = Duration(milliseconds: 140);

  /// Most transitions: value changes, expand/collapse, fades.
  static const medium = Duration(milliseconds: 280);

  /// Entrances and page-level choreography.
  static const slow = Duration(milliseconds: 520);

  /// Delay between items in a staggered entrance.
  static const stagger = Duration(milliseconds: 55);

  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const emphasized = Curves.easeOutBack;

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// Fades and slides its child in once, after [delay]. Use [staggered] to
/// reveal a list item by item.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 16),
  });

  final Widget child;
  final Duration delay;
  final Offset offset;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  // The delay is part of the animation (an Interval), so no timers linger.
  late final _total = widget.delay + Motion.slow;
  late final _c = AnimationController(vsync: this, duration: _total);
  late final _a = CurvedAnimation(
    parent: _c,
    curve: Interval(
      widget.delay.inMicroseconds / _total.inMicroseconds,
      1,
      curve: Motion.enter,
    ),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.reduced(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    child: widget.child,
    builder: (context, child) => Opacity(
      opacity: _a.value,
      child: Transform.translate(
        offset: widget.offset * (1 - _a.value),
        child: child,
      ),
    ),
  );
}

/// Wraps each widget in a [Reveal] with an increasing delay.
List<Widget> staggered(
  List<Widget> children, {
  Duration start = Duration.zero,
}) => [
  for (var i = 0; i < children.length; i++)
    Reveal(delay: start + Motion.stagger * math.min(i, 12), child: children[i]),
];

/// Gently shrinks while pressed, so every tap gets visible feedback even
/// before the ripple. Doesn't consume gestures: put an InkWell inside.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.scale = 0.97});

  final Widget child;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _set(true),
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: AnimatedScale(
      scale: _down && !Motion.reduced(context) ? widget.scale : 1,
      duration: Motion.fast,
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}

/// Cross-fades and slides when [value] changes (numbers, labels, states).
class AnimatedValue extends StatelessWidget {
  const AnimatedValue(
    this.value, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines = 1,
  });

  final String value;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int maxLines;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: Motion.medium,
    switchInCurve: Motion.enter,
    switchOutCurve: Motion.exit,
    transitionBuilder: (child, a) => FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(a),
        child: child,
      ),
    ),
    layoutBuilder: (current, previous) => Stack(
      alignment: Alignment.centerLeft,
      children: [...previous, ?current],
    ),
    child: Text(
      value,
      key: ValueKey(value),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    ),
  );
}

/// Twinkling star field with an occasional shooting star. With
/// [interactive], taps burst into sparkles. Static under reduced motion.
class Starfield extends StatefulWidget {
  const Starfield({
    super.key,
    this.density = 1,
    this.interactive = false,
    this.seed = 7,
    this.shootingStars = true,
    this.shootingEvery = 7,
    this.child,
  });

  /// Stars per 10,000 px² of area, roughly.
  final double density;
  final bool interactive;
  final int seed;
  final bool shootingStars;

  /// Seconds between shooting stars.
  final double shootingEvery;
  final Widget? child;

  @override
  State<Starfield> createState() => _StarfieldState();
}

class _Burst {
  _Burst(this.at, this.start);
  final Offset at;
  final Duration start;
}

class _StarfieldState extends State<Starfield>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(days: 1),
  );
  final _bursts = <_Burst>[];
  late final List<_Star> _stars = _makeStars();

  List<_Star> _makeStars() {
    final r = math.Random(widget.seed);
    return [
      for (var i = 0; i < 400; i++)
        _Star(
          Offset(r.nextDouble(), r.nextDouble()),
          0.5 + r.nextDouble() * (r.nextDouble() < 0.1 ? 1.8 : 0.9),
          r.nextDouble() * math.pi * 2,
          0.6 + r.nextDouble() * 1.8,
          r.nextDouble() < 0.12,
        ),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Duration get _now => _c.lastElapsedDuration ?? Duration.zero;

  void _tap(TapDownDetails d) {
    setState(() {
      _bursts.add(_Burst(d.localPosition, _now));
      if (_bursts.length > 8) _bursts.removeAt(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = SkyTokens.of(context);
    final paint = AnimatedBuilder(
      animation: _c,
      builder: (context, child) => CustomPaint(
        painter: _StarfieldPainter(
          stars: _stars,
          time: _now,
          bursts: _bursts,
          density: widget.density,
          shooting: widget.shootingStars && !Motion.reduced(context),
          period: widget.shootingEvery,
          star: t.star,
          accent: t.primary,
        ),
        child: child,
      ),
      child: widget.child,
    );
    return widget.interactive
        ? GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: _tap,
            child: paint,
          )
        : paint;
  }
}

class _Star {
  const _Star(this.pos, this.radius, this.phase, this.speed, this.colored);
  final Offset pos;
  final double radius;
  final double phase;
  final double speed;
  final bool colored;
}

class _StarfieldPainter extends CustomPainter {
  _StarfieldPainter({
    required this.stars,
    required this.time,
    required this.bursts,
    required this.density,
    required this.shooting,
    required this.period,
    required this.star,
    required this.accent,
  });

  final List<_Star> stars;
  final Duration time;
  final List<_Burst> bursts;
  final double density;
  final bool shooting;
  final double period;
  final Color star;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final s = time.inMicroseconds / 1e6;
    final count = math.min(
      stars.length,
      (size.width * size.height / 10000 * density).round(),
    );
    final p = Paint();
    for (var i = 0; i < count; i++) {
      final st = stars[i];
      final tw = 0.55 + 0.45 * math.sin(s * st.speed + st.phase);
      final c = st.colored ? accent : star;
      final at = Offset(st.pos.dx * size.width, st.pos.dy * size.height);
      p.color = c.withValues(alpha: (0.25 + 0.75 * tw) * 0.9);
      canvas.drawCircle(at, st.radius * (0.8 + 0.3 * tw), p);
      if (st.radius > 1.6) {
        // Bright stars get a soft cross glint.
        p
          ..color = c.withValues(alpha: 0.35 * tw)
          ..strokeWidth = 0.8;
        final l = st.radius * 3.5 * tw;
        canvas.drawLine(at - Offset(l, 0), at + Offset(l, 0), p);
        canvas.drawLine(at - Offset(0, l), at + Offset(0, l), p);
      }
    }

    // A shooting star crosses every ~7 s.
    if (shooting) {
      const life = 0.9;
      final k = (s / period).floor();
      final ph = s - k * period;
      if (ph < life) {
        final r = math.Random(k);
        final start = Offset(
          size.width * (0.2 + 0.7 * r.nextDouble()),
          size.height * 0.45 * r.nextDouble(),
        );
        final dir = Offset(-0.8, 0.45) * (size.shortestSide * 0.5);
        final q = Curves.easeOut.transform(ph / life);
        final head = start + dir * q;
        final tail = start + dir * math.max(0, q - 0.25);
        canvas.drawLine(
          tail,
          head,
          Paint()
            ..strokeWidth = 1.6
            ..strokeCap = StrokeCap.round
            ..shader = LinearGradient(
              colors: [
                star.withValues(alpha: 0),
                star.withValues(alpha: 1 - q),
              ],
            ).createShader(Rect.fromPoints(tail, head)),
        );
      }
    }

    // Tap bursts: eight sparks fly out and fade.
    for (final b in bursts) {
      final age = (time - b.start).inMicroseconds / 1e6;
      if (age < 0 || age > 0.9) continue;
      final q = Curves.easeOut.transform(age / 0.9);
      final paint = Paint()..color = accent.withValues(alpha: 1 - q);
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4 + 0.3;
        final d = 10 + 46 * q;
        canvas.drawCircle(
          b.at + Offset(math.cos(a), math.sin(a)) * d,
          2.6 * (1 - q) + 0.6,
          paint,
        );
      }
      canvas.drawCircle(
        b.at,
        6 * (1 - q),
        Paint()..color = star.withValues(alpha: 1 - q),
      );
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter old) => true;
}

/// Gently bobs its child up and down (empty-state icons, illustrations).
class Float extends StatefulWidget {
  const Float({super.key, required this.child, this.distance = 5});

  final Widget child;
  final double distance;

  @override
  State<Float> createState() => _FloatState();
}

class _FloatState extends State<Float> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (context, child) => Transform.translate(
      offset: Offset(
        0,
        -widget.distance * Curves.easeInOut.transform(_c.value),
      ),
      child: child,
    ),
  );
}
