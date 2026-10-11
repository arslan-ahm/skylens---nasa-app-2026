import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/settings/app_settings.dart';
import 'core/theme/app_theme.dart';
import 'features/lab/lab_home_screen.dart';
import 'features/lab/logbook_screen.dart';
import 'features/lab/nasa_screen.dart';
import 'features/lab/pointing_screen.dart';
import 'features/lab/sensors_screen.dart';
import 'features/lab/sky_engine_screen.dart';
import 'features/lab/ui_kit_screen.dart';

// On hackathon day: put the product shell at '/' and keep the Lab at '/lab'.
final _router = GoRouter(
  initialLocation: '/lab',
  routes: [
    GoRoute(path: '/', redirect: (_, _) => '/lab'),
    GoRoute(
      path: '/lab',
      builder: (_, _) => const LabHomeScreen(),
      routes: [
        GoRoute(path: 'sky', builder: (_, _) => const SkyEngineScreen()),
        GoRoute(path: 'pointing', builder: (_, _) => const PointingScreen()),
        GoRoute(path: 'sensors', builder: (_, _) => const SensorsScreen()),
        GoRoute(path: 'nasa', builder: (_, _) => const NasaScreen()),
        GoRoute(path: 'logbook', builder: (_, _) => const LogbookScreen()),
        GoRoute(path: 'ui', builder: (_, _) => const UiKitScreen()),
      ],
    ),
  ],
);

class SkyLensApp extends ConsumerWidget {
  const SkyLensApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    return MaterialApp.router(
      title: 'SkyLens',
      debugShowCheckedModeBanner: false,
      theme: buildSkyTheme(settings.theme),
      routerConfig: _router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(settings.textScale)),
        child: child!,
      ),
    );
  }
}
