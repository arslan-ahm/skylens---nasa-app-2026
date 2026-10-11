import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/astro/coordinates.dart';
import '../../core/network/provenance.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/cosmos.dart';
import '../../core/widgets/direction_hint.dart';
import '../../core/widgets/observation_form.dart';
import '../../core/widgets/sky_card.dart';
import '../../core/widgets/source_badge.dart';
import '../../core/widgets/states.dart';

/// Design-system gallery (DESIGN.md components) + app-wide display settings.
class UiKitScreen extends ConsumerStatefulWidget {
  const UiKitScreen({super.key});

  @override
  ConsumerState<UiKitScreen> createState() => _UiKitScreenState();
}

class _UiKitScreenState extends ConsumerState<UiKitScreen> {
  int _dot = 1;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final t = SkyTokens.of(context);
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();

    Widget section(String label, Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [CategoryTag(label), const SizedBox(height: 16), child],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('UI kit & settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
        children: [
          // --- Settings -----------------------------------------------------
          section(
            'Theme',
            SegmentedButton<SkyThemeVariant>(
              showSelectedIcon: false,
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
          ),
          section(
            'Text size ${(s.textScale * 100).round()}%',
            Slider(
              value: s.textScale,
              min: 0.9,
              max: 1.6,
              divisions: 7,
              onChanged: (v) =>
                  notifier.update((x) => x.copyWith(textScale: v)),
            ),
          ),
          section(
            'Licences',
            GhostPillButton(
              label: 'Open-source licences',
              onPressed: () =>
                  showLicensePage(context: context, applicationName: 'SkyLens'),
            ),
          ),
          const Divider(),
          const SizedBox(height: 40),

          // --- Hero: headline + globe + CTA + stat strip -------------------
          section(
            'Headline display block',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: GlobeDiagram(
                    size: 260,
                    animate: true,
                    centerLabel: 'You',
                    nodes: [
                      GlobeNode(ring: 0, angleDeg: 20, label: 'Moon'),
                      GlobeNode(ring: 1, angleDeg: 140, label: 'Jupiter'),
                      GlobeNode(
                        ring: 2,
                        angleDeg: -60,
                        label: 'ISS',
                        live: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Know what you see.', style: text.displayLarge),
                const SizedBox(height: 12),
                Text(
                  'Display 60 · weight 400 · tracking 0.04em. Body copy sits '
                  'underneath in Slate.',
                  style: text.bodyLarge!.copyWith(color: t.inkMuted),
                ),
                const SizedBox(height: 24),
                GhostPillButton(label: 'Start sky view', onPressed: () {}),
                const SizedBox(height: 24),
                const StatStrip([
                  ('2,865', 'stars'),
                  ('88', 'constellations'),
                  ('0', 'sign-ups'),
                ]),
              ],
            ),
          ),

          // --- Type scale -------------------------------------------------
          section(
            'Type scale',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (name, style) in [
                  ('Display 60', text.displayLarge!),
                  ('Heading 36', text.headlineLarge!),
                  ('Heading-sm 32', text.headlineMedium!),
                  ('Subheading 24', text.titleLarge!),
                  ('Body 16', text.bodyLarge!),
                  ('Body-sm 14', text.bodyMedium!),
                  ('Caption 12', text.bodySmall!),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      name,
                      style: style,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    ),
                  ),
              ],
            ),
          ),

          // --- Buttons & chips ----------------------------------------------
          section(
            'Ghost pill buttons',
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                GhostPillButton(label: 'Contact us', onPressed: () {}),
                GhostPillButton(
                  label: 'Log',
                  icon: Icons.add,
                  showArrow: false,
                  onPressed: () {},
                ),
                const GhostPillButton(label: 'Disabled', onPressed: null),
                ChoiceChip(
                  label: const Text('Planet'),
                  selected: true,
                  onSelected: (_) {},
                ),
                ChoiceChip(
                  label: const Text('Star'),
                  selected: false,
                  onSelected: (_) {},
                ),
              ],
            ),
          ),

          // --- Cards ------------------------------------------------------
          section(
            'Card surface · case study card',
            Column(
              children: [
                SkyCard(
                  title: 'Jupiter',
                  subtitle: 'Planet · rises 18:12',
                  icon: Icons.public,
                  category: 'Planet',
                  provenance: DataProvenance(
                    source: 'SkyLens astronomy engine',
                    fetchedAt: now,
                    origin: DataOrigin.computed,
                  ),
                  child: const Column(
                    children: [
                      FactRow('Magnitude', '−2.4'),
                      FactRow('Highest', '23:40 · 52°'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const SkyCard(
                  title: 'Where to look',
                  child: DirectionHint(Horizontal(135, 32)),
                ),
              ],
            ),
          ),

          // --- Status & attribution -------------------------------------
          section(
            'Source badges',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    const LiveDot(pulse: true),
                    Text(
                      'Live indicator (Signal Mint, active state only)',
                      style: text.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),

          section(
            'Carousel dots',
            Row(
              children: [
                Text('Step ${_dot + 1} of 6', style: text.bodyLarge),
                const Spacer(),
                CarouselDots(
                  count: 6,
                  index: _dot,
                  onTap: (i) => setState(() => _dot = i),
                ),
              ],
            ),
          ),

          // --- Form -------------------------------------------------------
          section(
            'Observation form',
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ObservationForm(
                  onSubmit: (d) => ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Saved ${d.target}'))),
                ),
              ),
            ),
          ),

          // --- States -----------------------------------------------------
          section(
            'Empty · error · loading',
            Column(
              children: [
                const SizedBox(
                  height: 300,
                  child: Card(
                    child: EmptyState(
                      title: 'No observations yet',
                      message: 'Tap Log to record what you saw.',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 320,
                  child: Card(
                    child: ErrorState(
                      error: 'Network unreachable',
                      onRetry: () {},
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const SizedBox(
                  height: 120,
                  child: Card(
                    child: LoadingState(message: 'Finding your sky…'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
