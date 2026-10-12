import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/providers.dart';
import 'core/storage/local_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Portrait keeps the sensor -> screen mapping simple for AR.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  _registerAssetLicenses();
  final store = await LocalStore.open();
  runApp(
    ProviderScope(
      overrides: [localStoreProvider.overrideWithValue(store)],
      child: const SkyLensApp(),
    ),
  );
}

/// Bundled fonts and data aren't Dart packages, so add their licences to
/// Flutter's licence page (showLicensePage) alongside the packages'.
void _registerAssetLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Inter font',
    ], await rootBundle.loadString('assets/fonts/Inter-OFL.txt'));
    yield const LicenseEntryWithLineBreaks(
      ['HYG star database v4.0'],
      '''
HYG Database by David Nash (astronexus), https://github.com/astronexus/HYG-Database
Licensed under CC BY-SA 4.0: https://creativecommons.org/licenses/by-sa/4.0/
SkyLens bundles a filtered subset (magnitude <= 5.5) in assets/catalog/stars.json.''',
    );
    yield const LicenseEntryWithLineBreaks(
      ['d3-celestial constellations'],
      '''
Copyright (c) 2015, Olaf Frohn. BSD-3-Clause.
https://github.com/ofrohn/d3-celestial
SkyLens bundles converted constellation lines in assets/catalog/constellations.json.''',
    );
  });
}
