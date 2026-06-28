import 'package:flutter/material.dart';
import 'package:munch_or_dump/core/models/verdict.dart';
import 'package:munch_or_dump/core/theme/app_colors.dart';

/// Theme-aware accessor for verdict colors: the primary tone on light surfaces,
/// the lighter accent tone on dark surfaces. Registered as a [ThemeExtension]
/// so widgets read verdict colors through the active theme.
@immutable
class VerdictPalette extends ThemeExtension<VerdictPalette> {
  const VerdictPalette({required this.onDark});

  /// Light-surface palette (primary tones).
  static const VerdictPalette light = VerdictPalette(onDark: false);

  /// Dark-surface palette (lighter accent tones).
  static const VerdictPalette dark = VerdictPalette(onDark: true);

  final bool onDark;

  /// The color for [verdict] appropriate to the current brightness.
  Color colorFor(Verdict verdict) => switch (verdict) {
    Verdict.munch => onDark ? AppColors.munchAccent : AppColors.munch,
    Verdict.okay => onDark ? AppColors.okayAccent : AppColors.okay,
    Verdict.treat => onDark ? AppColors.treatAccent : AppColors.treat,
    Verdict.engineered =>
      onDark ? AppColors.engineeredAccent : AppColors.engineered,
    Verdict.dump => onDark ? AppColors.dumpAccent : AppColors.dump,
    Verdict.bullshit => onDark ? AppColors.bullshitAccent : AppColors.bullshit,
  };

  @override
  VerdictPalette copyWith({bool? onDark}) =>
      VerdictPalette(onDark: onDark ?? this.onDark);

  @override
  VerdictPalette lerp(covariant VerdictPalette? other, double t) {
    // Discrete light/dark selection — no interpolation between palettes.
    if (other == null) return this;
    return t < 0.5 ? this : other;
  }
}

/// Convenience accessor: `context.verdicts.colorFor(verdict)`.
extension VerdictPaletteX on BuildContext {
  VerdictPalette get verdicts =>
      Theme.of(this).extension<VerdictPalette>() ?? VerdictPalette.light;
}
