import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/astro/rise_set.dart';
import '../../core/astro/sky_engine.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/design_components.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/object_sheet.dart';
import '../../core/widgets/sky_dome.dart';
import '../../core/widgets/states.dart';

class SkyEngineScreen extends ConsumerStatefulWidget {
  const SkyEngineScreen({super.key});

  @override
  ConsumerState<SkyEngineScreen> createState() => _SkyEngineScreenState();
}

class _SkyEngineScreenState extends ConsumerState<SkyEngineScreen> {
  String? _selected;
  double _hoursOffset = 0;

  void _open(SkyObject o) {
    setState(() => _selected = o.id);
    final loc = ref.read(observerLocationProvider).value;
    if (loc == null) return;
    final rs = ref
        .read(skyEngineProvider)
        .riseSetFor(o.id, loc.observer, DateTime.now());
    showSkyObjectSheet(context, object: o, riseSet: rs);
  }

  void _setOffset(double v) {
    setState(() => _hoursOffset = v);
    ref
        .read(timeOverrideProvider.notifier)
        .set(
          v == 0
              ? null
              : DateTime.now().add(Duration(minutes: (v * 60).round())),
        );
  }

  @override
  Widget build(BuildContext context) {
    final snap = ref.watch(skySnapshotProvider);
    final catalog = ref.watch(skyCatalogProvider).value;
    final loc = ref.watch(observerLocationProvider).value;
    final t = SkyTokens.of(context);
    final text = Theme.of(context).textTheme;
    final offset = _hoursOffset == 0
        ? 'Now'
        : '${_hoursOffset > 0 ? '+' : ''}${_hoursOffset.toStringAsFixed(1)} h';

    return Scaffold(
      appBar: AppBar(title: const Text('Sky map')),
      body: AsyncView(
        value: snap,
        loadingMessage: 'Finding your sky…',
        builder: (s) {
          final up = s.aboveHorizon
              .where((o) => o.kind != SkyObjectKind.star || o.magnitude < 2)
              .toList();
          final darkness = loc == null
              ? const <HorizonCrossing>[]
              : ref
                    .read(skyEngineProvider)
                    .sunCrossings(
                      loc.observer,
                      DateTime.now(),
                      Horizons.astronomicalTwilight,
                    );
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              Space.gutter,
              Space.lg,
              Space.gutter,
              Space.xxl,
            ),
            children: staggered([
              MetricRow([
                MetricTile(
                  label: s.twilight.label,
                  value: DateFormat.Hm().format(s.time),
                  icon: Icons.schedule,
                  tone: Tone.primary,
                ),
                MetricTile(
                  label: s.moonPhase.name,
                  value:
                      '${(s.moonPhase.illuminatedFraction * 100).round()}% lit',
                  icon: Icons.dark_mode_outlined,
                  tone: Tone.primary,
                ),
              ]),
              const SizedBox(height: Space.md),
              _InfoLine(
                Icons.place_outlined,
                '${loc?.sourceLabel ?? 'Location'} · '
                '${s.observer.latitude.toStringAsFixed(2)}°, '
                '${s.observer.longitude.toStringAsFixed(2)}°',
              ),
              for (final c in darkness)
                _InfoLine(
                  c.rising ? Icons.wb_twilight : Icons.nights_stay_outlined,
                  '${c.rising ? 'Astronomical dawn' : 'Full darkness from'} '
                  '${DateFormat.Hm().format(c.time.toLocal())}',
                ),
              const SectionLabel('Sky chart'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(Space.sm),
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: SkyDome(
                          snapshot: s,
                          constellations: catalog?.constellations ?? const [],
                          selectedId: _selected,
                          onSelect: _open,
                        ),
                      ),
                      Row(
                        children: [
                          const SizedBox(width: Space.sm),
                          Icon(Icons.history_toggle_off, color: t.textMuted),
                          Expanded(
                            child: Slider(
                              value: _hoursOffset,
                              min: -12,
                              max: 24,
                              divisions: 72,
                              label: offset,
                              semanticFormatterCallback: (_) =>
                                  'Time offset $offset',
                              onChanged: _setOffset,
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: TextButton(
                              onPressed: _hoursOffset == 0
                                  ? null
                                  : () => _setOffset(0),
                              child: Text(
                                offset,
                                style: const TextStyle(
                                  fontFeatures: kTabularFigures,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SectionLabel(
                'Above the horizon',
                trailing: Text(
                  '${s.aboveHorizon.length} objects',
                  style: text.labelMedium!.copyWith(color: t.textMuted),
                ),
              ),
              GroupCard(
                children: [
                  for (final o in up)
                    ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorForObject(o, t).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(Radii.md),
                        ),
                        child: Icon(
                          iconForObject(o),
                          size: 20,
                          color: colorForObject(o, t),
                        ),
                      ),
                      title: Text(o.name),
                      subtitle: Text(
                        '${o.horizontal.compassPoint} · '
                        '${o.horizontal.alt.toStringAsFixed(1)}° up · '
                        'mag ${o.magnitude.toStringAsFixed(1)}',
                        style: text.bodyMedium!.copyWith(
                          color: t.textMuted,
                          fontFeatures: kTabularFigures,
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right, color: t.textMuted),
                      onTap: () => _open(o),
                    ),
                ],
              ),
            ]),
          );
        },
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = SkyTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: Space.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: t.textMuted),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall!
                  .copyWith(fontFeatures: kTabularFigures),
            ),
          ),
        ],
      ),
    );
  }
}
