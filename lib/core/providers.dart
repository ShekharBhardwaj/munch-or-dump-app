import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munch_or_dump/core/api/api_client.dart';
import 'package:munch_or_dump/core/api/munch_api.dart';
import 'package:munch_or_dump/core/api/token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure JWT storage.
final tokenStoreProvider = Provider<TokenStore>((ref) => const TokenStore());

/// The preloaded [SharedPreferences] instance. `getInstance()` is async, so
/// `main()` awaits it once before `runApp` and overrides this provider with
/// the value — letting synchronous `Notifier.build()`s (the cart) hydrate
/// without an async gap. Tests override it with a mock-backed instance.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPrefsProvider must be overridden with the preloaded instance '
    '(see main.dart).',
  ),
);

/// Bumped by the dio interceptor whenever a request returns 401. The app root
/// listens and tells the auth layer to sign out — this keeps `core` free of any
/// dependency on the `auth` feature (the dependency points the other way).
final unauthorizedSignalProvider = StateProvider<int>((ref) => 0);

/// Configured Dio instance with Bearer auth + 401 handling.
final dioProvider = Provider<Dio>((ref) {
  final dio = buildApiDio(
    tokenStore: ref.watch(tokenStoreProvider),
    onUnauthorized: () async {
      ref.read(unauthorizedSignalProvider.notifier).state++;
    },
  );
  ref.onDispose(dio.close);
  return dio;
});

/// Typed API client.
final munchApiProvider = Provider<MunchApi>(
  (ref) => MunchApi(ref.watch(dioProvider)),
);
