import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munch_or_dump/core/providers.dart';
import 'package:munch_or_dump/core/router/app_router.dart';
import 'package:munch_or_dump/core/theme/app_theme.dart';
import 'package:munch_or_dump/features/auth/auth_controller.dart';

/// Root widget: wires the router and themes into [MaterialApp.router], and
/// turns a 401 from anywhere into a sign-out.
class MunchOrDumpApp extends ConsumerWidget {
  const MunchOrDumpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The dio interceptor already cleared the token; flip the session state too.
    ref.listen(unauthorizedSignalProvider, (_, _) {
      ref.read(authControllerProvider.notifier).onSessionExpired();
    });

    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Munch or Dump',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
