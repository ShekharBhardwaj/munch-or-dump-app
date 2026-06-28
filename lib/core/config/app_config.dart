/// Compile-time app configuration, injected via `--dart-define-from-file`.
///
/// Run with `flutter run --dart-define-from-file=config/dev.json` (see the
/// Makefile). Values fall back to production defaults so a bare `flutter test`
/// or `flutter run` works without any defines.
abstract final class AppConfig {
  /// Deployment environment: `dev` or `prod`.
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'prod',
  );

  /// Base URL of the Munch or Dump API. All paths are `/auth/*` or `/api/*`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _prodApiBaseUrl,
  );

  /// Google OAuth *server* client ID — used to obtain an id_token the backend
  /// `/auth/google` endpoint can verify. Empty until wired in Phase 1.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  static const String _prodApiBaseUrl =
      'https://1406mo0ze0.execute-api.us-east-1.amazonaws.com/Prod';

  static bool get isProd => environment == 'prod';
  static bool get isDev => environment == 'dev';
}
