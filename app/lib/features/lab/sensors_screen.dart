import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/direction_hint.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/sky_card.dart';
import '../../core/widgets/states.dart';

class SensorsScreen extends ConsumerWidget {
  const SensorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(observerLocationProvider);
    final pose = ref.watch(devicePoseProvider);
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Compass')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          Space.lg,
          Space.gutter,
          Space.xxl,
        ),
        children: staggered([
          SkyCard(
            title: 'Where you are',
            icon: Icons.my_location_outlined,
            trailing: IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(observerLocationProvider),
            ),
            child: AsyncView(
              value: loc,
              builder: (l) => Column(
                children: [
                  FactRow('Source', l.sourceLabel),
                  FactRow('Latitude', l.observer.latitude.toStringAsFixed(5)),
                  FactRow('Longitude', l.observer.longitude.toStringAsFixed(5)),
                  if (l.accuracyM != null)
                    FactRow('Accuracy', '±${l.accuracyM!.round()} m'),
                  if (l.label != null) FactRow('Label', l.label!),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.md),
          SkyCard(
            title: 'Where your phone points',
            subtitle: 'Move your phone and watch it follow',
            icon: Icons.explore_outlined,
            child: pose.when(
              data: (p) {
                final cam = p.cameraDirection;
                return Column(
                  children: [
                    FactRow(
                      'Camera azimuth',
                      '${cam.az.toStringAsFixed(1)}° ${cam.compassPoint}',
                    ),
                    FactRow(
                      'Camera altitude',
                      '${cam.alt.toStringAsFixed(1)}°',
                    ),
                    FactRow('Roll', '${p.rollDeg.toStringAsFixed(1)}°'),
                    FactRow(
                      'Compass offset',
                      '${settings.compassOffsetDeg.toStringAsFixed(1)}°',
                    ),
                    const SizedBox(height: 8),
                    DirectionHint(cam),
                  ],
                );
              },
              loading: () => const LoadingState(
                message:
                    'Waiting for sensors. Web builds and emulators have no '
                    'magnetometer, so test on a phone.',
              ),
              error: (e, _) => Text('Sensor error: $e'),
            ),
          ),
          const SizedBox(height: Space.md),
          SkyCard(
            title: 'Fine-tune the compass',
            subtitle: 'Nudge it if the sky looks a little off',
            icon: Icons.tune,
            trailing: Text(
              '${settings.compassOffsetDeg.toStringAsFixed(1)}°',
              style: Theme.of(context).textTheme.titleMedium!
                  .copyWith(fontFeatures: kTabularFigures),
            ),
            child: Slider(
              value: settings.compassOffsetDeg.clamp(-30, 30),
              min: -30,
              max: 30,
              divisions: 120,
              label: '${settings.compassOffsetDeg.toStringAsFixed(1)}°',
              onChanged: (v) => ref
                  .read(appSettingsProvider.notifier)
                  .update((s) => s.copyWith(compassOffsetDeg: v)),
            ),
          ),
        ]),
      ),
    );
  }
}
