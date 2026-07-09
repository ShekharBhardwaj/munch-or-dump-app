import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/models/analysis_result.dart';
import 'package:munch_or_dump/core/models/verdict.dart';
import 'package:munch_or_dump/core/router/routes.dart';
import 'package:munch_or_dump/core/theme/palette.dart';
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

    final palette = context.palette;
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
                style: TextStyle(
                  fontSize: 30,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: palette.inkPrimary,
                ),
              ),
              if (data.brand != null && data.brand!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  data.brand!,
                  style: TextStyle(fontSize: 13, color: palette.inkFaint),
                ),
              ],
              const SizedBox(height: 20),
              _VerdictHero(result: data, tone: tone),
              const SizedBox(height: 10),
              const _VerdictDisclaimer(),
              if (lead.isNotEmpty) ...<Widget>[
                const SizedBox(height: 20),
                Text(
                  lead,
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: palette.inkPrimary,
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
                  child: _AlternativesList(
                    verdict: data.verdict,
                    alternatives: data.alternatives,
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

class _VerdictHero extends StatefulWidget {
  const _VerdictHero({required this.result, required this.tone});

  final AnalysisResult result;
  final VerdictTone tone;

  @override
  State<_VerdictHero> createState() => _VerdictHeroState();
}

class _VerdictHeroState extends State<_VerdictHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _count;
  bool _buzzed = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..addListener(_maybeBuzz);
    _fade = CurvedAnimation(
      parent: _c,
      curve: const Interval(0, 0.6, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0, 0.7, curve: Curves.easeOutBack),
      ),
    );
    _count = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.15, 1, curve: Curves.easeOutCubic),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
        _c.value = 1;
        _buzzed = true;
      } else {
        _c.forward();
      }
    });
  }

  // Fires once as the verdict word lands. Harsh verdicts land harder.
  void _maybeBuzz() {
    if (_buzzed || _c.value < 0.55) return;
    _buzzed = true;
    if (widget.result.verdictScore <= 20) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _c
      ..removeListener(_maybeBuzz)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final result = widget.result;
    final tone = widget.tone;
    final pills = _metaPills(result);
    final panel = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.hairline),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                  FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            ExcludeSemantics(
                              child: Text(
                                result.verdict.emoji,
                                style: const TextStyle(fontSize: 40),
                              ),
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
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: _count,
                    builder: (BuildContext context, Widget? child) {
                      final int shown = (result.verdictScore * _count.value)
                          .round();
                      return Text(
                        'SCORE $shown / 90',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 3,
                          color: tone.mid,
                        ),
                      );
                    },
                  ),
                  if (pills.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: pills,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI estimate — always read the label for allergens.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: palette.inkMuted),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    result.cacheHit ? '⚡ Instant verdict' : '✨ Fresh analysis',
                    style: TextStyle(fontSize: 11, color: palette.inkFaint),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    final slug = result.productSlug?.trim() ?? '';
    if (slug.isEmpty) return panel;
    // Same tag as the list cards, so a tapped card morphs into this panel.
    return Hero(
      tag: 'product-hero-$slug',
      child: Material(type: MaterialType.transparency, child: panel),
    );
  }
}

/// Persistent per-verdict disclaimer — every verdict is an AI opinion, never a
/// fact or medical advice. Shown on every result.
class _VerdictDisclaimer extends StatelessWidget {
  const _VerdictDisclaimer();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Text(
      'An AI opinion — not fact, and not medical advice.',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12, color: palette.inkFaint),
    );
  }
}

/// NOVA + dietary pills for the hero.
List<Widget> _metaPills(AnalysisResult r) {
  final pills = <Widget>[];
  final nova = r.novaGroup;
  if (nova != null && nova >= 1 && nova <= 4) {
    // (label, fg, bg, border) per NOVA group — 1 green, 2 lime, 3 amber, 4 red.
    const nova1 = (
      'NOVA 1 · Unprocessed',
      Color(0xFF047857),
      Color(0xFFECFDF5),
      Color(0xFFA7F3D0),
    );
    const map = <int, (String, Color, Color, Color)>{
      1: nova1,
      2: (
        'NOVA 2 · Culinary',
        Color(0xFF4D7C0F),
        Color(0xFFF7FEE7),
        Color(0xFFD9F99D),
      ),
      3: (
        'NOVA 3 · Processed',
        Color(0xFFB45309),
        Color(0xFFFFFBEB),
        Color(0xFFFDE68A),
      ),
      4: (
        'NOVA 4 · Ultra-processed',
        Color(0xFFDC2626),
        Color(0xFFFEF2F2),
        Color(0xFFFECACA),
      ),
    };
    final (label, fg, bg, border) = map[nova] ?? nova1;
    pills.add(
      MetaPill(text: label, upper: true, fg: fg, bg: bg, border: border),
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
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
        const SizedBox(height: 18),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0x1FFBBF24),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x4DFBBF24)),
          ),
          child: const Icon(Icons.lock_outline, size: 18, color: _amber),
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
    required this.level,
    required this.dot,
    required this.tint,
    required this.name,
    required this.nameWeight,
    required this.expanded,
    this.badge,
    this.badgeBg,
    this.badgeFg,
  });

  final String level;
  final Color dot;
  final Color? tint;
  final Color name;
  final FontWeight nameWeight;
  final Color expanded;
  final String? badge;
  final Color? badgeBg;
  final Color? badgeFg;

  static _Concern of(SafetyRating r, Palette palette) => switch (r) {
    SafetyRating.harmful => _Concern(
      level: 'High concern',
      dot: palette.concernHigh,
      tint: palette.concernHighTint,
      name: const Color(0xFF7F1D1D),
      nameWeight: FontWeight.w600,
      expanded: const Color(0xFF991B1B),
      badge: 'High concern',
      badgeBg: const Color(0xFFFEE2E2),
      badgeFg: const Color(0xFFB91C1C),
    ),
    SafetyRating.concerning => _Concern(
      level: 'Concerning',
      dot: palette.concernMid,
      tint: palette.concernMidTint,
      name: const Color(0xFF7C2D12),
      nameWeight: FontWeight.w600,
      expanded: const Color(0xFF9A3412),
      badge: 'Concerning',
      badgeBg: const Color(0xFFFFEDD5),
      badgeFg: const Color(0xFFB45309),
    ),
    SafetyRating.moderate => _Concern(
      level: 'Moderate',
      dot: palette.concernModerate,
      tint: null,
      name: const Color(0xFF44403C),
      nameWeight: FontWeight.w500,
      expanded: const Color(0xFF57534E),
    ),
    SafetyRating.safe => _Concern(
      level: 'Safe',
      dot: palette.concernSafe,
      tint: null,
      name: palette.inkFaint,
      nameWeight: FontWeight.w500,
      expanded: palette.inkSecondary,
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
    final palette = context.palette;
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
            color: palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.hairline),
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
                        style: TextStyle(fontSize: 11, color: palette.inkGhost),
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
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: palette.inkSecondary,
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
    final palette = context.palette;
    final c = _Concern.of(ingredient.rating, palette);
    final explanation = ingredient.explanation ?? '';
    final canExpand = explanation.isNotEmpty;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.tint,
        border: divider
            ? Border(bottom: BorderSide(color: palette.hairlineFaint))
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
                  ConcernDot(
                    color: c.dot,
                    semanticLabel: '${c.level} ingredient',
                  ),
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
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: palette.inkFaint,
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
    final palette = context.palette;
    Widget item(Color color, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ConcernDot(color: color, size: 6),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 10, color: palette.inkFaint)),
      ],
    );
    return Wrap(
      spacing: 20,
      runSpacing: 8,
      children: <Widget>[
        item(palette.concernHigh, 'High concern'),
        item(palette.concernMid, 'Concerning'),
        item(palette.concernModerate, 'Moderate'),
        item(palette.concernSafe, 'Safe'),
      ],
    );
  }
}

class _ClaimCard extends StatelessWidget {
  const _ClaimCard({required this.claim});

  final MarketingClaim claim;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final misleading = claim.isMisleading;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: palette.ctaPressed,
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

/// The web's one-line framing per verdict, above the alternatives list. Only
/// non-MUNCH verdicts get alternatives from the API, so MUNCH is intentionally
/// absent here.
const Map<Verdict, String> _altSubtext = <Verdict, String>{
  Verdict.okay: 'Good enough — but these are meaningfully cleaner.',
  Verdict.treat: 'Fine occasionally — but these are everyday choices.',
  Verdict.engineered: 'A lab-built formula. These are made in a kitchen.',
  Verdict.dump: 'This one has red flags. These don’t.',
  Verdict.bullshit: 'The label lies. These actually do what they claim.',
};

class _AlternativesList extends StatelessWidget {
  const _AlternativesList({required this.verdict, required this.alternatives});

  final Verdict verdict;
  final List<Alternative> alternatives;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final alts = alternatives.take(5).toList();
    final subtext = _altSubtext[verdict];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (subtext != null) ...<Widget>[
          Text(
            subtext,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: palette.inkSecondary,
            ),
          ),
          const SizedBox(height: 6),
        ],
        for (var i = 0; i < alts.length; i++) ...<Widget>[
          if (i > 0) Divider(height: 1, color: palette.hairlineFaint),
          _AlternativeRow(alt: alts[i]),
        ],
      ],
    );
  }
}

class _AlternativeRow extends StatelessWidget {
  const _AlternativeRow({required this.alt});

  final Alternative alt;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final verdict = alt.verdict;
    final delta = alt.scoreDelta;
    final brand = alt.brandName;
    final name = alt.name.trim().isEmpty ? alt.slug : alt.name;
    return InkWell(
      onTap: alt.slug.isEmpty
          ? null
          : () => context.pushNamed(
              Routes.product,
              pathParameters: <String, String>{'slug': alt.slug},
            ),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (brand != null && brand.isNotEmpty) ...<Widget>[
                    Eyebrow(brand, size: 10, spacing: 1.4),
                    const SizedBox(height: 3),
                  ],
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: palette.inkPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (delta != null && delta > 0) ...<Widget>[
              Text(
                '+$delta',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: palette.impactPositive,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (verdict != null) WebVerdictBadge(verdict: verdict, size: 9),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: palette.inkGhost),
          ],
        ),
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
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.hairline),
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
