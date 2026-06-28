import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/models/analysis_result.dart';
import 'package:munch_or_dump/core/router/routes.dart';
import 'package:munch_or_dump/features/account/account_screen.dart';
import 'package:munch_or_dump/features/auth/auth_controller.dart';
import 'package:munch_or_dump/features/auth/auth_screen.dart';
import 'package:munch_or_dump/features/auth/forgot_password_screen.dart';
import 'package:munch_or_dump/features/auth/verify_email_screen.dart';
import 'package:munch_or_dump/features/history/history_screen.dart';
import 'package:munch_or_dump/features/home/home_screen.dart';
import 'package:munch_or_dump/features/onboarding/onboarding_screen.dart';
import 'package:munch_or_dump/features/product/product_screen.dart';
import 'package:munch_or_dump/features/result/result_screen.dart';
import 'package:munch_or_dump/features/scan/scan_screen.dart';
import 'package:munch_or_dump/features/watchlist/watchlist_screen.dart';

const Set<String> _authRoutes = <String>{
  Routes.loginPath,
  Routes.verifyPath,
  Routes.forgotPath,
};
const Set<String> _gatedRoutes = <String>{
  Routes.accountPath,
  Routes.onboardingPath,
  Routes.historyPath,
  Routes.watchlistPath,
};

/// The app router. Redirect rules:
///  * gated routes (`_gatedRoutes`: `/account`, `/onboarding`, `/history`,
///    `/watchlist`) require a session → home if not (the app allows anonymous
///    browsing; login is reached via the account icon)
///  * auth routes redirect to home once signed in
///  * onboarding itself is navigated to imperatively after login (not forced
///    globally) so a signed-in user is never trapped.
final routerProvider = Provider<GoRouter>((ref) {
  // Re-run redirects whenever the session changes.
  final refresh = ValueNotifier<int>(0);
  ref
    ..onDispose(refresh.dispose)
    ..listen(authControllerProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      if (auth.isLoading) return null;
      final loggedIn = auth.valueOrNull != null;
      final loc = state.matchedLocation;
      // Anonymous-friendly: a logged-out user on a gated route (sign-out or an
      // expired session) lands on home, not a login wall. The login screen is
      // reached deliberately via the home account icon.
      if (!loggedIn && _gatedRoutes.contains(loc)) return Routes.homePath;
      if (loggedIn && _authRoutes.contains(loc)) return Routes.homePath;
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: Routes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/scan',
        name: Routes.scan,
        builder: (context, state) => const ScanScreen(),
      ),
      GoRoute(
        path: '/result',
        name: Routes.result,
        builder: (context, state) {
          final extra = state.extra;
          return ResultScreen(result: extra is AnalysisResult ? extra : null);
        },
      ),
      GoRoute(
        path: '/product/:slug',
        name: Routes.product,
        builder: (context, state) =>
            ProductScreen(slug: state.pathParameters['slug'] ?? ''),
      ),
      GoRoute(
        path: '/history',
        name: Routes.history,
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/watchlist',
        name: Routes.watchlist,
        builder: (context, state) => const WatchlistScreen(),
      ),
      GoRoute(
        path: '/login',
        name: Routes.login,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/verify',
        name: Routes.verify,
        builder: (context, state) =>
            VerifyEmailScreen(email: state.extra as String? ?? ''),
      ),
      GoRoute(
        path: '/forgot',
        name: Routes.forgot,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/account',
        name: Routes.account,
        builder: (context, state) => const AccountScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
