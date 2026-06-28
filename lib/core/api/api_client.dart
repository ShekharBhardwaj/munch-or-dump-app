import 'package:dio/dio.dart';
import 'package:munch_or_dump/core/api/api_exception.dart';
import 'package:munch_or_dump/core/api/token_store.dart';
import 'package:munch_or_dump/core/config/app_config.dart';

/// Builds the configured [Dio] instance for the Munch or Dump API.
///
/// Responsibilities:
///  * base URL + sane timeouts
///  * attach `Authorization: Bearer <jwt>` from secure storage
///  * on 401, wipe the session and fire [onUnauthorized] — there is no
///    refresh-token flow, so a 401 means re-auth.
///
/// HTTP/transport failures surface as [DioException]; call [mapDioError] at the
/// call site to turn them into an [ApiException] with status + body.
Dio buildApiDio({
  required TokenStore tokenStore,
  Future<void> Function()? onUnauthorized,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStore.read();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await tokenStore.clear();
          await onUnauthorized?.call();
        }
        handler.reject(error);
      },
    ),
  );

  return dio;
}

/// Translates a [DioException] into our [ApiException], pulling the API's
/// `{ error | message }` body when present and falling back to friendly copy.
ApiException mapDioError(DioException error) {
  final response = error.response;
  final data = response?.data;

  Map<String, dynamic>? body;
  var message = '';
  if (data is Map<String, dynamic>) {
    body = data;
    message = (data['error'] ?? data['message'] ?? '').toString();
  }

  if (message.isEmpty) {
    message = switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'The request timed out. Check your connection and try again.',
      DioExceptionType.connectionError =>
        'Can’t reach Munch or Dump right now. Check your connection.',
      _ => 'Something went wrong (${response?.statusCode ?? 'network'}).',
    };
  }

  return ApiException(message, statusCode: response?.statusCode, data: body);
}
