import 'package:flutter/material.dart';

/// Brand + verdict colors.
///
/// Verdict hexes mirror the web app's `ShareCard.jsx` VERDICT_CONFIG so web and
/// mobile stay visually identical. Each verdict has a primary tone (for light
/// surfaces) and a lighter accent tone (for dark surfaces).
abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────────
  static const Color brandSeed = Color(
    0xFF10B981,
  ); // emerald — the "Munch" hero
  static const Color ink = Color(0xFF1C1917); // stone-900 text
  static const Color mutedInk = Color(0xFF78716C); // stone-500

  // ── Neutral palette — exact website stone values (web parity) ────────────────
  static const Color brand = Color(0xFF0E9F6E); // emerald accent (sparingly)
  static const Color brandDeep = Color(0xFF0A7A54);
  static const Color canvas = Color(0xFFF8F7F4); // page cream
  static const Color surface = Color(0xFFFFFFFF); // cards
  static const Color surfaceAlt = Color(0xFFFAFAF9); // neutral pill fill
  static const Color inkPrimary = Color(0xFF1C1917); // stone-900 headings
  static const Color inkSecondary = Color(0xFF78716C); // stone-500 body
  static const Color inkFaint = Color(0xFFA8A29E); // stone-400 eyebrows
  static const Color inkMuted = Color(
    0xFFA8A29E,
  ); // alias (eyebrows/placeholder)
  static const Color inkGhost = Color(
    0xFFD6D3D1,
  ); // stone-300 empty/placeholder
  static const Color hairline = Color(0xFFE7E5E4); // stone-200 borders
  static const Color hairlineFaint = Color(0xFFF5F5F4); // stone-100 dividers
  static const Color ctaBlack = Color(0xFF0C0A09); // stone-950 primary CTA
  static const Color ctaPressed = Color(0xFF292524); // stone-800

  // ── Concern tiers (ingredient severity) ──────────────────────────────────────
  static const Color concernHigh = Color(0xFFEF4444); // red-500
  static const Color concernMid = Color(0xFFFB923C); // orange-400
  static const Color concernModerate = Color(0xFFFBBF24); // amber-400
  static const Color concernSafe = Color(0xFF34D399); // emerald-400
  static const Color concernHighTint = Color(0xFFFEF2F2); // red-50
  static const Color concernMidTint = Color(0xFFFFF7ED); // orange-50
  static const Color impactPositive = Color(0xFF16A34A); // emerald-600
  static const Color impactNegative = Color(0xFFEF4444); // red-500

  // ── Verdict — primary tone ──────────────────────────────────────────────────
  static const Color munch = Color(0xFF10B981);
  static const Color okay = Color(0xFF0EA5E9);
  static const Color treat = Color(0xFFF59E0B);
  static const Color engineered = Color(0xFF8B5CF6);
  static const Color dump = Color(0xFFEF4444);
  static const Color bullshit = Color(0xFFA855F7);

  // ── Verdict — lighter accent tone (dark surfaces) ───────────────────────────
  static const Color munchAccent = Color(0xFF34D399);
  static const Color okayAccent = Color(0xFF38BDF8);
  static const Color treatAccent = Color(0xFFFBBF24);
  static const Color engineeredAccent = Color(0xFFA78BFA);
  static const Color dumpAccent = Color(0xFFF87171);
  static const Color bullshitAccent = Color(0xFFC084FC);
}
