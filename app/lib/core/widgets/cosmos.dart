import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// DESIGN.md components: ghost pill button, category tag, stat strip,
// carousel dots, live indicator, globe (concentric-ring) diagram and a
// section header. All flat, weight 400, white-first.

/// The canonical action: outlined pill with a trailing ›.
class GhostPillButton extends StatelessWidget {
  const GhostPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.showArrow = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool showArrow;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 10)],
        Text(label),
        if (showArrow) ...[
          const SizedBox(width: 8),
          const ExcludeSemantics(child: Text('›')),
        ],
      ],
    ),
  );
}

/// Small uppercase label (card categories, eyebrows above headlines).
class CategoryTag extends StatelessWidget {
  const CategoryTag(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: skyText(
      12,
      1.5,
      0.6,
    ).copyWith(color: color ?? SkyTokens.of(context).inkMuted),
  );
}

/// Eyebrow + headline (+ optional trailing widget, e.g. [CarouselDots]).
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.trailing,
    this.large = false,
  });

  final String title;
  final String? eyebrow;
  final Widget? trailing;

  /// Display size (60) instead of heading size (36).
  final bool large;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null || trailing != null)
          Row(
            children: [
              if (eyebrow != null) CategoryTag(eyebrow!),
              const Spacer(),
              ?trailing,
            ],
          ),
        if (eyebrow != null) const SizedBox(height: 12),
        Semantics(
          header: true,
          child: Text(
            title,
            style: large ? text.displayLarge : text.headlineLarge,
          ),
        ),
      ],
    );
  }
}

/// Row of key metrics: white value followed by a Slate label.
class StatStrip extends StatelessWidget {
  const StatStrip(this.items, {super.key, this.valueSize = 24});

  final List<(String value, String label)> items;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    final t = SkyTokens.of(context);
    return Wrap(
      spacing: 30,
      runSpacing: 12,
      children: [
        for (final (value, label) in items)
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: skyText(
                    valueSize,
                    1.25,
                    valueSize * 0.025,
                  ).copyWith(color: t.ink),
                ),
                TextSpan(
                  text: '  $label',
                  style: skyText(16, 1.6, 0.4).copyWith(color: t.inkMuted),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Position indicator: Slate dots, white for the active one.
class CarouselDots extends StatelessWidget {
  const CarouselDots({
    super.key,
    required this.count,
    required this.index,
    this.onTap,
  });

  final int count;
  final int index;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final t = SkyTokens.of(context);
    return Semantics(
      label: 'Step ${index + 1} of $count',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            GestureDetector(
              onTap: onTap == null ? null : () => onTap!(i),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == index ? t.ink : t.inkMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Signal Mint status dot for live data / active state. [pulse] adds an
/// expanding ring (disabled when the OS asks for reduced motion).
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
    final color = widget.color ?? SkyTokens.of(context).live;
    final s = widget.size;
    return SizedBox.square(
      dimension: s * 3,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _LiveDotPainter(color, s, widget.pulse ? _c.value : -1),
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
        size / 2 + phase * size,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = color.withValues(alpha: 1 - phase),
      );
    }
    canvas.drawCircle(c, size / 2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_LiveDotPainter old) => old.phase != phase;
}

/// A labelled point orbiting on one of the [GlobeDiagram] rings.
class GlobeNode {
  const GlobeNode({
    required this.ring,
    required this.angleDeg,
    this.label,
    this.live = false,
  });

  /// 0 = innermost ring.
  final int ring;
  final double angleDeg;
  final String? label;

  /// Drawn in Signal Mint with a pulse.
  final bool live;
}

/// DESIGN.md "globe visualization": concentric Teal rings over a Deep Navy
/// wash, white nodes with uppercase annotation labels. Use it as hero art,
/// in empty states, or behind a centred [child].
class GlobeDiagram extends StatefulWidget {
  const GlobeDiagram({
    super.key,
    this.size = 280,
    this.rings = 3,
    this.nodes = const [],
    this.centerLabel,
    this.child,
    this.animate = false,
  });

  final double size;
  final int rings;
  final List<GlobeNode> nodes;
  final String? centerLabel;
  final Widget? child;

  /// Slowly orbit the nodes (off when reduced motion is requested).
  final bool animate;

  @override
  State<GlobeDiagram> createState() => _GlobeDiagramState();
}

class _GlobeDiagramState extends State<GlobeDiagram>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = widget.animate && !MediaQuery.disableAnimationsOf(context);
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
    final t = SkyTokens.of(context);
    return SizedBox.square(
      dimension: widget.size,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) => CustomPaint(
            painter: _GlobePainter(
              t,
              widget.rings,
              widget.nodes,
              widget.centerLabel,
              _c.value,
            ),
            child: child,
          ),
          child: widget.child == null ? null : Center(child: widget.child),
        ),
      ),
    );
  }
}

class _GlobePainter extends CustomPainter {
  _GlobePainter(this.t, this.rings, this.nodes, this.centerLabel, this.phase);

  final SkyTokens t;
  final int rings;
  final List<GlobeNode> nodes;
  final String? centerLabel;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outer = size.shortestSide / 2;

    canvas.drawCircle(
      c,
      outer,
      Paint()
        ..shader = RadialGradient(colors: [t.wash, t.wash.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: c, radius: outer)),
    );

    // Dashed outer guide in Iron.
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = t.hairline;
    final rDash = outer - 2;
    for (var a = 0.0; a < 2 * math.pi; a += 0.06) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: rDash),
        a,
        0.02,
        false,
        dash,
      );
    }

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = t.diagram;
    double ringR(int i) => outer * (0.32 + 0.6 * (i + 1) / (rings + 1));
    for (var i = 0; i < rings; i++) {
      canvas.drawCircle(c, ringR(i), ringPaint);
    }

    canvas.drawCircle(c, 3.5, Paint()..color = t.ink);
    if (centerLabel != null) {
      _label(canvas, centerLabel!, c + const Offset(9, -8));
    }

    for (final n in nodes) {
      final r = ringR(n.ring.clamp(0, rings - 1));
      final speed = 1.0 / (n.ring + 1);
      final a = (n.angleDeg * math.pi / 180) + phase * 2 * math.pi * speed;
      final p = c + Offset(math.cos(a), math.sin(a)) * r;
      final color = n.live ? t.live : t.ink;
      if (n.live) {
        canvas.drawCircle(
          p,
          8,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = t.live.withValues(alpha: 0.5),
        );
      }
      canvas.drawCircle(p, 3.5, Paint()..color = color);
      if (n.label != null) {
        final lead = Paint()
          ..strokeWidth = 1
          ..color = t.ink.withValues(alpha: 0.45);
        final elbow = p + const Offset(14, -14);
        canvas.drawLine(p + const Offset(4, -4), elbow, lead);
        canvas.drawLine(elbow, elbow + const Offset(12, 0), lead);
        _label(canvas, n.label!, elbow + const Offset(16, -8));
      }
    }
  }

  void _label(Canvas canvas, String s, Offset at) {
    final tp = TextPainter(
      text: TextSpan(
        text: s.toUpperCase(),
        style: skyText(11, 1.4, 0.6).copyWith(color: t.ink),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_GlobePainter old) =>
      old.phase != phase || old.t != t || old.nodes != nodes;
}
