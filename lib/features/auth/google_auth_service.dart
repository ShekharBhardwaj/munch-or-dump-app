import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:munch_or_dump/core/api/api_exception.dart';
import 'package:munch_or_dump/core/config/app_config.dart';

/// Thrown when the user dismisses the Google sign-in sheet — handled silently.
class GoogleSignInCancelled implements Exception {
  const GoogleSignInCancelled();
}

/// Runs the native Google sign-in and returns the OpenID id_token to exchange at
/// `/auth/google`. Lazily initializes the SDK with the configured client IDs;
/// `serverClientId` must equal the backend's GOOGLE_CLIENT_ID so the id_token
/// audience the backend verifies matches.
class GoogleAuthService {
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      clientId: AppConfig.googleIosClientId.isEmpty
          ? null
          : AppConfig.googleIosClientId,
      serverClientId: AppConfig.googleServerClientId.isEmpty
          ? null
          : AppConfig.googleServerClientId,
    );
    _initialized = true;
  }

  /// Interactive sign-in → id_token. Throws [GoogleSignInCancelled] on cancel,
  /// or [ApiException] on any other failure.
  Future<String> signIn() async {
    await _ensureInitialized();
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw const ApiException(
        'Google sign-in isn’t available on this device.',
      );
    }
    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const GoogleSignInCancelled();
      }
      throw ApiException(e.description ?? 'Google sign-in failed.');
    }
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const ApiException('Google sign-in failed — no token returned.');
    }
    return idToken;
  }

  /// Best-effort Google session sign-out (keeps account-switch clean).
  Future<void> signOut() async {
    if (!_initialized) return;
    try {
      await GoogleSignIn.instance.signOut();
    } on Object {
      // ignore — the app JWT logout is what matters
    }
  }
}

final googleAuthServiceProvider = Provider<GoogleAuthService>(
  (ref) => GoogleAuthService(),
);
