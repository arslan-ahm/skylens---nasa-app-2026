/// Build-time configuration via `--dart-define` / `--dart-define-from-file`.
///
///   flutter run --dart-define=NASA_API_KEY=xxxx --dart-define=DATA_MODE=mock
///   flutter run --dart-define-from-file=.env.json
abstract final class AppConfig {
  /// api.nasa.gov key. DEMO_KEY works but is limited to 30 req/h per IP.
  static const nasaApiKey = String.fromEnvironment(
    'NASA_API_KEY',
    defaultValue: 'DEMO_KEY',
  );

  /// `live` (network, falling back to cache then mock) or `mock` (fixtures
  /// only — use for demos with no connectivity and for widget tests).
  static const dataMode = String.fromEnvironment(
    'DATA_MODE',
    defaultValue: 'live',
  );

  static bool get useMockData => dataMode == 'mock';

  static bool get usingDemoKey => nasaApiKey == 'DEMO_KEY';
}
