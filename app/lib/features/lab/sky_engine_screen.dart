import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/astro/rise_set.dart';
import '../../core/astro/sky_engine.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
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

  @override
  Widget build(BuildContext context) {
    final snap = ref.watch(skySnapshotProvider);
    final catalog = ref.watch(skyCatalogProvider).value;
    final loc = ref.watch(observerLocationProvider).value;
    final t = SkyTokens.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Sky engine')),
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
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${DateFormat.yMMMd().add_Hm().format(s.time)} · '
                '${loc?.sourceLabel ?? ''} ${s.observer.latitude.toStringAsFixed(2)}, ${s.observer.longitude.toStringAsFixed(2)}',
                style: TextStyle(color: t.inkMuted),
              ),
              Text(
                '${s.twilight.label} · ${s.moonPhase.name} (${(s.moonPhase.illuminatedFraction * 100).round()}% lit)',
              ),
              for (final c in darkness)
                Text(
                  '${c.rising ? 'Astronomical dawn' : 'Full darkness from'} ${DateFormat.Hm().format(c.time.toLocal())}',
                  style: TextStyle(color: t.inkMuted),
                ),
              const SizedBox(height: 12),
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
                  const Icon(Icons.schedule, size: 18),
                  Expanded(
                    child: Slider(
                      value: _hoursOffset,
                      min: -12,
                      max: 24,
                      divisions: 72,
                      label:
                          '${_hoursOffset >= 0 ? '+' : ''}${_hoursOffset.toStringAsFixed(1)} h',
                      onChanged: (v) {
                        setState(() => _hoursOffset = v);
                        ref
                            .read(timeOverrideProvider.notifier)
                            .set(
                              v == 0
                                  ? null
                                  : DateTime.now().add(
                                      Duration(minutes: (v * 60).round()),
                                    ),
                            );
                      },
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _hoursOffset = 0);
                      ref.read(timeOverrideProvider.notifier).set(null);
                    },
                    child: const Text('Now'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Above the horizon (${s.aboveHorizon.length} objects)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              for (final o in up)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(iconForObject(o), color: colorForObject(o, t)),
                  title: Text(o.name),
                  subtitle: Text(
                    '${o.horizontal.compassPoint} · alt ${o.horizontal.alt.toStringAsFixed(1)}° · mag ${o.magnitude.toStringAsFixed(1)}',
                  ),
                  onTap: () => _open(o),
                ),
            ],
          );
        },
      ),
    );
  }
}
