import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/design_components.dart';
import '../../core/widgets/motion.dart';

/// Animated, playful welcome. It picks up exactly where the native splash
/// leaves off (same background, logo centred at the same size), then:
///
/// 1. stars rush past at warp speed and settle into a twinkling sky;
/// 2. the logo's star pops, the logo glides up, a satellite orbits it;
/// 3. "SkyLens" bounces in letter by letter;
/// 4. the Big Dipper draws itself, star by star;
/// 5. the start button's rocket blasts off when tapped.
///
/// Tap the sky to make stars sparkle, tap the logo to spin it. Continues by
/// itself after a few quiet seconds. Reduced motion shows the final frame.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.next = '/explore'});

  final String next;

  /// Logo box size; matches the native splash icon (tool/brand/make_icons.py).
  static const markSize = 144.0;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _title = 'SkyLens';

  late final _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  late final _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );
  late final _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  late final _launch = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  Timer? _auto;
  bool _left = false;

  Animation<double> _part(double a, double b, [Curve curve = Motion.enter]) =>
      CurvedAnimation(
        parent: _intro,
        curve: Interval(a, b, curve: curve),
      );

  late final _warp = _part(0.0, 0.38, Curves.easeIn);
  late final _sky = _part(0.22, 0.5);
  late final _move = _part(0.3, 0.6, Curves.easeInOutCubic);
  late final _tagline = _part(0.72, 0.92);
  late final _dipper = _part(0.55, 0.95, Curves.easeInOut);
  late final _button = _part(0.8, 1.0);
  late final _letters = [
    for (var i = 0; i < _title.length; i++)
      _part(0.42 + i * 0.04, 0.70 + i * 0.04, Curves.elasticOut),
  ];
  // The star dips, then pops back with a bounce.
  late final _star = TweenSequence([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 0.55,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 12,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.55,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 40,
    ),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 48),
  ]).animate(_intro);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_intro.isAnimating || _intro.isCompleted) return;
    if (Motion.reduced(context)) {
      _intro.value = 1;
      _scheduleAuto();
      return;
    }
    _loop.repeat();
    // Auto-continue counts from the end of the intro, so the welcome is
    // always seen in full.
    _intro.forward().whenComplete(() {
      if (mounted) _scheduleAuto();
    });
  }

  void _scheduleAuto() {
    _auto?.cancel();
    _auto = Timer(const Duration(seconds: 4), _start);
  }

  /// Rocket blasts off, then we move on.
  Future<void> _start() async {
    if (_left || !mounted) return;
    _left = true;
    _auto?.cancel();
    if (!Motion.reduced(context)) await _launch.forward();
    if (mounted) context.go(widget.next);
  }

  @override
  void dispose() {
    _auto?.cancel();
    _intro.dispose();
    _loop.dispose();
    _spin.dispose();
    _launch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = SkyTokens.of(context);
    final text = Theme.of(context).textTheme;
    final reduced = Motion.reduced(context);

    return Scaffold(
      body: Listener(
        // Any interaction gives the user more time before auto-continue.
        onPointerDown: (_) {
          if (_intro.isCompleted) _scheduleAuto();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Twinkling, tappable sky that fades in after the warp.
            FadeTransition(
              opacity: _sky,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.35),
                    radius: 1.0,
                    colors: [Color.lerp(t.bg, t.primary, 0.16)!, t.bg],
                  ),
                ),
                child: const Starfield(
                  interactive: true,
                  density: 1.4,
                  shootingEvery: 2.6,
                ),
              ),
            ),

            // Warp-speed star rush and the Big Dipper.
            IgnorePointer(
              child: AnimatedBuilder(
                animation: Listenable.merge([_intro, _loop]),
                builder: (context, _) => CustomPaint(
                  painter: _IntroPainter(
                    warp: reduced ? 1 : _warp.value,
                    dipper: _dipper.value,
                    twinkle: _loop.value,
                    star: t.star,
                    line: t.primary,
                  ),
                ),
              ),
            ),

            // Logo: starts centred (= native splash), glides up.
            AnimatedBuilder(
              animation: Listenable.merge([_intro, _loop, _spin]),
              builder: (context, _) {
                final twinkle = reduced
                    ? 0.0
                    : 0.5 + 0.5 * math.sin(_loop.value * 2 * math.pi * 3);
                return Align(
                  alignment: Alignment(0, -0.30 * _move.value),
                  child: GestureDetector(
                    onTap: () => _spin.forward(from: 0),
                    child: Semantics(
                      label: 'SkyLens logo. Tap to spin.',
                      button: true,
                      child: Transform.rotate(
                        angle:
                            Curves.easeOutBack.transform(_spin.value) *
                            2 *
                            math.pi,
                        child: SizedBox.square(
                          dimension: SplashScreen.markSize,
                          child: CustomPaint(
                            painter: MarkPainter(
                              t,
                              star: _star.value,
                              twinkle: _intro.isCompleted ? twinkle : 0,
                            ),
                            foregroundPainter: reduced
                                ? null
                                : _OrbitPainter(
                                    angle: _loop.value * 2 * math.pi,
                                    opacity: _tagline.value,
                                    color: t.star,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Bouncing title, tagline and the rocket button.
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 5),
                  Semantics(
                    label: _title,
                    header: true,
                    child: ExcludeSemantics(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < _title.length; i++)
                            AnimatedBuilder(
                              animation: _letters[i],
                              builder: (context, child) {
                                final v = _letters[i].value;
                                return Opacity(
                                  opacity: v.clamp(0, 1),
                                  child: Transform.translate(
                                    offset: Offset(0, -36 * (1 - v)),
                                    child: child,
                                  ),
                                );
                              },
                              child: Text(_title[i], style: text.displaySmall),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.sm),
                  _FadeUp(
                    animation: _tagline,
                    child: Text(
                      'Your pocket observatory',
                      style: text.titleMedium!.copyWith(color: t.textMuted),
                    ),
                  ),
                  const Spacer(flex: 3),
                  _FadeUp(
                    animation: _button,
                    child: Column(
                      children: [
                        _RocketButton(launch: _launch, onPressed: _start),
                        const SizedBox(height: Space.lg),
                        Text(
                          'Tap the sky to make the stars sparkle',
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Start exploring" with a rocket that blasts off on tap.
class _RocketButton extends StatelessWidget {
  const _RocketButton({required this.launch, required this.onPressed});

  final Animation<double> launch;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = SkyTokens.of(context);
    return Pressable(
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size(230, 56),
          shape: const StadiumBorder(),
        ),
        child: AnimatedBuilder(
          animation: launch,
          builder: (context, _) {
            final q = Curves.easeIn.transform(launch.value);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.translate(
                  offset: Offset(18 * q, -260 * q),
                  child: Transform.rotate(
                    angle: -0.6 * (1 - q) + 0.2,
                    child: Icon(
                      Icons.rocket_launch,
                      color: t.onPrimary,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: Space.sm),
                Opacity(opacity: 1 - q, child: const Text('Start exploring')),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Warp-speed rush at the start, then the Big Dipper drawing itself.
class _IntroPainter extends CustomPainter {
  _IntroPainter({
    required this.warp,
    required this.dipper,
    required this.twinkle,
    required this.star,
    required this.line,
  });

  final double warp;
  final double dipper;
  final double twinkle;
  final Color star;
  final Color line;

  // Big Dipper, roughly to shape: Alkaid → Mizar → Alioth → Megrez →
  // Phecda → Merak → Dubhe → back to Megrez.
  static const _dipperPts = [
    Offset(0.00, 0.10),
    Offset(0.17, 0.00),
    Offset(0.32, 0.06),
    Offset(0.46, 0.20),
    Offset(0.50, 0.44),
    Offset(0.79, 0.50),
    Offset(0.82, 0.22),
    Offset(0.46, 0.20),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    _paintWarp(canvas, size);
    _paintDipper(canvas, size);
  }

  void _paintWarp(Canvas canvas, Size size) {
    if (warp >= 1) return;
    final c = size.center(Offset.zero);
    final maxR = size.longestSide * 0.8;
    final fade = warp < 0.6 ? 1.0 : (1 - warp) / 0.4;
    final rnd = math.Random(3);
    final p = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < 160; i++) {
      final a = rnd.nextDouble() * 2 * math.pi;
      final speed = 0.4 + rnd.nextDouble() * 0.9;
      final start = rnd.nextDouble() * 0.3;
      final d = maxR * (start + warp * warp * speed * 1.6);
      final tail = d * (1 - 0.35 * (1 - warp));
      final dir = Offset(math.cos(a), math.sin(a));
      p
        ..color = star.withValues(alpha: 0.85 * fade)
        ..strokeWidth = 1 + 1.6 * speed * warp;
      canvas.drawLine(c + dir * tail * 0.8, c + dir * d, p);
    }
  }

  void _paintDipper(Canvas canvas, Size size) {
    if (dipper <= 0) return;
    final w = math.min(size.width * 0.42, 190.0);
    final origin = Offset(size.width * 0.93 - w, size.height * 0.07 + 24);
    Offset at(Offset n) => origin + n * w;

    final segs = _dipperPts.length - 1;
    final drawn = dipper * segs;
    final linePaint = Paint()
      ..color = line.withValues(alpha: 0.55)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < segs; i++) {
      final k = (drawn - i).clamp(0.0, 1.0);
      if (k <= 0) break;
      final a = at(_dipperPts[i]), b = at(_dipperPts[i + 1]);
      canvas.drawLine(a, Offset.lerp(a, b, k)!, linePaint);
    }
    for (var i = 0; i < 7; i++) {
      final k = (drawn - i + 1).clamp(0.0, 1.0);
      if (k <= 0) continue;
      final tw = 0.75 + 0.25 * math.sin(twinkle * 2 * math.pi * 2 + i);
      final pop = Curves.elasticOut.transform(k);
      final pt = at(_dipperPts[i]);
      canvas.drawCircle(
        pt,
        7 * pop,
        Paint()..color = star.withValues(alpha: 0.18 * tw),
      );
      canvas.drawCircle(
        pt,
        2.6 * pop * tw,
        Paint()..color = star.withValues(alpha: 0.95),
      );
    }
    if (dipper > 0.85) {
      final tp = TextPainter(
        text: TextSpan(
          text: 'Big Dipper',
          style: TextStyle(
            fontFamily: kFontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: line.withValues(alpha: (dipper - 0.85) / 0.15 * 0.9),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, at(const Offset(0.5, 0.62)) - Offset(tp.width / 2, 0));
    }
  }

  @override
  bool shouldRepaint(_IntroPainter old) =>
      old.warp != warp || old.dipper != dipper || old.twinkle != twinkle;
}

/// A tiny satellite circling just outside the lens ring.
class _OrbitPainter extends CustomPainter {
  _OrbitPainter({
    required this.angle,
    required this.opacity,
    required this.color,
  });

  final double angle;
  final double opacity;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final c = size.center(Offset.zero);
    final r = size.shortestSide * 0.47;
    final p = c + Offset(math.cos(angle), math.sin(angle)) * r;
    canvas.drawCircle(
      p,
      size.shortestSide * 0.045,
      Paint()
        ..color = color.withValues(alpha: 0.25 * opacity)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          size.shortestSide * 0.03,
        ),
    );
    canvas.drawCircle(
      p,
      size.shortestSide * 0.018,
      Paint()..color = color.withValues(alpha: opacity),
    );
  }

  @override
  bool shouldRepaint(_OrbitPainter old) =>
      old.angle != angle || old.opacity != opacity || old.color != color;
}

class _FadeUp extends StatelessWidget {
  const _FadeUp({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    child: child,
    builder: (context, child) => Opacity(
      opacity: animation.value.clamp(0, 1),
      child: Transform.translate(
        offset: Offset(0, 16 * (1 - animation.value)),
        child: child,
      ),
    ),
  );
}
