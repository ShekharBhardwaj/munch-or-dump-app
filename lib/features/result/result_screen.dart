import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/models/analysis_result.dart';
import 'package:munch_or_dump/core/router/routes.dart';
import 'package:munch_or_dump/core/theme/app_colors.dart';
import 'package:munch_or_dump/core/theme/verdict_palette.dart';
import 'package:munch_or_dump/core/widgets/editorial.dart';
import 'package:munch_or_dump/features/auth/auth_controller.dart';
import 'package:munch_or_dump/features/result/result_actions.dart';

/// The verdict result — the app's headline screen, in the website's editorial
/// language: a graph-paper hero, the big verdict word, NOVA + dietary pills, the
/// dark "For You" gated card, an impact-scored ingredient breakdown, and the
/// misleading-claim treatment.
class ResultScreen extends StatelessWidget {
  const ResultScreen({required this.result, super.key});

  final AnalysisResult? result;

  @override
  Widget build(BuildContext context) {
    final data = result;
    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result')),
        body: const Center(child: Text('No result to show — scan a product.')),
      );
    }

    final tone = verdictToneFor(data.verdict);
    final category = (data.category ?? 'Food').trim();
    final lead = data.shortExplanation ?? '';

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: GridBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: <Widget>[
              Eyebrow(
                '${category.isEmpty ? 'Food' : category} · Product analysis',
                size: 12,
                spacing: 3.6,
              ),
              const SizedBox(height: 10),
              Text(
                data.productName.isEmpty ? 'Verdict' : data.productName,
                style: const TextStyle(
                  fontSize: 30,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: AppColors.inkPrimary,
                ),
              ),
              if (data.brand != null && data.brand!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  data.brand!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.inkFaint,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _VerdictHero(result: data, tone: tone),
              if (lead.isNotEmpty) ...<Widget>[
                const SizedBox(height: 20),
                Text(
                  lead,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkPrimary,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _ForYouCard(result: data),
              if (data.verdictReasons.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                _ResultCard(
                  title: 'Why',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (final reason in data.verdictReasons)
                        _Bullet(text: reason, color: tone.bar),
                    ],
                  ),
                ),
              ],
              if (data.ingredientsDetected.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                _IngredientBreakdown(ingredients: data.ingredientsDetected),
              ],
              if (data.marketingClaims.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                const Eyebrow('Marketing claims', spacing: 4.2),
                for (final claim in data.marketingClaims) ...<Widget>[
                  const SizedBox(height: 12),
                  _ClaimCard(claim: claim),
                ],
              ],
              if ((data.consumptionContext ?? '').isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                _ResultCard(
                  title: 'Bottom line',
                  child: Text(
                    data.consumptionContext!,
                    style: const TextStyle(height: 1.5),
                  ),
                ),
              ],
              if (data.alternatives.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                _ResultCard(
                  title: 'Better alternatives',
                  child: Column(
                    children: <Widget>[
                      for (final alt in data.alternatives)
                        _AlternativeRow(alt: alt),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ResultActions(result: data),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerdictHero extends StatelessWidget {
  const _VerdictHero({required this.result, required this.tone});

  final AnalysisResult result;
  final VerdictTone tone;

  @override
  Widget build(BuildContext context) {
    final pills = _metaPills(result);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A1C1917),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: <Widget>[
            Container(height: 8, color: tone.bar),
            Container(
              width: double.infinity,
              color: tone.tint,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              child: Column(
                children: <Widget>[
                  const Eyebrow(
                    'Verdict',
                    size: 10,
                    spacing: 4.5,
                    align: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          result.verdict.emoji,
                          style: const TextStyle(fontSize: 40),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          result.verdict.label.toUpperCase(),
                          style: TextStyle(
                            fontSize: 72,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.5,
                            color: tone.word,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'SCORE ${result.verdictScore} / 90',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3,
                      color: tone.mid,
                    ),
                  ),
                  if (pills.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: pills,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    result.cacheHit ? '⚡ Instant verdict' : '✨ Fresh analysis',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.inkFaint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// NOVA + dietary pills for the hero.
List<Widget> _metaPills(AnalysisResult r) {
  final pills = <Widget>[];
  final nova = r.novaGroup;
  if (nova != null && nova >= 1 && nova <= 4) {
    const labels = <int, String>{
      1: 'NOVA 1 · Unprocessed',
      2: 'NOVA 2 · Culinary',
      3: 'NOVA 3 · Processed',
      4: 'NOVA 4 · Ultra-processed',
    };
    final ok = nova <= 2;
    pills.add(
      MetaPill(
        text: labels[nova]!,
        upper: true,
        fg: ok ? const Color(0xFF047857) : const Color(0xFFDC2626),
        bg: ok ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
        border: ok ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
      ),
    );
  }
  void diet(bool on, String label, {required bool good}) {
    if (!on) return;
    pills.add(
      MetaPill(
        text: '${good ? '✓' : '⚠'} $label',
        upper: true,
        fg: good ? const Color(0xFF047857) : const Color(0xFFDC2626),
        bg: good ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
        border: good ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
      ),
    );
  }

  diet(r.isVegan, 'Vegan', good: true);
  diet(r.isVegetarian && !r.isVegan, 'Vegetarian', good: true);
  diet(r.isGlutenFree, 'Gluten free', good: true);
  diet(r.isDairyFree, 'Dairy free', good: true);
  diet(r.containsNuts, 'Contains nuts', good: false);
  diet(r.containsSoy, 'Contains soy', good: false);
  diet(r.containsEggs, 'Contains eggs', good: false);
  return pills;
}

/// The dark amber-accented "For You" card — gated when there's no personalized
/// note (sign in / set up profile), unlocked when one is present.
class _ForYouCard extends ConsumerWidget {
  const _ForYouCard({required this.result});

  final AnalysisResult result;

  static const _amber = Color(0xFFFBBF24);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(authControllerProvider).valueOrNull != null;
    final note = result.hasProfileNote ? result.profileNote! : null;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x4D78350F)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF1C1710),
            Color(0xFF2A1E0D),
            Color(0xFF1A1508),
          ],
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x14FBBF24), blurRadius: 24),
          BoxShadow(
            color: Color(0x4D000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: note != null
          ? _unlocked(note)
          : _gated(context, loggedIn: loggedIn),
    );
  }

  Widget _unlocked(String note) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Row(
          children: <Widget>[
            Icon(Icons.auto_awesome, size: 16, color: _amber),
            SizedBox(width: 8),
            Text(
              'FOR YOU',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5,
                color: _amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          note,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFFE5C97A),
          ),
        ),
      ],
    );
  }

  Widget _gated(BuildContext context, {required bool loggedIn}) {
    return Column(
      children: <Widget>[
        Stack(
          alignment: Alignment.center,
          children: <Widget>[
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: const IgnorePointer(
                child: Text(
                  'Based on your goals and the conditions you track, here’s '
                  'exactly how this product fits your day.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xE6FDE68A),
                  ),
                ),
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0x1FFBBF24),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x4DFBBF24)),
              ),
              child: const Icon(Icons.lock_outline, size: 16, color: _amber),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          loggedIn
              ? 'Set up your profile to unlock a take on every product'
              : 'Your personalized take is ready',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xCCFDE68A),
          ),
        ),
        const SizedBox(height: 14),
        _AmberButton(
          label: loggedIn ? 'Set up your profile' : 'Sign in to unlock',
          onTap: () =>
              context.pushNamed(loggedIn ? Routes.onboarding : Routes.login),
        ),
      ],
    );
  }
}

class _AmberButton extends StatelessWidget {
  const _AmberButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFFF59E0B), Color(0xFFD97706)],
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x66F59E0B),
              blurRadius: 12,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Concern styling derived from an ingredient's safety rating.
class _Concern {
  const _Concern({
    required this.dot,
    required this.tint,
    required this.name,
    required this.nameWeight,
    required this.expanded,
    this.badge,
    this.badgeBg,
    this.badgeFg,
  });

  final Color dot;
  final Color? tint;
  final Color name;
  final FontWeight nameWeight;
  final Color expanded;
  final String? badge;
  final Color? badgeBg;
  final Color? badgeFg;

  static _Concern of(SafetyRating r) => switch (r) {
    SafetyRating.harmful => const _Concern(
      dot: AppColors.concernHigh,
      tint: AppColors.concernHighTint,
      name: Color(0xFF7F1D1D),
      nameWeight: FontWeight.w600,
      expanded: Color(0xFF991B1B),
      badge: 'High concern',
      badgeBg: Color(0xFFFEE2E2),
      badgeFg: Color(0xFFB91C1C),
    ),
    SafetyRating.concerning => const _Concern(
      dot: AppColors.concernMid,
      tint: AppColors.concernMidTint,
      name: Color(0xFF7C2D12),
      nameWeight: FontWeight.w600,
      expanded: Color(0xFF9A3412),
      badge: 'Concerning',
      badgeBg: Color(0xFFFFEDD5),
      badgeFg: Color(0xFFB45309),
    ),
    SafetyRating.moderate => const _Concern(
      dot: AppColors.concernModerate,
      tint: null,
      name: Color(0xFF44403C),
      nameWeight: FontWeight.w500,
      expanded: Color(0xFF57534E),
    ),
    SafetyRating.safe => const _Concern(
      dot: AppColors.concernSafe,
      tint: null,
      name: AppColors.inkFaint,
      nameWeight: FontWeight.w500,
      expanded: AppColors.inkSecondary,
    ),
  };
}

int _severityRank(SafetyRating r) => switch (r) {
  SafetyRating.harmful => 0,
  SafetyRating.concerning => 1,
  SafetyRating.moderate => 2,
  SafetyRating.safe => 3,
};

class _IngredientBreakdown extends StatefulWidget {
  const _IngredientBreakdown({required this.ingredients});

  final List<AnalyzedIngredient> ingredients;

  @override
  State<_IngredientBreakdown> createState() => _IngredientBreakdownState();
}

class _IngredientBreakdownState extends State<_IngredientBreakdown> {
  static const _preview = 8;
  final Set<int> _expanded = <int>{};
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final sorted = <AnalyzedIngredient>[...widget.ingredients]
      ..sort((a, b) {
        final byRank = _severityRank(
          a.rating,
        ).compareTo(_severityRank(b.rating));
        if (byRank != 0) return byRank;
        return (a.impactScore ?? 0).compareTo(b.impactScore ?? 0);
      });
    final flagCount = sorted
        .where(
          (i) =>
              i.rating == SafetyRating.harmful ||
              i.rating == SafetyRating.concerning,
        )
        .length;
    final visible = _showAll ? sorted : sorted.take(_preview).toList();
    final hidden = sorted.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.hairline),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: <Widget>[
                      const Eyebrow('Ingredients', spacing: 4.2),
                      const SizedBox(width: 12),
                      Text(
                        '${sorted.length} total',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.inkGhost,
                        ),
                      ),
                      if (flagCount > 0)
                        Text(
                          ' · $flagCount flagged',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFF87171),
                          ),
                        ),
                    ],
                  ),
                ),
                for (var i = 0; i < visible.length; i++)
                  _IngredientRow(
                    ingredient: visible[i],
                    divider: i != visible.length - 1 || hidden > 0,
                    expanded: _expanded.contains(i),
                    onToggle: () => setState(() {
                      _expanded.contains(i)
                          ? _expanded.remove(i)
                          : _expanded.add(i);
                    }),
                  ),
                if (hidden > 0)
                  InkWell(
                    onTap: () => setState(() => _showAll = true),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      child: Text(
                        'Show $hidden more clean '
                        'ingredient${hidden == 1 ? '' : 's'} →',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _ConcernLegend(),
      ],
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.ingredient,
    required this.divider,
    required this.expanded,
    required this.onToggle,
  });

  final AnalyzedIngredient ingredient;
  final bool divider;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = _Concern.of(ingredient.rating);
    final explanation = ingredient.explanation ?? '';
    final canExpand = explanation.isNotEmpty;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.tint,
        border: divider
            ? const Border(bottom: BorderSide(color: AppColors.hairlineFaint))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            onTap: canExpand ? onToggle : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: <Widget>[
                  ConcernDot(color: c.dot),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ingredient.name,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.25,
                        fontWeight: c.nameWeight,
                        color: c.name,
                      ),
                    ),
                  ),
                  if (c.badge != null) ...<Widget>[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: c.badgeBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        c.badge!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: c.badgeFg,
                        ),
                      ),
                    ),
                  ],
                  if ((ingredient.impactScore ?? 0).abs() >= 2) ...<Widget>[
                    const SizedBox(width: 8),
                    ImpactScore(score: ingredient.impactScore!),
                  ],
                  if (canExpand) ...<Widget>[
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: AppColors.inkFaint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: (expanded && canExpand)
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(40, 0, 20, 12),
                    child: Text(
                      explanation,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: c.expanded,
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _ConcernLegend extends StatelessWidget {
  const _ConcernLegend();

  @override
  Widget build(BuildContext context) {
    Widget item(Color color, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ConcernDot(color: color, size: 6),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.inkFaint),
        ),
      ],
    );
    return Wrap(
      spacing: 20,
      runSpacing: 8,
      children: <Widget>[
        item(AppColors.concernHigh, 'High concern'),
        item(AppColors.concernMid, 'Concerning'),
        item(AppColors.concernModerate, 'Moderate'),
        item(AppColors.concernSafe, 'Safe'),
      ],
    );
  }
}

class _ClaimCard extends StatelessWidget {
  const _ClaimCard({required this.claim});

  final MarketingClaim claim;

  @override
  Widget build(BuildContext context) {
    final misleading = claim.isMisleading;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: misleading ? const Color(0xCCFECACA) : const Color(0x99E7E5E4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: misleading
                  ? const Color(0xFFFEF2F2)
                  : const Color(0xFFECFDF5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              misleading ? Icons.warning_amber_rounded : Icons.check,
              size: 16,
              color: misleading
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Eyebrow('Claim', size: 11, spacing: 1),
                const SizedBox(height: 4),
                Text(
                  '“${claim.claim}”',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ctaPressed,
                  ),
                ),
                if ((claim.reality ?? '').isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  const Eyebrow('Reality', size: 11, spacing: 1),
                  const SizedBox(height: 4),
                  Text(
                    claim.reality!,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Color(0xFF57534E),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlternativeRow extends StatelessWidget {
  const _AlternativeRow({required this.alt});

  final Alternative alt;

  @override
  Widget build(BuildContext context) {
    final verdict = alt.verdict;
    final delta = alt.scoreDelta;
    final brand = alt.brandName;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        alt.name.trim().isEmpty ? alt.slug : alt.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: brand != null && brand.isNotEmpty
          ? Text(brand, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (delta != null && delta > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '+$delta',
                style: const TextStyle(
                  color: AppColors.impactPositive,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          if (verdict != null) WebVerdictBadge(verdict: verdict, size: 10),
        ],
      ),
      onTap: alt.slug.isEmpty
          ? null
          : () => context.pushNamed(
              Routes.product,
              pathParameters: <String, String>{'slug': alt.slug},
            ),
    );
  }
}

/// A white section card with an editorial eyebrow title.
class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Eyebrow(title, spacing: 4.2),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 7, right: 10),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          Expanded(child: Text(text, style: const TextStyle(height: 1.45))),
        ],
      ),
    );
  }
}
