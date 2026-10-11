import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// Thin wrapper over Hive CE boxes. Values are JSON-like maps/lists/primitives
/// so no type adapters or code generation are needed. Works on web too.
class LocalStore {
  LocalStore._(this.settings, this.cache, this.logbook);

  final Box<dynamic> settings;
  final Box<dynamic> cache;
  final Box<dynamic> logbook;

  static Future<LocalStore> open() async {
    await Hive.initFlutter('skylens');
    return LocalStore._(
      await Hive.openBox<dynamic>('settings'),
      await Hive.openBox<dynamic>('cache'),
      await Hive.openBox<dynamic>('logbook'),
    );
  }
}
