import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:skylens/core/theme/app_theme.dart';
import 'package:skylens/core/widgets/observation_form.dart';
import 'package:skylens/features/lab/lab_home_screen.dart';

Widget _wrap(Widget child) => ProviderScope(
  child: MaterialApp(theme: buildSkyTheme(SkyThemeVariant.space), home: child),
);

void main() {
  setUpAll(
    () => Hive.init(Directory.systemTemp.createTempSync('skylens_smoke').path),
  );

  testWidgets('Lab home lists every lab', (tester) async {
    // Tall phone viewport so the lazy list builds every entry.
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_wrap(const LabHomeScreen()));
    await tester.pump(const Duration(seconds: 1));
    for (final title in [
      'Sky map',
      'Sky camera',
      'Compass',
      'Space news',
      'Sky diary',
      'Settings',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
  });

  testWidgets('every theme variant builds', (tester) async {
    for (final v in SkyThemeVariant.values) {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildSkyTheme(v),
            home: const LabHomeScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(LabHomeScreen), findsOneWidget);
    }
  });

  testWidgets('observation form validates and submits', (tester) async {
    ObservationDraft? saved;
    await tester.pumpWidget(
      _wrap(
        Scaffold(
          body: SingleChildScrollView(
            child: ObservationForm(onSubmit: (d) => saved = d),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Save observation'));
    await tester.pump();
    expect(find.text('Required'), findsOneWidget);
    expect(saved, isNull);

    await tester.enterText(find.byType(TextFormField).first, 'Moon');
    await tester.tap(find.text('Save observation'));
    await tester.pump();
    expect(saved?.target, 'Moon');
    expect(saved?.equipment, 'Naked eye');
  });
}
