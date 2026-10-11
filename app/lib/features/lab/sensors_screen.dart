import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/settings/app_settings.dart';
import '../../core/widgets/direction_hint.dart';
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
      appBar: AppBar(title: const Text('Sensors')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SkyCard(
            title: 'Location',
            icon: Icons.my_location,
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
          const SizedBox(height: 12),
          SkyCard(
            title: 'Device pose',
            subtitle: 'Accelerometer + magnetometer, low-pass filtered',
            icon: Icons.explore,
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
              loading: () => const Text(
                'Waiting for sensors… (no magnetometer on web/emulators — test on a phone)',
              ),
              error: (e, _) => Text('Sensor error: $e'),
            ),
          ),
          const SizedBox(height: 12),
          SkyCard(
            title: 'Compass offset',
            subtitle: 'Magnetic declination + calibration (east positive)',
            icon: Icons.tune,
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
        ],
      ),
    );
  }
}
