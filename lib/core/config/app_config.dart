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

  /// Google OAuth *server* (web) client ID — must equal the backend's
  /// GOOGLE_CLIENT_ID so the id_token audience the backend verifies matches.
  /// When empty, the Google sign-in button is hidden.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  /// Google OAuth *iOS* client ID — the native client used by google_sign_in on
  /// iOS. Its REVERSED_CLIENT_ID must also be added to ios/Runner/Info.plist as
  /// a URL scheme. Leave empty on Android (uses the google-services config).
  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );

  /// Whether Google sign-in is configured (server client ID present).
  static bool get googleSignInEnabled => googleServerClientId.isNotEmpty;

  static const String _prodApiBaseUrl =
      'https://1406mo0ze0.execute-api.us-east-1.amazonaws.com/Prod';

  static bool get isProd => environment == 'prod';
  static bool get isDev => environment == 'dev';
}
