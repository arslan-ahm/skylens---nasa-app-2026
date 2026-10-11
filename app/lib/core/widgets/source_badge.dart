import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../network/provenance.dart';
import '../theme/app_theme.dart';

/// Compact attribution line: "NASA APOD · Live · 21:04 · Public domain".
/// Put one under every card that shows external or computed data.
class SourceBadge extends StatelessWidget {
  const SourceBadge(this.provenance, {super.key});

  final DataProvenance provenance;

  @override
  Widget build(BuildContext context) {
    final t = SkyTokens.of(context);
    final p = provenance;
    final (originLabel, originColor) = switch (p.origin) {
      DataOrigin.live => ('Live', t.horizon),
      DataOrigin.cache => ('Saved', t.accent),
      DataOrigin.mock => ('Sample', t.warning),
      DataOrigin.computed => ('Computed', t.accent),
    };
    final style = Theme.of(context).textTheme.labelSmall!
        .copyWith(color: t.inkMuted);
    final parts = [
      DateFormat.MMMd().add_Hm().format(p.fetchedAt.toLocal()),
      ?p.license,
      ?p.note,
    ];

    return Semantics(
      label: 'Source: ${p.source}, $originLabel, ${parts.join(', ')}',
      child: InkWell(
        onTap: p.url == null ? null : () => launchUrl(Uri.parse(p.url!)),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(Icons.verified_outlined, size: 14, color: t.inkMuted),
              Text(
                p.source,
                style: style.copyWith(fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: originColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  originLabel,
                  style: style.copyWith(color: originColor),
                ),
              ),
              Text(parts.join(' · '), style: style),
            ],
          ),
        ),
      ),
    );
  }
}
