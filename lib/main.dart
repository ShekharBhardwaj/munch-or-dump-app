import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munch_or_dump/app.dart';
import 'package:munch_or_dump/core/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Preload prefs so synchronous providers (the cart) can hydrate in build().
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: <Override>[sharedPrefsProvider.overrideWithValue(prefs)],
      child: const MunchOrDumpApp(),
    ),
  );
}
