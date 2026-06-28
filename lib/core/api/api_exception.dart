/// A normalized API error, mirroring the web client's `err.status` / `err.data`.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.data});

  final String message;
  final int? statusCode;
  final Map<String, dynamic>? data;

  /// 401 — the session is invalid/expired; the caller should re-authenticate.
  bool get isUnauthorized => statusCode == 401;

  /// 429 — rate limited (e.g. the 30 analyze-calls/user/24h cap).
  bool get isRateLimited => statusCode == 429;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
