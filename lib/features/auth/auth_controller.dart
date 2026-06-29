import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munch_or_dump/core/models/profile_update.dart';
import 'package:munch_or_dump/core/models/user.dart';
import 'package:munch_or_dump/features/auth/auth_repository.dart';
import 'package:munch_or_dump/features/auth/google_auth_service.dart';

/// Global session state: `AsyncValue<User?>` where a non-null value means signed
/// in, null means signed out, loading is the launch bootstrap, and error is a
/// bootstrap failure. Roughly the web AuthContext.
///
/// Form-level errors (bad password, taken email) are NOT funneled into this
/// state — the auth methods rethrow [ApiException] so screens can show inline
/// errors while the session state only flips on actual success.
class AuthController extends AsyncNotifier<User?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<User?> build() => _repo.currentUser();

  Future<User> signInWithEmail(String email, String password) async {
    final user = await _repo.signInWithEmail(email, password);
    state = AsyncData<User?>(user);
    return user;
  }

  Future<User> completeVerification(String email, String code) async {
    final user = await _repo.completeVerification(email, code);
    state = AsyncData<User?>(user);
    return user;
  }

  Future<User> signInWithGoogle(String idToken) async {
    final user = await _repo.signInWithGoogle(idToken);
    state = AsyncData<User?>(user);
    return user;
  }

  Future<void> register(String email, String password) =>
      _repo.register(email, password);

  Future<void> resendVerification(String email) =>
      _repo.resendVerification(email);

  Future<void> forgotPassword(String email) => _repo.forgotPassword(email);

  Future<void> resetPassword(String email, String code, String newPassword) =>
      _repo.resetPassword(email, code, newPassword);

  Future<void> updateProfile(ProfileUpdate update) async {
    await _repo.updateProfile(update);
    state = AsyncData<User?>(await _repo.currentUser());
  }

  Future<void> refresh() async {
    state = AsyncData<User?>(await _repo.currentUser());
  }

  Future<void> signOut() async {
    await _repo.signOut();
    await ref.read(googleAuthServiceProvider).signOut();
    state = const AsyncData<User?>(null);
  }

  /// Invoked when any request returns 401 (the token is already cleared by the
  /// dio interceptor). Flip to signed-out, but only if we currently hold a
  /// session — guards against re-entrancy during the launch bootstrap.
  void onSessionExpired() {
    final current = state;
    if (current is AsyncData<User?> && current.value != null) {
      state = const AsyncData<User?>(null);
    }
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, User?>(
  AuthController.new,
);
