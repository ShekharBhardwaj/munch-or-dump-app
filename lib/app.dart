import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munch_or_dump/core/providers.dart';
import 'package:munch_or_dump/core/theme/app_theme.dart';

/// Root widget: wires the router and themes into [MaterialApp.router].
class MunchOrDumpApp extends ConsumerWidget {
  const MunchOrDumpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
