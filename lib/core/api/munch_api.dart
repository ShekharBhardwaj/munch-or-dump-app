import 'package:dio/dio.dart';
import 'package:munch_or_dump/core/api/api_client.dart';
import 'package:munch_or_dump/core/models/user.dart';

/// Typed client over the Munch or Dump API.
///
/// Mirrors the web app's `munchAPI` surface (`src/api/client.js`) so the two
/// clients stay recognizably the same. Phase 0 establishes the pattern with two
/// representative endpoints; the full surface (scans / analyze / products /
/// watches / …) lands in Phase 1–2.
class MunchApi {
  const MunchApi(this._dio);

  final Dio _dio;

  /// GET `/auth/me` — the current user. Throws [ApiException] (401 if the
  /// session is missing or expired).
  Future<User> getMe() => _get('/auth/me', User.fromJson);

  /// POST `/api/analyze` with a barcode only — the no-image fast path.
  ///
  /// Returns the raw analysis map (a typed model arrives with the Result screen
  /// in Phase 2). A `{ "found": false }` response means the barcode isn't in
  /// the Open Food Facts cache.
  Future<Map<String, dynamic>> analyzeBarcode(String barcode) =>
      _post('/api/analyze', <String, dynamic>{'barcode': barcode});

  // ── helpers ─────────────────────────────────────────────────────────────────

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
}
