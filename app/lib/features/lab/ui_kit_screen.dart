import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/astro/coordinates.dart';
import '../../core/network/provenance.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/design_components.dart';
import '../../core/widgets/direction_hint.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/observation_form.dart';
import '../../core/widgets/sky_card.dart';
import '../../core/widgets/source_badge.dart';
import '../../core/widgets/states.dart';

/// Gallery of every design-system component, in the current theme.
class UiKitScreen extends ConsumerWidget {
  const UiKitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Design gallery')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          0,
          Space.gutter,
          Space.xxl,
        ),
        children: staggered([
          // --- Brand -------------------------------------------------------
          const SectionLabel('Brand'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Row(
                children: [
                  const BrandLockup(caption: 'Personal observatory'),
                  const Spacer(),
                  for (final size in [24.0, 40.0]) ...[
                    SkyLensMark(size: size),
                    const SizedBox(width: Space.sm),
                  ],
                ],
              ),
            ),
          ),

          // --- Type --------------------------------------------------------
          const SectionLabel('Typography · Inter'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (name, style) in [
                    ('Display 32', text.displaySmall!),
                    ('Headline 24', text.headlineSmall!),
                    ('Title 20', text.titleLarge!),
                    ('Title 16', text.titleMedium!),
                    ('Body 16', text.bodyLarge!),
                    ('Body 14', text.bodyMedium!),
                    ('Caption 12', text.bodySmall!),
                    ('LABEL 11', text.labelSmall!),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.sm),
                      child: Text(name, style: style, maxLines: 1),
                    ),
                ],
              ),
            ),
          ),

          // --- Actions -----------------------------------------------------
          const SectionLabel('Buttons'),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              FilledButton(onPressed: () {}, child: const Text('Primary')),
              ElevatedButton(onPressed: () {}, child: const Text('Tonal')),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Secondary'),
              ),
              TextButton(onPressed: () {}, child: const Text('Text')),
              const FilledButton(onPressed: null, child: Text('Disabled')),
            ],
          ),
          const SizedBox(height: Space.md),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              FilterChip(
                label: const Text('Planets'),
                selected: true,
                onSelected: (_) {},
              ),
              FilterChip(
                label: const Text('Stars'),
                selected: false,
                onSelected: (_) {},
              ),
            ],
          ),

          // --- Status ------------------------------------------------------
          const SectionLabel('Status'),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              for (final o in DataOrigin.values)
                StatusPill(o.label, tone: o.tone, icon: o.icon),
              const StatusPill(
                'Demo key',
                tone: Tone.warning,
                icon: Icons.warning_amber_rounded,
              ),
              const StatusPill(
                'Offline',
                tone: Tone.danger,
                icon: Icons.cloud_off_outlined,
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          const MetricRow([
            MetricTile(
              label: 'Stars',
              value: '2,855',
              icon: Icons.star_outline,
              tone: Tone.primary,
            ),
            MetricTile(
              label: 'Clear sky',
              value: '82%',
              icon: Icons.cloud_outlined,
              tone: Tone.success,
            ),
          ]),

          // --- Cards and lists ---------------------------------------------
          const SectionLabel('Cards'),
          SkyCard(
            title: 'Jupiter',
            subtitle: 'Planet · rises 18:12',
            icon: Icons.public,
            provenance: DataProvenance(
              source: 'SkyLens astronomy engine',
              fetchedAt: now,
              origin: DataOrigin.computed,
            ),
            child: const Column(
              children: [
                FactRow('Magnitude', '−2.4'),
                FactRow('Highest', '23:40 · 52°', divider: false),
              ],
            ),
          ),
          const SizedBox(height: Space.md),
          const SkyCard(
            title: 'Where to look',
            icon: Icons.near_me_outlined,
            child: DirectionHint(Horizontal(135, 32)),
          ),
          const SectionLabel('List'),
          GroupCard(
            children: [
              ModuleTile(
                icon: Icons.auto_awesome_outlined,
                title: 'Module tile',
                subtitle: 'Icon badge, title, subtitle, chevron',
                onTap: () {},
              ),
              ModuleTile(
                icon: Icons.satellite_alt_outlined,
                title: 'Second row',
                subtitle: 'Inset divider between rows',
                onTap: () {},
              ),
            ],
          ),
          const SectionLabel('Attribution'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: Column(
                children: [
                  for (final o in DataOrigin.values)
                    SourceBadge(
                      DataProvenance(
                        source: 'NASA APOD',
                        fetchedAt: now,
                        origin: o,
                        license: 'Public domain',
                      ),
                    ),
                ],
              ),
            ),
          ),

          // --- Form --------------------------------------------------------
          const SectionLabel('Form'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Space.lg),
              child: ObservationForm(
                onSubmit: (d) => ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Saved ${d.target}'))),
              ),
            ),
          ),

          // --- States ------------------------------------------------------
          const SectionLabel('Empty · error · loading'),
          const SizedBox(
            height: 260,
            child: Card(
              child: EmptyState(
                title: 'No observations yet',
                message: 'Record what you saw tonight.',
              ),
            ),
          ),
          const SizedBox(height: Space.md),
          SizedBox(
            height: 300,
            child: Card(
              child: ErrorState(
                error: 'Network unreachable. Check your connection.',
                onRetry: () {},
              ),
            ),
          ),
          const SizedBox(height: Space.md),
          const SizedBox(
            height: 140,
            child: Card(child: LoadingState(message: 'Finding your sky…')),
          ),
        ]),
      ),
    );
  }
}
