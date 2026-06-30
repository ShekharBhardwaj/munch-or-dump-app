import 'package:flutter/material.dart';
import 'package:munch_or_dump/core/models/verdict.dart';
import 'package:munch_or_dump/core/theme/app_colors.dart';

/// The on-screen color roles a verdict carries on the website: the deep [word]
/// tone (the huge verdict word + badge text), the [bar] stripe/accent, the [mid]
/// tone (percentile line), the pale [tint] panel fill, the [border], and the
/// saturated badge [dot].
@immutable
class VerdictTone {
  const VerdictTone({
    required this.word,
    required this.bar,
    required this.mid,
    required this.tint,
    required this.border,
    required this.dot,
  });

  final Color word;
  final Color bar;
  final Color mid;
  final Color tint;
  final Color border;
  final Color dot;
}

/// Web-UI verdict tones (exact tailwind/stone values from munchordump.com).
const Map<Verdict, VerdictTone> kVerdictTones = <Verdict, VerdictTone>{
  Verdict.munch: VerdictTone(
    word: Color(0xFF065F46),
    bar: Color(0xFF10B981),
    mid: Color(0xFF10B981),
    tint: Color(0xFFECFDF5),
    border: Color(0xFFA7F3D0),
    dot: Color(0xFF10B981),
  ),
  Verdict.okay: VerdictTone(
    word: Color(0xFF075985),
    bar: Color(0xFF0EA5E9),
    mid: Color(0xFF0EA5E9),
    tint: Color(0xFFF0F9FF),
    border: Color(0xFFBAE6FD),
    dot: Color(0xFF38BDF8),
  ),
  Verdict.treat: VerdictTone(
    word: Color(0xFF92400E),
    bar: Color(0xFFF59E0B),
    mid: Color(0xFFF59E0B),
    tint: Color(0xFFFFFBEB),
    border: Color(0xFFFDE68A),
    dot: Color(0xFFF59E0B),
  ),
  Verdict.engineered: VerdictTone(
    word: Color(0xFF3730A3),
    bar: Color(0xFF818CF8),
    mid: Color(0xFF818CF8),
    tint: Color(0xFFEEF2FF),
    border: Color(0xFFC7D2FE),
    dot: Color(0xFF6366F1),
  ),
  Verdict.dump: VerdictTone(
    word: Color(0xFF7F1D1D),
    bar: Color(0xFFDC2626),
    mid: Color(0xFFF87171),
    tint: Color(0xFFFEF2F2),
    border: Color(0xFFFECACA),
    dot: Color(0xFFEF4444),
  ),
  Verdict.bullshit: VerdictTone(
    word: Color(0xFF581C87),
    bar: Color(0xFF9333EA),
    mid: Color(0xFFD8B4FE),
    tint: Color(0xFFFAF5FF),
    border: Color(0xFFF5D0FE),
    dot: Color(0xFFD946EF),
  ),
};

/// The website tones for [verdict] (falls back to OKAY if unmapped).
VerdictTone verdictToneFor(Verdict verdict) =>
    kVerdictTones[verdict] ?? kVerdictTones[Verdict.okay]!;

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
