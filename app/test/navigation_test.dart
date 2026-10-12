import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skylens/core/theme/app_theme.dart';
import 'package:skylens/features/shell/app_shell.dart';
import 'package:skylens/features/splash/splash_screen.dart';

Widget _app(GoRouter router) => MaterialApp.router(
  theme: buildSkyTheme(SkyThemeVariant.space),
  routerConfig: router,
);

void main() {
  testWidgets('splash: rocket button leads to the next screen', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const SplashScreen(next: '/home'),
        ),
        GoRoute(path: '/home', builder: (_, _) => const Text('HOME')),
      ],
    );
    await tester.pumpWidget(_app(router));
    await tester.pump(const Duration(seconds: 3)); // intro
    await tester.tap(find.text('Start exploring'));
    await tester.pump(const Duration(seconds: 1)); // rocket launch
    await tester.pump(const Duration(seconds: 1)); // page transition
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('shell: tabs switch and keep the bar', (tester) async {
    final router = GoRouter(
      initialLocation: '/a',
      routes: [
        StatefulShellRoute(
          builder: (_, _, shell) => shell,
          navigatorContainerBuilder: (_, shell, children) => AppShell(
            shell: shell,
            tabs: const [
              ShellTab('First', Icons.star_outline, Icons.star),
              ShellTab('Second', Icons.circle_outlined, Icons.circle),
            ],
            children: children,
          ),
          branches: [
            StatefulShellBranch(
              routes: [GoRoute(path: '/a', builder: (_, _) => const Text('A'))],
            ),
            StatefulShellBranch(
              routes: [GoRoute(path: '/b', builder: (_, _) => const Text('B'))],
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);
    await tester.tap(find.text('Second'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/b');
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
