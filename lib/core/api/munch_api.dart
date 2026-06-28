import 'package:dio/dio.dart';
import 'package:munch_or_dump/core/api/api_client.dart';
import 'package:munch_or_dump/core/api/api_exception.dart';
import 'package:munch_or_dump/core/models/profile_update.dart';
import 'package:munch_or_dump/core/models/user.dart';
import 'package:munch_or_dump/core/models/user_profile.dart';

/// Typed client over the Munch or Dump API.
///
/// Mirrors the web app's `munchAPI` surface (`src/api/client.js`) so the two
/// clients stay recognizably the same. Phase 1 implements the full auth spine;
/// catalog/scan/analyze endpoints land in Phase 2+.
class MunchApi {
  const MunchApi(this._dio);

  final Dio _dio;

  // ── Auth ────────────────────────────────────────────────────────────────────

  /// GET `/auth/me` — the full current user. Throws [ApiException] (401 if the
  /// session is missing or expired).
  Future<User> getMe() => _get('/auth/me', User.fromJson);

  /// POST `/auth/login` — returns the JWT. On a 403 with
  /// `requires_verification`, the email is unverified (see [ApiException.data]).
  Future<String> login(String email, String password) async {
    final res = await _post('/auth/login', <String, dynamic>{
      'email': email,
      'password': password,
    });
    return _requireToken(res);
  }

  /// POST `/auth/register` — creates an unverified account and emails a 6-digit
  /// code. No token is issued until [verifyEmail] succeeds. 409 if already taken.
  Future<void> register(String email, String password) => _post(
    '/auth/register',
    <String, dynamic>{'email': email, 'password': password},
  );

  /// POST `/auth/verify-email` — confirms the code and returns the JWT.
  Future<String> verifyEmail(String email, String code) async {
    final res = await _post('/auth/verify-email', <String, dynamic>{
      'email': email,
      'code': code,
    });
    return _requireToken(res);
  }

  /// POST `/auth/resend-verification`.
  Future<void> resendVerification(String email) =>
      _post('/auth/resend-verification', <String, dynamic>{'email': email});

  /// POST `/auth/forgot-password` — always succeeds (no account-existence leak).
  Future<void> forgotPassword(String email) =>
      _post('/auth/forgot-password', <String, dynamic>{'email': email});

  /// POST `/auth/reset-password` — sets a new password from the emailed code.
  Future<void> resetPassword(String email, String code, String newPassword) =>
      _post('/auth/reset-password', <String, dynamic>{
        'email': email,
        'code': code,
        'new_password': newPassword,
      });

  /// POST `/auth/google` — exchanges a Google id_token for the JWT. Requires the
  /// backend to have GOOGLE_CLIENT_ID configured (it fails closed otherwise).
  Future<String> googleAuth(String idToken) async {
    final res = await _post('/auth/google', <String, dynamic>{
      'id_token': idToken,
    });
    return _requireToken(res);
  }

  /// POST `/auth/logout` — revokes the session server-side (bumps token_version).
  Future<void> logout() => _post('/auth/logout', const <String, dynamic>{});

  /// PATCH `/auth/profile` — updates the personalization profile.
  Future<UserProfile> updateProfile(ProfileUpdate update) async {
    final res = await _patch('/auth/profile', update.toJson());
    return UserProfile.fromJson(res['profile'] as Map<String, dynamic>);
  }

  // ── Scan (Phase 2 will build on this) ────────────────────────────────────────

  /// POST `/api/analyze` with a barcode only — the no-image fast path.
  /// `{ "found": false }` means the barcode isn't in the Open Food Facts cache.
  Future<Map<String, dynamic>> analyzeBarcode(String barcode) =>
      _post('/api/analyze', <String, dynamic>{'barcode': barcode});

  // ── helpers ─────────────────────────────────────────────────────────────────

  /// Extract the JWT from an auth response, turning a missing/empty token (a
  /// 2xx with no `token` — backend contract drift) into a clean [ApiException]
  /// the auth screens already handle, rather than an uncaught TypeError.
  String _requireToken(Map<String, dynamic> res) {
    final token = res['token'];
    if (token is! String || token.isEmpty) {
      throw const ApiException('Sign-in failed — please try again.');
    }
    return token;
  }

  Future<T> _get<T>(String path, T Function(Map<String, dynamic>) parse) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(path);
      return parse(res.data ?? const <String, dynamic>{});
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(path, data: body);
      return res.data ?? const <String, dynamic>{};
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }

  Future<Map<String, dynamic>> _patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(path, data: body);
      return res.data ?? const <String, dynamic>{};
    } on DioException catch (error) {
      throw mapDioError(error);
    }
  }
}
