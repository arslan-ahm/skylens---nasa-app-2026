import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/astro/coordinates.dart';
import '../../core/network/provenance.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/direction_hint.dart';
import '../../core/widgets/sky_card.dart';
import '../../core/widgets/states.dart';

/// Component gallery + app-wide display settings.
class UiKitScreen extends ConsumerWidget {
  const UiKitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('UI kit & settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Theme', style: text.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<SkyThemeVariant>(
            segments: [
              for (final v in SkyThemeVariant.values)
                ButtonSegment(
                  value: v,
                  label: Text(v.label, textAlign: TextAlign.center),
                ),
            ],
            selected: {s.theme},
            onSelectionChanged: (v) =>
                notifier.update((x) => x.copyWith(theme: v.first)),
          ),
          const SizedBox(height: 16),
          Text(
            'Text size ${(s.textScale * 100).round()}%',
            style: text.titleMedium,
          ),
          Slider(
            value: s.textScale,
            min: 0.9,
            max: 1.6,
            divisions: 7,
            onChanged: (v) => notifier.update((x) => x.copyWith(textScale: v)),
          ),
          const Divider(height: 32),
          SkyCard(
            title: 'SkyCard',
            subtitle: 'Icon, title, subtitle, body, source badge',
            icon: Icons.auto_awesome,
            provenance: DataProvenance(
              source: 'Example source',
              fetchedAt: DateTime.now(),
              license: 'CC BY 4.0',
              origin: DataOrigin.mock,
            ),
            child: const Column(
              children: [
                FactRow('Magnitude', '−2.4'),
                FactRow('Rises', '19:42'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const SkyCard(
            title: 'Direction hint',
            icon: Icons.explore_outlined,
            child: DirectionHint(Horizontal(135, 32)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: () {},
                child: const Text('Primary action'),
              ),
              OutlinedButton(onPressed: () {}, child: const Text('Secondary')),
              const Chip(label: Text('Planet')),
            ],
          ),
          const SizedBox(height: 12),
          const SizedBox(
            height: 220,
            child: Card(
              child: EmptyState(
                title: 'Empty state',
                message: 'Nothing here yet.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: Card(
              child: ErrorState(error: 'Network unreachable', onRetry: () {}),
            ),
          ),
          const SizedBox(height: 12),
          const SizedBox(
            height: 120,
            child: Card(child: LoadingState(message: 'Loading…')),
          ),
        ],
      ),
    );
  }
}
