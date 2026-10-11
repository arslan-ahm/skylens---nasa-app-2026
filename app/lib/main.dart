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
  final store = await LocalStore.open();
  runApp(
    ProviderScope(
      overrides: [localStoreProvider.overrideWithValue(store)],
      child: const SkyLensApp(),
    ),
  );
}
