import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/features/home/home_screen.dart';
import 'package:munch_or_dump/features/scan/scan_screen.dart';

/// Named routes — referenced via `context.goNamed(...)` to avoid stringly paths.
abstract final class Routes {
  static const String home = 'home';
  static const String scan = 'scan';
}

/// Builds the app's [GoRouter]. Auth-gated redirects are added in Phase 1.
GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/',
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
    ],
  );
}
