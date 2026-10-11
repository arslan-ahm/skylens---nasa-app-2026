import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';

/// Dev Lab: one screen per infrastructure piece, to verify it on a real
/// device. Keep it as a hidden debug menu once the product shell exists.
class LabHomeScreen extends StatelessWidget {
  const LabHomeScreen({super.key});

  static const _entries = [
    (
      '/lab/sky',
      Icons.auto_awesome,
      'Sky engine',
      'Positions, rise/set, sky chart, time travel',
    ),
    (
      '/lab/pointing',
      Icons.camera_alt_outlined,
      'Pointing / AR test',
      'Camera + sensor overlay, FOV & compass calibration',
    ),
    (
      '/lab/sensors',
      Icons.explore_outlined,
      'Sensors',
      'Location source, raw pose, compass',
    ),
    (
      '/lab/nasa',
      Icons.rocket_launch_outlined,
      'NASA & open data',
      'APOD, NeoWs, DONKI, Image Library, weather',
    ),
    (
      '/lab/logbook',
      Icons.menu_book_outlined,
      'Logbook',
      'Local observation storage + CSV export',
    ),
    (
      '/lab/ui',
      Icons.palette_outlined,
      'UI kit & settings',
      'Components, themes, text size',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = SkyTokens.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('SkyLens · Dev Lab')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Data mode: ${AppConfig.dataMode}'
            '${AppConfig.usingDemoKey ? ' · NASA DEMO_KEY (30 req/h)' : ' · personal NASA key'}',
            style: TextStyle(color: t.inkMuted),
          ),
          const SizedBox(height: 12),
          for (final (path, icon, title, subtitle) in _entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  leading: Icon(icon, color: t.accent),
                  title: Text(title),
                  subtitle: Text(subtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(path),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
