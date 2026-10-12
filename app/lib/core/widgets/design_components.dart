import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'motion.dart';

// Shared building blocks of the SkyLens design system. Every one reads
// SkyTokens, so the night-vision and high-contrast themes apply everywhere.

/// Semantic colour of a status element. Always pair it with an icon or a
/// word: colour never carries meaning on its own.
enum Tone { neutral, primary, success, warning, danger }

extension ToneColor on Tone {
  Color of(SkyTokens t) => switch (this) {
    Tone.neutral => t.textMuted,
    Tone.primary => t.primary,
    Tone.success => t.success,
    Tone.warning => t.warning,
    Tone.danger => t.danger,
  };
}

// --- Brand ---------------------------------------------------------------

/// The SkyLens mark: a lens ring framing a horizon and a four-point star.
/// Same geometry as the launcher icon and splash (tool/brand/make_icons.py).
class SkyLensMark extends StatelessWidget {
  const SkyLensMark({super.key, this.size = 32, this.semanticLabel});

  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: MarkPainter(SkyTokens.of(context))),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: mark)
        : Semantics(label: semanticLabel, image: true, child: mark);
  }
}

/// Paints the mark. Each part can be partly drawn so the splash can
/// animate it: [ring] sweeps the lens, [ground] raises the horizon, [star]
/// pops the star in, [twinkle] (0..1) pulses it afterwards.
class MarkPainter extends CustomPainter {
  MarkPainter(
    this.t, {
    this.ring = 1,
    this.ground = 1,
    this.star = 1,
    this.twinkle = 0,
  });

  final SkyTokens t;
  final double ring;
  final double ground;
  final double star;
  final double twinkle;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    Offset p(double x, double y) => Offset(x * s, y * s);
    final c = p(0.5, 0.5);
    const ringR = 0.38, ringW = 0.075;
    final inner = (ringR - ringW / 2) * s;

    // Horizon: the part of the lens below a large arc, softly filled.
    if (ground > 0) {
      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: c, radius: inner)),
      );
      final rise = (1 - ground) * 0.3 * s;
      final g = Rect.fromCircle(
        center: p(0.5, 1.22) + Offset(0, rise),
        radius: 0.58 * s,
      );
      canvas.drawOval(
        g,
        Paint()..color = t.primary.withValues(alpha: 0.28 * ground),
      );
      canvas.drawOval(
        g,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.03 * s
          ..color = t.primary.withValues(alpha: ground),
      );
      canvas.restore();
    }

    // Lens ring with a light-to-deep gradient, swept clockwise from the top.
    if (ring > 0) {
      final ringRect = Rect.fromCircle(center: c, radius: ringR * s);
      canvas.drawArc(
        ringRect,
        -math.pi / 2,
        2 * math.pi * ring,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ringW * s
          ..strokeCap = ring < 1 ? StrokeCap.round : StrokeCap.butt
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(t.primary, Colors.white, 0.45)!,
              Color.lerp(t.primary, const Color(0xFF3355FF), 0.45)!,
            ],
          ).createShader(ringRect),
      );
    }

    // Four-point star (pops in, then twinkles) and a small companion.
    if (star > 0) {
      final pulse = 1 + 0.12 * twinkle;
      final sc = p(0.585, 0.41);
      canvas.save();
      canvas.translate(sc.dx, sc.dy);
      canvas.rotate((1 - star) * math.pi / 2 + twinkle * 0.08);
      canvas.translate(-sc.dx, -sc.dy);
      if (twinkle > 0) {
        canvas.drawCircle(
          sc,
          0.16 * s * pulse,
          Paint()
            ..color = t.star.withValues(alpha: 0.12 * twinkle)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.06 * s),
        );
      }
      canvas.drawPath(
        _sparkle(sc, 0.15 * s * star * pulse, 0.035 * s * star),
        Paint()..color = t.star,
      );
      canvas.restore();
      canvas.drawCircle(
        p(0.375, 0.355),
        0.026 * s * star,
        Paint()..color = t.star.withValues(alpha: 0.85 * (1 - 0.5 * twinkle)),
      );
    }
  }

  static Path _sparkle(Offset c, double outer, double inner) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / 4;
      final pt = c + Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(MarkPainter old) =>
      old.t != t ||
      old.ring != ring ||
      old.ground != ground ||
      old.star != star ||
      old.twinkle != twinkle;
}

/// Mark + "SkyLens" wordmark, with an optional caption underneath.
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.caption, this.markSize = 36});

  final String? caption;
  final double markSize;

  @override
  Widget build(BuildContext context) {
    final t = SkyTokens.of(context);
    final text = Theme.of(context).textTheme;
    return Semantics(
      header: true,
      label: caption == null ? 'SkyLens' : 'SkyLens, $caption',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SkyLensMark(size: markSize),
            const SizedBox(width: Space.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('SkyLens', style: text.titleLarge),
                if (caption != null)
                  Text(
                    caption!,
                    style: text.labelMedium!.copyWith(color: t.textMuted),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- Structure -----------------------------------------------------------

/// Small uppercase heading above a group of content.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing, this.padding});

  final String text;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final t = SkyTokens.of(context);
    return Padding(
      padding:
          padding ??
          const EdgeInsets.only(top: Space.xl, bottom: Space.sm, left: 4),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                text.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall!
                    .copyWith(color: t.textMuted),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Rounded tinted square holding an icon (list leading, card header).
class IconBadge extends StatelessWidget {
  const IconBadge(
    this.icon, {
    super.key,
    this.tone = Tone.primary,
    this.size = 40,
  });

  final IconData icon;
  final Tone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = SkyTokens.of(context);
    final fg = tone == Tone.primary ? t.onPrimaryContainer : tone.of(t);
    final bg = tone == Tone.primary
        ? t.primaryContainer
        : tone.of(t).withValues(alpha: 0.14);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: Icon(icon, size: size * 0.5, color: fg),
      ),
    );
  }
}

/// Compact label + value tile for key numbers ("Data mode · Live").
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.tone = Tone.neutral,
  });

  final String label;
  final String value;
  final IconData? icon;

  /// Colours the icon only; the value stays primary text.
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final t = SkyTokens.of(context);
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: '$label: $value',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(Space.md),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: t.outline, width: t.strokeWidth),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: tone.of(t)),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      style: text.labelMedium!.copyWith(color: t.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              AnimatedValue(
                value,
                style: text.titleMedium!.copyWith(
                  fontFeatures: kTabularFigures,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lays out [MetricTile]s in equal columns.
class MetricRow extends StatelessWidget {
  const MetricRow(this.tiles, {super.key});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < tiles.length; i++) ...[
        if (i > 0) const SizedBox(width: Space.sm),
        Expanded(child: tiles[i]),
      ],
    ],
  );
}

/// Small rounded status label with an icon: "Live", "Saved", "Demo key".
class StatusPill extends StatelessWidget {
  const StatusPill(
    this.label, {
    super.key,
    this.tone = Tone.neutral,
    this.icon,
  });

  final String label;
  final Tone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = SkyTokens.of(context);
    final c = tone.of(t);
    return AnimatedContainer(
      duration: Motion.medium,
      curve: Motion.enter,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Radii.sm),
        border: t.strokeWidth > 1 ? Border.all(color: c) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium!
                .copyWith(color: c, height: 1.2),
          ),
        ],
      ),
    );
  }
}

/// A tappable row inside a card: icon badge, title, subtitle, chevron.
class ModuleTile extends StatelessWidget {
  const ModuleTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = SkyTokens.of(context);
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: ExcludeSemantics(
        child: Pressable(
          scale: 0.985,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.lg,
                  vertical: Space.md,
                ),
                child: Row(
                  children: [
                    IconBadge(icon),
                    const SizedBox(width: Space.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(title, style: text.titleSmall),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: text.bodyMedium!.copyWith(
                              color: t.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Space.sm),
                    trailing ?? Icon(Icons.chevron_right, color: t.textMuted),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Card that groups rows separated by inset dividers (settings-style).
class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Divider(indent: 72),
          children[i],
        ],
      ],
    ),
  );
}

/// Status dot for live data / active state. [pulse] adds an expanding ring
/// (off when the OS asks for reduced motion).
class LiveDot extends StatefulWidget {
  const LiveDot({super.key, this.size = 8, this.pulse = false, this.color});

  final double size;
  final bool pulse;
  final Color? color;

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = widget.pulse && !MediaQuery.disableAnimationsOf(context);
    if (animate && !_c.isAnimating) _c.repeat();
    if (!animate) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? SkyTokens.of(context).success;
    final s = widget.size;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: s * 2.5,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            painter: _LiveDotPainter(color, s, widget.pulse ? _c.value : -1),
          ),
        ),
      ),
    );
  }
}

class _LiveDotPainter extends CustomPainter {
  _LiveDotPainter(this.color, this.size, this.phase);

  final Color color;
  final double size;
  final double phase;

  @override
  void paint(Canvas canvas, Size box) {
    final c = box.center(Offset.zero);
    if (phase >= 0) {
      canvas.drawCircle(
        c,
        size / 2 + phase * size * 0.75,
        Paint()..color = color.withValues(alpha: 0.4 * (1 - phase)),
      );
    }
    canvas.drawCircle(c, size / 2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_LiveDotPainter old) => old.phase != phase;
}
