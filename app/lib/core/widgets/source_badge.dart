import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../network/provenance.dart';
import '../theme/app_theme.dart';
import 'design_components.dart';
import 'motion.dart';
import 'sky_card.dart';

extension DataOriginStyle on DataOrigin {
  String get label => switch (this) {
    DataOrigin.live => 'Live',
    DataOrigin.cache => 'Saved',
    DataOrigin.mock => 'Sample',
    DataOrigin.computed => 'Computed',
  };

  /// Plain-language version for the quiet footer line.
  String? get friendly => switch (this) {
    DataOrigin.live || DataOrigin.computed => null,
    DataOrigin.cache => 'saved earlier',
    DataOrigin.mock => 'example data',
  };

  IconData get icon => switch (this) {
    DataOrigin.live => Icons.wifi_tethering,
    DataOrigin.cache => Icons.history,
    DataOrigin.mock => Icons.science_outlined,
    DataOrigin.computed => Icons.calculate_outlined,
  };

  /// Only live data is green, so "green" always means "fresh".
  Tone get tone => switch (this) {
    DataOrigin.live => Tone.success,
    DataOrigin.cache => Tone.warning,
    DataOrigin.mock => Tone.neutral,
    DataOrigin.computed => Tone.primary,
  };
}

/// Quiet credit line under any card that shows external or computed data:
/// "From NASA APOD · saved earlier ⓘ". Technical details (origin, time,
/// licence, notes, link) open in a sheet on tap, so they never crowd the UI
/// but are always one tap away.
class SourceBadge extends StatelessWidget {
  const SourceBadge(this.provenance, {super.key});

  final DataProvenance provenance;

  @override
  Widget build(BuildContext context) {
    final t = SkyTokens.of(context);
    final text = Theme.of(context).textTheme;
    final p = provenance;
    final line = ['From ${p.source}', ?p.origin.friendly].join(' · ');

    return Semantics(
      button: true,
      label: '$line. Show source details',
      child: ExcludeSemantics(
        child: InkWell(
          onTap: () => showSourceDetails(context, p),
          borderRadius: BorderRadius.circular(Radii.sm),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 32),
            child: Row(
              children: [
                if (p.origin.friendly != null) ...[
                  Icon(p.origin.icon, size: 14, color: p.origin.tone.of(t)),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    line,
                    style: text.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.info_outline, size: 16, color: t.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full provenance for one piece of data.
Future<void> showSourceDetails(BuildContext context, DataProvenance p) =>
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        final text = Theme.of(context).textTheme;
        final rows = [
          ('Status', p.origin.label),
          (
            'Updated',
            DateFormat.yMMMd().add_Hm().format(p.fetchedAt.toLocal()),
          ),
          if (p.license != null) ('Licence', p.license!),
          if (p.note != null) ('Note', p.note!),
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.xl, 0, Space.xl, Space.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: staggered([
                Row(
                  children: [
                    IconBadge(p.origin.icon, tone: p.origin.tone),
                    const SizedBox(width: Space.md),
                    Expanded(child: Text(p.source, style: text.titleLarge)),
                  ],
                ),
                const SizedBox(height: Space.md),
                for (final (i, (k, v)) in rows.indexed)
                  FactRow(k, v, divider: i < rows.length - 1),
                if (p.url != null) ...[
                  const SizedBox(height: Space.lg),
                  OutlinedButton.icon(
                    onPressed: () => launchUrl(Uri.parse(p.url!)),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Open source'),
                  ),
                ],
              ]),
            ),
          ),
        );
      },
    );
