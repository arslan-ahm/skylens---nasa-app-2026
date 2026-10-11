import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../network/provenance.dart';
import '../theme/app_theme.dart';
import 'cosmos.dart';

/// Compact attribution line: "● NASA APOD · LIVE · Oct 11 21:04 · licence".
/// Put one under every card that shows external or computed data.
///
/// Origin is shown as a dot plus a word (colour never carries meaning
/// alone): Live = Signal Mint dot, Saved = white ring, Sample = Ash dot,
/// Computed = white dot.
class SourceBadge extends StatelessWidget {
  const SourceBadge(this.provenance, {super.key});

  final DataProvenance provenance;

  @override
  Widget build(BuildContext context) {
    final t = SkyTokens.of(context);
    final p = provenance;
    final originLabel = switch (p.origin) {
      DataOrigin.live => 'Live',
      DataOrigin.cache => 'Saved',
      DataOrigin.mock => 'Sample',
      DataOrigin.computed => 'Computed',
    };
    final dot = switch (p.origin) {
      DataOrigin.live => const LiveDot(size: 7),
      DataOrigin.cache => _Ring(color: t.ink),
      DataOrigin.mock => LiveDot(size: 7, color: t.inkFaint),
      DataOrigin.computed => LiveDot(size: 7, color: t.ink),
    };
    final style = skyText(12, 1.5, 0.24).copyWith(color: t.inkMuted);
    final meta = [
      DateFormat.MMMd().add_Hm().format(p.fetchedAt.toLocal()),
      ?p.license,
      ?p.note,
    ];

    return Semantics(
      label: 'Source: ${p.source}, $originLabel, ${meta.join(', ')}',
      link: p.url != null,
      child: InkWell(
        onTap: p.url == null ? null : () => launchUrl(Uri.parse(p.url!)),
        borderRadius: BorderRadius.circular(10),
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                dot,
                Text(p.source, style: style.copyWith(color: t.ink)),
                Text(
                  '·  ${originLabel.toUpperCase()}',
                  style: style.copyWith(letterSpacing: 0.6),
                ),
                Text('·  ${meta.join('  ·  ')}', style: style),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 21,
    child: Center(
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.2),
        ),
      ),
    ),
  );
}
