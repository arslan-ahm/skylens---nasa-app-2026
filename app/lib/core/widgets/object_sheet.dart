import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../astro/rise_set.dart';
import '../astro/sky_engine.dart';
import '../network/provenance.dart';
import '../theme/app_theme.dart';
import 'design_components.dart';
import 'direction_hint.dart';
import 'sky_card.dart';
import 'source_badge.dart';

/// Sky-chart colour for an object (monochrome in Space; tinted in the
/// accessibility themes).
Color colorForObject(SkyObject o, SkyTokens t) => switch (o.kind) {
  SkyObjectKind.sun => t.sun,
  SkyObjectKind.moon => t.moon,
  SkyObjectKind.planet => t.planet,
  SkyObjectKind.star => t.star,
};

IconData iconForObject(SkyObject o) => switch (o.kind) {
  SkyObjectKind.sun => Icons.wb_sunny_outlined,
  SkyObjectKind.moon => Icons.dark_mode_outlined,
  SkyObjectKind.planet => Icons.public,
  SkyObjectKind.star => Icons.star_outline,
};

String kindLabel(SkyObject o) => switch (o.kind) {
  SkyObjectKind.sun => 'Star · our Sun',
  SkyObjectKind.moon => 'Natural satellite',
  SkyObjectKind.planet => 'Planet',
  SkyObjectKind.star =>
    o.constellation == null ? 'Star' : 'Star in ${o.constellation}',
};

/// Generic detail sheet for any sky object. [extra] lets features append
/// their own sections (NASA imagery, log button, AI explanation...).
Future<void> showSkyObjectSheet(
  BuildContext context, {
  required SkyObject object,
  RiseSet? riseSet,
  List<Widget> extra = const [],
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.55,
    maxChildSize: 0.95,
    builder: (context, scroll) =>
        _ObjectSheetBody(object, riseSet, extra, scroll),
  ),
);

class _ObjectSheetBody extends StatelessWidget {
  const _ObjectSheetBody(this.o, this.rs, this.extra, this.scroll);

  final SkyObject o;
  final RiseSet? rs;
  final List<Widget> extra;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final hm = DateFormat.Hm();
    String fmt(DateTime? d) => d == null ? '—' : hm.format(d.toLocal());

    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        CategoryTag(kindLabel(o)),
        const SizedBox(height: 8),
        Semantics(
          header: true,
          child: Text(o.name, style: text.headlineMedium),
        ),
        const SizedBox(height: 24),
        DirectionHint(o.horizontal),
        const SizedBox(height: 16),
        FactRow('Altitude', '${o.horizontal.alt.toStringAsFixed(1)}°'),
        FactRow(
          'Azimuth',
          '${o.horizontal.az.toStringAsFixed(1)}° ${o.horizontal.compassPoint}',
        ),
        FactRow('Brightness (magnitude)', o.magnitude.toStringAsFixed(1)),
        if (o.distanceKm != null)
          FactRow(
            'Distance',
            o.distanceKm! > 1e7
                ? '${(o.distanceKm! / 149597870.7).toStringAsFixed(3)} AU'
                : '${NumberFormat.decimalPattern().format(o.distanceKm!.round())} km',
          ),
        if (rs != null) ...[
          if (rs!.alwaysUp)
            const FactRow('Visibility', 'Up all day (circumpolar)'),
          if (rs!.alwaysDown)
            const FactRow('Visibility', 'Does not rise today'),
          if (!rs!.alwaysUp && !rs!.alwaysDown) ...[
            FactRow('Rises', fmt(rs!.rise)),
            FactRow('Sets', fmt(rs!.set)),
          ],
          FactRow(
            'Highest',
            '${fmt(rs!.transit)} at ${rs!.transitAltitude.toStringAsFixed(0)}°',
          ),
        ],
        const SizedBox(height: 16),
        SourceBadge(
          DataProvenance(
            source: 'SkyLens astronomy engine',
            fetchedAt: DateTime.now(),
            origin: DataOrigin.computed,
            note: 'Positions accurate to ~1′ (Moon ~3′)',
          ),
        ),
        ...extra,
      ],
    );
  }
}
