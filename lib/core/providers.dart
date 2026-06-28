import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/api/api_client.dart';
import 'package:munch_or_dump/core/api/munch_api.dart';
import 'package:munch_or_dump/core/api/token_store.dart';
import 'package:munch_or_dump/core/router/app_router.dart';

/// Secure JWT storage.
final tokenStoreProvider = Provider<TokenStore>((ref) => const TokenStore());

/// Configured Dio instance. The 401 → re-auth wiring is added with the auth
/// layer in Phase 1.
final dioProvider = Provider<Dio>((ref) {
  final dio = buildApiDio(tokenStore: ref.watch(tokenStoreProvider));
  ref.onDispose(dio.close);
  return dio;
});

/// Typed API client.
final munchApiProvider = Provider<MunchApi>(
  (ref) => MunchApi(ref.watch(dioProvider)),
);

/// App router.
final routerProvider = Provider<GoRouter>((ref) {
  final router = buildRouter();
  ref.onDispose(router.dispose);
  return router;
});
