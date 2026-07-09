import 'package:flutter/material.dart';

/// Theme-aware color roles for the whole design system — the dynamic
/// counterpart to the static [AppColors] constants. Registered as a
/// [ThemeExtension] on both light and dark [ThemeData] so widgets resolve the
/// correct palette through the active theme: `context.palette.canvas`.
///
/// [light] carries exactly today's `AppColors` values (zero visual change in
/// light mode). [dark] is a designed dark-stone palette — stone-950 canvas,
/// stone-900 cards, an inverted (light) CTA pill, brightened concern tones and
/// low-saturation dark tints — not a naive inversion.
@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.brandSeed,
    required this.brand,
    required this.brandDeep,
    required this.ink,
    required this.mutedInk,
    required this.canvas,
    required this.surface,
    required this.surfaceAlt,
    required this.inkPrimary,
    required this.inkSecondary,
    required this.inkFaint,
    required this.inkMuted,
    required this.inkGhost,
    required this.hairline,
    required this.hairlineFaint,
    required this.ctaBlack,
    required this.ctaPressed,
    required this.ctaForeground,
    required this.concernHigh,
    required this.concernMid,
    required this.concernModerate,
    required this.concernSafe,
    required this.concernHighTint,
    required this.concernMidTint,
    required this.impactPositive,
    required this.impactNegative,
    required this.munch,
    required this.okay,
    required this.treat,
    required this.engineered,
    required this.dump,
    required this.bullshit,
    required this.munchAccent,
    required this.okayAccent,
    required this.treatAccent,
    required this.engineeredAccent,
    required this.dumpAccent,
    required this.bullshitAccent,
    required this.shadow,
    required this.gridLine,
  });

  /// Light palette — exactly today's `AppColors` values.
  static const Palette light = Palette(
    brandSeed: Color(0xFF10B981), // emerald — the "Munch" hero
    brand: Color(0xFF0E9F6E), // emerald accent (sparingly)
    brandDeep: Color(0xFF0A7A54),
    ink: Color(0xFF1C1917), // stone-900 text
    mutedInk: Color(0xFF78716C), // stone-500
    canvas: Color(0xFFF8F7F4), // page cream
    surface: Color(0xFFFFFFFF), // cards
    surfaceAlt: Color(0xFFFAFAF9), // neutral pill fill
    inkPrimary: Color(0xFF1C1917), // stone-900 headings
    inkSecondary: Color(0xFF78716C), // stone-500 body
    inkFaint: Color(0xFFA8A29E), // stone-400 eyebrows
    inkMuted: Color(0xFFA8A29E), // alias (eyebrows/placeholder)
    inkGhost: Color(0xFFD6D3D1), // stone-300 empty/placeholder
    hairline: Color(0xFFE7E5E4), // stone-200 borders
    hairlineFaint: Color(0xFFF5F5F4), // stone-100 dividers
    ctaBlack: Color(0xFF0C0A09), // stone-950 primary CTA
    ctaPressed: Color(0xFF292524), // stone-800
    ctaForeground: Color(0xFFFFFFFF), // text/icon on the CTA pill
    concernHigh: Color(0xFFEF4444), // red-500
    concernMid: Color(0xFFFB923C), // orange-400
    concernModerate: Color(0xFFFBBF24), // amber-400
    concernSafe: Color(0xFF34D399), // emerald-400
    concernHighTint: Color(0xFFFEF2F2), // red-50
    concernMidTint: Color(0xFFFFF7ED), // orange-50
    impactPositive: Color(0xFF16A34A), // emerald-600
    impactNegative: Color(0xFFEF4444), // red-500
    munch: Color(0xFF10B981),
    okay: Color(0xFF0EA5E9),
    treat: Color(0xFFF59E0B),
    engineered: Color(0xFF8B5CF6),
    dump: Color(0xFFEF4444),
    bullshit: Color(0xFFA855F7),
    munchAccent: Color(0xFF34D399),
    okayAccent: Color(0xFF38BDF8),
    treatAccent: Color(0xFFFBBF24),
    engineeredAccent: Color(0xFFA78BFA),
    dumpAccent: Color(0xFFF87171),
    bullshitAccent: Color(0xFFC084FC),
    shadow: Color(0x0A1C1917), // card drop shadow
    gridLine: Color.fromRGBO(0, 0, 0, 0.022), // graph-paper texture
  );

  /// Dark palette — premium dark stone. The CTA inverts (light pill on dark
  /// canvas), concern tones brighten a step for contrast, and the pale tint
  /// panels become deep low-saturation washes.
  static const Palette dark = Palette(
    brandSeed: Color(0xFF10B981),
    brand: Color(0xFF10B981), // emerald-500 — brighter on dark
    brandDeep: Color(0xFF0E9F6E), // light-mode brand, one step up
    ink: Color(0xFFFAFAF9), // stone-50 text
    mutedInk: Color(0xFFA8A29E), // stone-400
    canvas: Color(0xFF0C0A09), // stone-950 page
    surface: Color(0xFF1C1917), // stone-900 cards
    surfaceAlt: Color(0xFF292524), // stone-800 pill fill
    inkPrimary: Color(0xFFFAFAF9), // stone-50 headings
    inkSecondary: Color(0xFFA8A29E), // stone-400 body
    inkFaint: Color(0xFF78716C), // stone-500 eyebrows
    inkMuted: Color(0xFF78716C), // alias (eyebrows/placeholder)
    inkGhost: Color(0xFF57534E), // stone-600 empty/placeholder
    hairline: Color(0xFF292524), // stone-800 borders
    hairlineFaint: Color(0xFF1C1917), // stone-900 dividers
    ctaBlack: Color(0xFFFAFAF9), // the CTA inverts: light pill
    ctaPressed: Color(0xFFE7E5E4), // stone-200
    ctaForeground: Color(0xFF0C0A09), // near-black text on the light pill
    concernHigh: Color(0xFFF87171), // red-400 — brightened
    concernMid: Color(0xFFFB923C), // orange-400 (already bright)
    concernModerate: Color(0xFFFBBF24), // amber-400 (already bright)
    concernSafe: Color(0xFF34D399), // emerald-400 (already bright)
    concernHighTint: Color(0xFF2A1414), // deep desaturated red wash
    concernMidTint: Color(0xFF2A1D0E), // deep desaturated orange wash
    impactPositive: Color(0xFF34D399), // emerald-400 — brightened
    impactNegative: Color(0xFFF87171), // red-400 — brightened
    munch: Color(0xFF34D399), // accent tones read as primary on dark
    okay: Color(0xFF38BDF8),
    treat: Color(0xFFFBBF24),
    engineered: Color(0xFFA78BFA),
    dump: Color(0xFFF87171),
    bullshit: Color(0xFFC084FC),
    munchAccent: Color(0xFF34D399),
    okayAccent: Color(0xFF38BDF8),
    treatAccent: Color(0xFFFBBF24),
    engineeredAccent: Color(0xFFA78BFA),
    dumpAccent: Color(0xFFF87171),
    bullshitAccent: Color(0xFFC084FC),
    shadow: Color(0x66000000), // deeper drop shadow on dark
    gridLine: Color.fromRGBO(255, 255, 255, 0.04), // light-on-dark texture
  );

  // ── Brand ──────────────────────────────────────────────────────────────────
  final Color brandSeed;
  final Color brand;
  final Color brandDeep;
  final Color ink;
  final Color mutedInk;

  // ── Neutrals ───────────────────────────────────────────────────────────────
  final Color canvas;
  final Color surface;
  final Color surfaceAlt;
  final Color inkPrimary;
  final Color inkSecondary;
  final Color inkFaint;
  final Color inkMuted;
  final Color inkGhost;
  final Color hairline;
  final Color hairlineFaint;
  final Color ctaBlack;
  final Color ctaPressed;
  final Color ctaForeground;

  // ── Concern tiers (ingredient severity) ────────────────────────────────────
  final Color concernHigh;
  final Color concernMid;
  final Color concernModerate;
  final Color concernSafe;
  final Color concernHighTint;
  final Color concernMidTint;
  final Color impactPositive;
  final Color impactNegative;

  // ── Verdict — primary tone ─────────────────────────────────────────────────
  final Color munch;
  final Color okay;
  final Color treat;
  final Color engineered;
  final Color dump;
  final Color bullshit;

  // ── Verdict — lighter accent tone ──────────────────────────────────────────
  final Color munchAccent;
  final Color okayAccent;
  final Color treatAccent;
  final Color engineeredAccent;
  final Color dumpAccent;
  final Color bullshitAccent;

  // ── Effects ────────────────────────────────────────────────────────────────
  final Color shadow;
  final Color gridLine;

  @override
  Palette copyWith({
    Color? brandSeed,
    Color? brand,
    Color? brandDeep,
    Color? ink,
    Color? mutedInk,
    Color? canvas,
    Color? surface,
    Color? surfaceAlt,
    Color? inkPrimary,
    Color? inkSecondary,
    Color? inkFaint,
    Color? inkMuted,
    Color? inkGhost,
    Color? hairline,
    Color? hairlineFaint,
    Color? ctaBlack,
    Color? ctaPressed,
    Color? ctaForeground,
    Color? concernHigh,
    Color? concernMid,
    Color? concernModerate,
    Color? concernSafe,
    Color? concernHighTint,
    Color? concernMidTint,
    Color? impactPositive,
    Color? impactNegative,
    Color? munch,
    Color? okay,
    Color? treat,
    Color? engineered,
    Color? dump,
    Color? bullshit,
    Color? munchAccent,
    Color? okayAccent,
    Color? treatAccent,
    Color? engineeredAccent,
    Color? dumpAccent,
    Color? bullshitAccent,
    Color? shadow,
    Color? gridLine,
  }) {
    return Palette(
      brandSeed: brandSeed ?? this.brandSeed,
      brand: brand ?? this.brand,
      brandDeep: brandDeep ?? this.brandDeep,
      ink: ink ?? this.ink,
      mutedInk: mutedInk ?? this.mutedInk,
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      inkPrimary: inkPrimary ?? this.inkPrimary,
      inkSecondary: inkSecondary ?? this.inkSecondary,
      inkFaint: inkFaint ?? this.inkFaint,
      inkMuted: inkMuted ?? this.inkMuted,
      inkGhost: inkGhost ?? this.inkGhost,
      hairline: hairline ?? this.hairline,
      hairlineFaint: hairlineFaint ?? this.hairlineFaint,
      ctaBlack: ctaBlack ?? this.ctaBlack,
      ctaPressed: ctaPressed ?? this.ctaPressed,
      ctaForeground: ctaForeground ?? this.ctaForeground,
      concernHigh: concernHigh ?? this.concernHigh,
      concernMid: concernMid ?? this.concernMid,
      concernModerate: concernModerate ?? this.concernModerate,
      concernSafe: concernSafe ?? this.concernSafe,
      concernHighTint: concernHighTint ?? this.concernHighTint,
      concernMidTint: concernMidTint ?? this.concernMidTint,
      impactPositive: impactPositive ?? this.impactPositive,
      impactNegative: impactNegative ?? this.impactNegative,
      munch: munch ?? this.munch,
      okay: okay ?? this.okay,
      treat: treat ?? this.treat,
      engineered: engineered ?? this.engineered,
      dump: dump ?? this.dump,
      bullshit: bullshit ?? this.bullshit,
      munchAccent: munchAccent ?? this.munchAccent,
      okayAccent: okayAccent ?? this.okayAccent,
      treatAccent: treatAccent ?? this.treatAccent,
      engineeredAccent: engineeredAccent ?? this.engineeredAccent,
      dumpAccent: dumpAccent ?? this.dumpAccent,
      bullshitAccent: bullshitAccent ?? this.bullshitAccent,
      shadow: shadow ?? this.shadow,
      gridLine: gridLine ?? this.gridLine,
    );
  }

  @override
  Palette lerp(covariant Palette? other, double t) {
    if (other == null) return this;
    return Palette(
      brandSeed: Color.lerp(brandSeed, other.brandSeed, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brandDeep: Color.lerp(brandDeep, other.brandDeep, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      mutedInk: Color.lerp(mutedInk, other.mutedInk, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      inkPrimary: Color.lerp(inkPrimary, other.inkPrimary, t)!,
      inkSecondary: Color.lerp(inkSecondary, other.inkSecondary, t)!,
      inkFaint: Color.lerp(inkFaint, other.inkFaint, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      inkGhost: Color.lerp(inkGhost, other.inkGhost, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      hairlineFaint: Color.lerp(hairlineFaint, other.hairlineFaint, t)!,
      ctaBlack: Color.lerp(ctaBlack, other.ctaBlack, t)!,
      ctaPressed: Color.lerp(ctaPressed, other.ctaPressed, t)!,
      ctaForeground: Color.lerp(ctaForeground, other.ctaForeground, t)!,
      concernHigh: Color.lerp(concernHigh, other.concernHigh, t)!,
      concernMid: Color.lerp(concernMid, other.concernMid, t)!,
      concernModerate: Color.lerp(concernModerate, other.concernModerate, t)!,
      concernSafe: Color.lerp(concernSafe, other.concernSafe, t)!,
      concernHighTint: Color.lerp(concernHighTint, other.concernHighTint, t)!,
      concernMidTint: Color.lerp(concernMidTint, other.concernMidTint, t)!,
      impactPositive: Color.lerp(impactPositive, other.impactPositive, t)!,
      impactNegative: Color.lerp(impactNegative, other.impactNegative, t)!,
      munch: Color.lerp(munch, other.munch, t)!,
      okay: Color.lerp(okay, other.okay, t)!,
      treat: Color.lerp(treat, other.treat, t)!,
      engineered: Color.lerp(engineered, other.engineered, t)!,
      dump: Color.lerp(dump, other.dump, t)!,
      bullshit: Color.lerp(bullshit, other.bullshit, t)!,
      munchAccent: Color.lerp(munchAccent, other.munchAccent, t)!,
      okayAccent: Color.lerp(okayAccent, other.okayAccent, t)!,
      treatAccent: Color.lerp(treatAccent, other.treatAccent, t)!,
      engineeredAccent: Color.lerp(
        engineeredAccent,
        other.engineeredAccent,
        t,
      )!,
      dumpAccent: Color.lerp(dumpAccent, other.dumpAccent, t)!,
      bullshitAccent: Color.lerp(bullshitAccent, other.bullshitAccent, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      gridLine: Color.lerp(gridLine, other.gridLine, t)!,
    );
  }
}

/// Convenience accessor: `context.palette.canvas`.
///
/// Falls back to [Palette.light] when the theme doesn't register the
/// extension (e.g. widget tests pumping a bare [MaterialApp]).
extension PaletteX on BuildContext {
  Palette get palette => Theme.of(this).extension<Palette>() ?? Palette.light;
}
