import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/astro/sky_engine.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/design_components.dart';
import '../../core/widgets/motion.dart';

/// Home of the Lab: one friendly tile per building block, so each can be
/// tried on a real phone. Technical details live behind "For developers".
class LabHomeScreen extends ConsumerWidget {
  const LabHomeScreen({super.key});

  static const _features = [
    ('/sky', Icons.auto_awesome, 'Sky map', "See what's above you now"),
    (
      '/camera',
      Icons.photo_camera_outlined,
      'Sky camera',
      'Point your phone at a star',
    ),
    (
      '/compass',
      Icons.explore_outlined,
      'Compass',
      'Where you are and where you face',
    ),
    (
      '/news',
      Icons.rocket_launch_outlined,
      'Space news',
      'Pictures and updates from NASA',
    ),
    (
      '/diary',
      Icons.menu_book_outlined,
      'Sky diary',
      'Keep notes of what you saw',
    ),
    ('/settings', Icons.tune, 'Settings', 'Themes, text size and style'),
  ];

  /// Opened over the tabs; everything else is a tab.
  static const _fullScreen = {'/camera', '/compass'};

  static String _greeting(DateTime now) => switch (now.hour) {
    >= 5 && < 12 => 'Good morning',
    >= 12 && < 17 => 'Good afternoon',
    _ => 'Good evening',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = SkyTokens.of(context);
    final text = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;
    final tileWidth = (math.min(width, 600) - Space.gutter * 2 - Space.md) / 2;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Starfield(
              density: 1.2,
              interactive: true,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.gutter,
                    Space.sm,
                    Space.sm,
                    Space.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: staggered([
                      Row(
                        children: [
                          const SkyLensMark(size: 36),
                          const SizedBox(width: Space.md),
                          Text('SkyLens', style: text.titleLarge),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Settings',
                            icon: const Icon(Icons.settings_outlined),
                            onPressed: () => context.go('/settings'),
                          ),
                        ],
                      ),
                      const SizedBox(height: Space.lg),
                      Text(
                        _greeting(DateTime.now()),
                        style: text.titleMedium!.copyWith(color: t.textMuted),
                      ),
                      const SizedBox(height: Space.xs),
                      Text(
                        'What shall we explore?',
                        style: text.headlineMedium,
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Space.gutter,
              0,
              Space.gutter,
              Space.xxl,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Reveal(
                    delay: Duration(milliseconds: 150),
                    child: _TonightCard(),
                  ),
                  const SizedBox(height: Space.md),
                  Wrap(
                    spacing: Space.md,
                    runSpacing: Space.md,
                    children: staggered(start: Motion.medium, [
                      for (final (i, (path, icon, title, subtitle))
                          in _features.indexed)
                        SizedBox(
                          width: tileWidth,
                          child: _FeatureTile(
                            icon: icon,
                            title: title,
                            subtitle: subtitle,
                            color: t.accents[i % t.accents.length],
                            onTap: () => _fullScreen.contains(path)
                                ? context.push(path)
                                : context.go(path),
                          ),
                        ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Live summary of tonight: the Moon at its real phase, how dark it is and
/// how many planets are up. Opens the sky map.
class _TonightCard extends ConsumerWidget {
  const _TonightCard();

  static String _mood(Twilight tw) => switch (tw) {
    Twilight.day => 'Stars come out after sunset',
    Twilight.civil || Twilight.nautical => 'The sky is getting dark',
    Twilight.astronomical => 'Almost dark enough',
    Twilight.night => 'A great time to stargaze',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = SkyTokens.of(context);
    final text = Theme.of(context).textTheme;
    final snap = ref.watch(skySnapshotProvider).value;
    final planets = snap?.aboveHorizon
        .where((o) => o.kind == SkyObjectKind.planet)
        .length;
    final phase = snap?.moonPhase;

    return Pressable(
      child: Material(
        color: t.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
          side: BorderSide(color: t.outline, width: t.strokeWidth),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go('/sky'),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(t.surface, t.primary, 0.18)!,
                        t.surface,
                      ],
                    ),
                  ),
                  child: const Starfield(
                    density: 0.9,
                    seed: 21,
                    shootingStars: false,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(Space.xl),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "TONIGHT'S SKY",
                            style: text.labelSmall!.copyWith(color: t.primary),
                          ),
                          const SizedBox(height: Space.sm),
                          AnimatedValue(
                            snap == null ? 'Looking up…' : _mood(snap.twilight),
                            style: text.titleLarge,
                            maxLines: 2,
                          ),
                          const SizedBox(height: Space.xs),
                          AnimatedValue(
                            phase == null
                                ? ' '
                                : '${phase.name} · ${planets ?? 0} '
                                      '${planets == 1 ? 'planet' : 'planets'} up',
                            style: text.bodyMedium!.copyWith(
                              color: t.textMuted,
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: Space.lg),
                          Row(
                            children: [
                              Text(
                                'Open sky map',
                                style: text.labelLarge!.copyWith(
                                  color: t.primary,
                                ),
                              ),
                              const SizedBox(width: Space.xs),
                              Icon(
                                Icons.arrow_forward,
                                size: 18,
                                color: t.primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Space.lg),
                    MoonPhaseIcon(
                      fraction: phase?.illuminatedFraction ?? 0.5,
                      waxing: phase?.waxing ?? true,
                      size: 76,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = SkyTokens.of(context);
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: ExcludeSemantics(
        child: Pressable(
          child: Material(
            color: t.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.xl),
              side: BorderSide(color: t.outline, width: t.strokeWidth),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              splashColor: color.withValues(alpha: 0.18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 150),
                child: Padding(
                  padding: const EdgeInsets.all(Space.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const SizedBox(height: Space.lg),
                      Text(title, style: text.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: text.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The Moon drawn at its real phase (lit side on the right when waxing, as
/// seen from the northern hemisphere). Animates when the phase changes.
class MoonPhaseIcon extends StatelessWidget {
  const MoonPhaseIcon({
    super.key,
    required this.fraction,
    required this.waxing,
    this.size = 64,
  });

  final double fraction;
  final bool waxing;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = SkyTokens.of(context);
    return Semantics(
      label: 'Moon ${(fraction * 100).round()}% lit',
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: fraction),
        duration: Motion.slow,
        curve: Motion.enter,
        builder: (context, f, _) => SizedBox.square(
          dimension: size,
          child: CustomPaint(painter: _MoonPainter(f, waxing, t)),
        ),
      ),
    );
  }
}

class _MoonPainter extends CustomPainter {
  _MoonPainter(this.f, this.waxing, this.t);

  final double f;
  final bool waxing;
  final SkyTokens t;

  /// Half of [r]'s oval on one side of its vertical axis (+1 right, -1 left).
  static Path _half(Rect r, double side) => Path()
    ..moveTo(r.center.dx, r.top)
    ..arcTo(r, -math.pi / 2, math.pi * side, false)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final disc = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r * 1.2,
      Paint()
        ..color = t.moon.withValues(alpha: 0.05 + 0.12 * f)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.3),
    );
    canvas.drawCircle(c, r, Paint()..color = t.moon.withValues(alpha: 0.12));

    final lit = waxing ? 1.0 : -1.0;
    final terminator = Rect.fromCenter(
      center: c,
      width: 2 * r * (1 - 2 * f).abs(),
      height: 2 * r,
    );
    final path = f < 0.5
        ? Path.combine(
            PathOperation.difference,
            _half(disc, lit),
            _half(terminator, lit),
          )
        : Path.combine(
            PathOperation.union,
            _half(disc, lit),
            _half(terminator, -lit),
          );
    canvas.drawPath(path, Paint()..color = t.moon);
  }

  @override
  bool shouldRepaint(_MoonPainter old) =>
      old.f != f || old.waxing != waxing || old.t != t;
}
