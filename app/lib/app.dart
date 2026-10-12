import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'features/lab/settings_screen.dart';
import 'features/lab/ui_kit_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/splash/splash_screen.dart';

// Splash â†’ bottom-tab shell. Camera and compass open full screen over the
// tabs (the camera never keeps running in a hidden tab).
// On hackathon day: replace the tabs with the product's own sections and
// keep these Lab screens reachable from Settings â†’ For developers.
const _tabs = [
  ShellTab('Explore', Icons.explore_outlined, Icons.explore),
  ShellTab('Sky', Icons.auto_awesome_outlined, Icons.auto_awesome),
  ShellTab('News', Icons.rocket_launch_outlined, Icons.rocket_launch),
  ShellTab('Diary', Icons.menu_book_outlined, Icons.menu_book),
  ShellTab('Settings', Icons.settings_outlined, Icons.settings),
];

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
    StatefulShellRoute(
      builder: (_, _, shell) => shell,
      navigatorContainerBuilder: (_, shell, children) =>
          AppShell(shell: shell, tabs: _tabs, children: children),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/explore', builder: (_, _) => const LabHomeScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/sky', builder: (_, _) => const SkyEngineScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/news', builder: (_, _) => const NasaScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/diary', builder: (_, _) => const LogbookScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (_, _) => const SettingsScreen(),
              routes: [
                GoRoute(path: 'design', builder: (_, _) => const UiKitScreen()),
              ],
            ),
          ],
        ),
      ],
    ),
    GoRoute(path: '/camera', builder: (_, _) => const PointingScreen()),
    GoRoute(path: '/compass', builder: (_, _) => const SensorsScreen()),
    // Old Lab links (docs, bookmarks) still work.
    GoRoute(
      path: '/lab',
      redirect: (_, state) => switch (state.uri.path) {
        '/lab/sky' => '/sky',
        '/lab/pointing' => '/camera',
        '/lab/sensors' => '/compass',
        '/lab/nasa' => '/news',
        '/lab/logbook' => '/diary',
        '/lab/ui' => '/settings',
        _ => '/explore',
      },
      routes: [
        for (final p in ['sky', 'pointing', 'sensors', 'nasa', 'logbook', 'ui'])
          GoRoute(
            path: p,
            redirect: (_, _) => null,
            builder: (_, _) => const SizedBox(),
          ),
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
      builder: (context, child) {
        final bg = SkyTokens.of(context).bg;
        // System bars blend into the app background in every theme.
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: bg,
            systemNavigationBarColor: bg,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(settings.textScale)),
            child: child!,
          ),
        );
      },
    );
  }
}
