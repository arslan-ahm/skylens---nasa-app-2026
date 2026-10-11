import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/cosmos.dart';

/// Dev Lab: one screen per infrastructure piece, to verify it on a real
/// device. Keep it as a hidden debug menu once the product shell exists.
class LabHomeScreen extends StatelessWidget {
  const LabHomeScreen({super.key});

  static const _entries = [
    (
      '/lab/sky',
      Icons.auto_awesome_outlined,
      'Sky engine',
      'Positions, rise/set, sky chart, time travel',
      'Astronomy',
    ),
    (
      '/lab/pointing',
      Icons.camera_alt_outlined,
      'Pointing / AR test',
      'Camera + sensor overlay, FOV and compass calibration',
      'Sensors',
    ),
    (
      '/lab/sensors',
      Icons.explore_outlined,
      'Sensors',
      'Location source, raw pose, compass offset',
      'Sensors',
    ),
    (
      '/lab/nasa',
      Icons.rocket_launch_outlined,
      'NASA & open data',
      'APOD, NeoWs, DONKI, Image Library, weather',
      'Live data',
    ),
    (
      '/lab/logbook',
      Icons.menu_book_outlined,
      'Logbook',
      'Local observation storage and CSV export',
      'Storage',
    ),
    (
      '/lab/ui',
      Icons.palette_outlined,
      'UI kit & settings',
      'Design system components, themes, text size',
      'Design',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = SkyTokens.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SKYLENS',
          style: skyText(16, 1.6, 4).copyWith(color: t.ink),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: CategoryTag('Dev Lab')),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionHeader(
                  eyebrow: 'Pre-event toolkit',
                  title: 'Every building block, testable on a phone.',
                ),
              ),
              const SizedBox(width: 12),
              GlobeDiagram(
                size: 120,
                rings: 2,
                animate: true,
                nodes: const [
                  GlobeNode(ring: 1, angleDeg: -40, live: true),
                  GlobeNode(ring: 0, angleDeg: 150),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          StatStrip([
            ('6', 'labs'),
            (AppConfig.dataMode, 'data mode'),
            (AppConfig.usingDemoKey ? 'Demo' : 'Own', 'NASA key'),
          ]),
          if (AppConfig.usingDemoKey) ...[
            const SizedBox(height: 8),
            Text(
              'DEMO_KEY is limited to 30 requests per hour.',
              style: text.bodySmall!.copyWith(color: t.inkMuted),
            ),
          ],
          const SizedBox(height: 32),
          for (final (path, icon, title, subtitle, category) in _entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => context.push(path),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(icon, color: t.ink),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: text.titleLarge),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: text.bodyMedium!.copyWith(
                                  color: t.inkMuted,
                                ),
                              ),
                              const SizedBox(height: 12),
                              CategoryTag(category),
                            ],
                          ),
                        ),
                        Text('›', style: text.titleLarge),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
