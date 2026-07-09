import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munch_or_dump/core/api/api_exception.dart';
import 'package:munch_or_dump/core/api/munch_api.dart';
import 'package:munch_or_dump/core/api/token_store.dart';
import 'package:munch_or_dump/core/models/profile_update.dart';
import 'package:munch_or_dump/core/models/user.dart';
import 'package:munch_or_dump/core/models/user_profile.dart';
import 'package:munch_or_dump/core/providers.dart';

/// Owns the auth orchestration: trades credentials for a JWT, persists it, and
/// resolves the full [User] from `/auth/me`. Pure logic (no UI), so it's easy
/// to test and keeps [AuthController] focused on state.
class AuthRepository {
  const AuthRepository(this._api, this._tokenStore);

  final MunchApi _api;
  final TokenStore _tokenStore;

  /// Resolve the user from a stored token, or null if there is none / it's
  /// expired. Clears an invalid token so the app starts clean.
  Future<User?> currentUser() async {
    final token = await _tokenStore.read();
    if (token == null || token.isEmpty) return null;
    try {
      return await _api.getMe();
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await _tokenStore.clear();
        return null;
      }
      rethrow;
    }
  }

  Future<User> signInWithEmail(String email, String password) async {
    final token = await _api.login(email, password);
    return _establishSession(token);
  }

  Future<User> completeVerification(String email, String code) async {
    final token = await _api.verifyEmail(email, code);
    return _establishSession(token);
  }

  Future<User> signInWithGoogle(String idToken) async {
    final token = await _api.googleAuth(idToken);
    return _establishSession(token);
  }

  Future<User> signInWithApple(String identityToken, {String? fullName}) async {
    final token = await _api.signInWithApple(identityToken, fullName: fullName);
    return _establishSession(token);
  }

  /// Persist [token] (the request interceptor reads it from storage) and resolve
  /// the full user. If resolving fails for any reason — a non-401 transient
  /// error or a parse failure — clear the token so we never leave a valid
  /// session behind a screen that just reported sign-in failed.
  Future<User> _establishSession(String token) async {
    await _tokenStore.write(token);
    try {
      return await _api.getMe();
    } on Object catch (_) {
      await _tokenStore.clear();
      rethrow;
    }
  }

  Future<void> register(String email, String password) =>
      _api.register(email, password);

  Future<void> resendVerification(String email) =>
      _api.resendVerification(email);

  Future<void> forgotPassword(String email) => _api.forgotPassword(email);

  Future<void> resetPassword(String email, String code, String newPassword) =>
      _api.resetPassword(email, code, newPassword);

  Future<UserProfile> updateProfile(ProfileUpdate update) =>
      _api.updateProfile(update);

  Future<void> signOut() async {
    try {
      await _api.logout();
    } on ApiException {
      // Best-effort server revoke — clear locally regardless.
    }
    await _tokenStore.clear();
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(munchApiProvider),
    ref.watch(tokenStoreProvider),
  ),
);
