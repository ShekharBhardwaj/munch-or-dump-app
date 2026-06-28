import 'package:flutter/material.dart';
import 'package:munch_or_dump/core/theme/app_colors.dart';
import 'package:munch_or_dump/core/theme/verdict_palette.dart';

/// Light + dark themes for the app, seeded from the brand color and carrying
/// the [VerdictPalette] extension.
abstract final class AppTheme {
  static ThemeData get light => _base(Brightness.light, VerdictPalette.light);
  static ThemeData get dark => _base(Brightness.dark, VerdictPalette.dark);

  static ThemeData _base(Brightness brightness, VerdictPalette verdicts) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandSeed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      extensions: <ThemeExtension<dynamic>>[verdicts],
      appBarTheme: const AppBarTheme(centerTitle: false),
    );
  }
}
