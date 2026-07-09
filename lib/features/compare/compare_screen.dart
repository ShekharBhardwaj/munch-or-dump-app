import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munch_or_dump/core/models/analysis_result.dart';
import 'package:munch_or_dump/core/models/catalog.dart';
import 'package:munch_or_dump/core/theme/palette.dart';
import 'package:munch_or_dump/core/theme/verdict_palette.dart';
import 'package:munch_or_dump/core/widgets/editorial.dart';
import 'package:munch_or_dump/features/browse/search_screen.dart';
import 'package:munch_or_dump/features/product/product_screen.dart';

const Color _winTint = Color(
  0xFFF3FBF7,
); // faint emerald wash for the better cell
const Color _emeraldText = Color(0xFF047857);
const Color _redText = Color(0xFFDC2626);

/// Pick two products and see which wins — an aligned, attribute-by-attribute
/// comparison with a clear "better choice" call-out. Open to anyone (product
/// detail is anonymous-readable).
class CompareScreen extends ConsumerStatefulWidget {
  const CompareScreen({this.initialSlug, this.initialSlugB, super.key});

  final String? initialSlug;
  final String? initialSlugB;

  @override
  ConsumerState<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends ConsumerState<CompareScreen> {
  String? _a;
  String? _b;

  @override
  void initState() {
    super.initState();
    _a = _clean(widget.initialSlug);
    _b = _clean(widget.initialSlugB);
  }

  String? _clean(String? slug) =>
      (slug != null && slug.isNotEmpty) ? slug : null;

  Future<void> _pick({required bool isA}) async {
    final item = await Navigator.of(context).push<ProductListItem>(
      MaterialPageRoute<ProductListItem>(
        builder: (context) =>
            SearchScreen(onPick: (item) => Navigator.of(context).pop(item)),
      ),
    );
    if (item == null || item.slug.isEmpty || !mounted) return;
    ref.invalidate(productProvider(item.slug));
    setState(() => isA ? _a = item.slug : _b = item.slug);
  }

  @override
  Widget build(BuildContext context) {
    final aAsync = _a != null ? ref.watch(productProvider(_a!)) : null;
    final bAsync = _b != null ? ref.watch(productProvider(_b!)) : null;
    final a = aAsync?.valueOrNull;
    final b = bAsync?.valueOrNull;

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _CompareHeader(),
              const SizedBox(height: 20),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: _PickerSlot(
                        label: 'Product A',
                        async: aAsync,
                        onPick: () => _pick(isA: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PickerSlot(
                        label: 'Product B',
                        async: bAsync,
                        onPick: () => _pick(isA: false),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (a != null && b != null)
                _ComparisonSheet(a: a, b: b)
              else
                _EmptyHint(
                  bothEmpty: _a == null && _b == null,
                  onBrowse: () => _pick(isA: _a == null),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompareHeader extends StatelessWidget {
  const _CompareHeader();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Eyebrow('Head to head'),
        const SizedBox(height: 6),
        Text(
          'Compare',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: palette.inkPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pick two products and see which wins.',
          style: TextStyle(fontSize: 14, color: palette.inkFaint),
        ),
      ],
    );
  }
}

class _PickerSlot extends StatelessWidget {
  const _PickerSlot({
    required this.label,
    required this.async,
    required this.onPick,
  });

  final String label;
  final AsyncValue<AnalysisResult>? async;
  final VoidCallback onPick;

  BoxDecoration _cardDecoration(BuildContext context) {
    final palette = context.palette;
    return BoxDecoration(
      color: palette.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: palette.hairline),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final value = async;
    if (value == null) return _empty(context);
    return value.when(
      loading: () => Container(
        height: 128,
        decoration: _cardDecoration(context),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, _) => _tappable(
        context,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.refresh, size: 20, color: palette.inkSecondary),
            const SizedBox(height: 6),
            Text(
              'Tap to pick another',
              style: TextStyle(fontSize: 13, color: palette.inkSecondary),
            ),
          ],
        ),
      ),
      data: (result) => Container(
        decoration: _cardDecoration(context),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Eyebrow(label, size: 10, spacing: 3),
            const SizedBox(height: 8),
            Text(
              result.productName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: palette.inkPrimary,
              ),
            ),
            if (result.brand != null && result.brand!.isNotEmpty)
              Text(
                result.brand!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: palette.inkFaint),
              ),
            const SizedBox(height: 10),
            InkWell(
              onTap: onPick,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.close, size: 12, color: palette.inkFaint),
                  const SizedBox(width: 4),
                  Text(
                    'change',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: palette.inkFaint,
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

  Widget _empty(BuildContext context) {
    final palette = context.palette;
    return _tappable(
      context,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Eyebrow(label, size: 10, spacing: 3),
          const SizedBox(height: 10),
          Icon(Icons.add, size: 20, color: palette.inkGhost),
          const SizedBox(height: 6),
          Text(
            'Add product',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: palette.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tappable(BuildContext context, {required Widget child}) => InkWell(
    onTap: onPick,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      height: 128,
      decoration: _cardDecoration(context),
      alignment: Alignment.center,
      child: child,
    ),
  );
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.bothEmpty, required this.onBrowse});

  final bool bothEmpty;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: <Widget>[
            Icon(Icons.compare_arrows, size: 40, color: palette.inkGhost),
            const SizedBox(height: 12),
            Text(
              bothEmpty
                  ? 'Add two products to compare them.'
                  : 'Add one more product to see the comparison.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: palette.inkFaint),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: onBrowse,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Browse products',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: palette.inkSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward,
                    size: 15,
                    color: palette.inkSecondary,
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

/// (winning side 'a' | 'b' | '', a human reason) — the web's better-pick logic.
({String side, String reason}) _betterOf(AnalysisResult a, AnalysisResult b) {
  if (a.verdictScore != b.verdictScore) {
    return (
      side: a.verdictScore > b.verdictScore ? 'a' : 'b',
      reason: 'Higher score',
    );
  }
  if (a.verdict.index != b.verdict.index) {
    return (
      side: a.verdict.index < b.verdict.index ? 'a' : 'b',
      reason: 'Cleaner verdict',
    );
  }
  final na = a.novaGroup;
  final nb = b.novaGroup;
  if (na != null && nb != null && na != nb) {
    return (side: na < nb ? 'a' : 'b', reason: 'Less processed');
  }
  return (side: '', reason: '');
}

int _flaggedCount(AnalysisResult r) => r.ingredientsDetected
    .where(
      (i) =>
          i.rating == SafetyRating.concerning ||
          i.rating == SafetyRating.harmful,
    )
    .length;

int _misleadingCount(AnalysisResult r) =>
    r.marketingClaims.where((c) => c.isMisleading).length;

class _ComparisonSheet extends StatelessWidget {
  const _ComparisonSheet({required this.a, required this.b});

  final AnalysisResult a;
  final AnalysisResult b;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final best = _betterOf(a, b);
    final side = best.side;

    final showNova = a.novaGroup != null || b.novaGroup != null;
    final showIngredients =
        a.ingredientsDetected.isNotEmpty || b.ingredientsDetected.isNotEmpty;
    final showHonesty =
        a.marketingClaims.isNotEmpty || b.marketingClaims.isNotEmpty;
    final showSoy = a.containsSoy || b.containsSoy;
    final showEggs = a.containsEggs || b.containsEggs;

    final rows = <Widget>[
      _row(
        context,
        'Score',
        a: _ScoreCell(result: a),
        b: _ScoreCell(result: b),
        side: side,
        first: true,
      ),
      _row(
        context,
        'Verdict',
        a: _VerdictCell(result: a),
        b: _VerdictCell(result: b),
        side: side,
      ),
      if (showNova)
        _row(
          context,
          'Processing',
          a: _NovaCell(a.novaGroup),
          b: _NovaCell(b.novaGroup),
          side: side,
        ),
      _row(
        context,
        'Vegan',
        a: _YesNo(a.isVegan),
        b: _YesNo(b.isVegan),
        side: side,
      ),
      _row(
        context,
        'Gluten-free',
        a: _YesNo(a.isGlutenFree),
        b: _YesNo(b.isGlutenFree),
        side: side,
      ),
      _row(
        context,
        'Dairy-free',
        a: _YesNo(a.isDairyFree),
        b: _YesNo(b.isDairyFree),
        side: side,
      ),
      _row(
        context,
        'Nut-free',
        a: _YesNo(!a.containsNuts),
        b: _YesNo(!b.containsNuts),
        side: side,
      ),
      if (showSoy)
        _row(
          context,
          'Soy-free',
          a: _YesNo(!a.containsSoy),
          b: _YesNo(!b.containsSoy),
          side: side,
        ),
      if (showEggs)
        _row(
          context,
          'Egg-free',
          a: _YesNo(!a.containsEggs),
          b: _YesNo(!b.containsEggs),
          side: side,
        ),
      if (showIngredients)
        _row(
          context,
          'Ingredients',
          a: _CountCell(a.ingredientsDetected.length),
          b: _CountCell(b.ingredientsDetected.length),
          side: side,
        ),
      if (showIngredients)
        _row(
          context,
          'Flagged',
          a: _FlaggedCell(_flaggedCount(a)),
          b: _FlaggedCell(_flaggedCount(b)),
          side: side,
        ),
      if (showHonesty)
        _row(
          context,
          'Marketing',
          a: _HonestyCell(_misleadingCount(a)),
          b: _HonestyCell(_misleadingCount(b)),
          side: side,
        ),
    ];

    return Column(
      children: <Widget>[
        _Callout(best: best, winner: side == 'a' ? a : b),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: palette.surface,
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
                _headerRow(context, a: a, b: b, side: side),
                ...rows,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _headerRow(
    BuildContext context, {
    required AnalysisResult a,
    required AnalysisResult b,
    required String side,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(width: 84, color: context.palette.surfaceAlt),
          Expanded(
            child: _NameCell(result: a, winner: side == 'a'),
          ),
          Expanded(
            child: _NameCell(result: b, winner: side == 'b', left: true),
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label, {
    required Widget a,
    required Widget b,
    required String side,
    bool first = false,
  }) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: first
            ? null
            : Border(top: BorderSide(color: palette.hairlineFaint)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              width: 84,
              color: palette.surfaceAlt,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              alignment: Alignment.centerLeft,
              child: Eyebrow(label, size: 10, spacing: 1.5),
            ),
            Expanded(child: _cell(context, a, side == 'a')),
            Expanded(child: _cell(context, b, side == 'b', left: true)),
          ],
        ),
      ),
    );
  }

  Widget _cell(
    BuildContext context,
    Widget child,
    bool win, {
    bool left = false,
  }) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: win ? _winTint : null,
        border: left
            ? Border(left: BorderSide(color: context.palette.hairlineFaint))
            : null,
      ),
      child: child,
    );
  }
}

class _Callout extends StatelessWidget {
  const _Callout({required this.best, required this.winner});

  final ({String side, String reason}) best;
  final AnalysisResult winner;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (best.side.isEmpty) {
      return Column(
        children: <Widget>[
          const Eyebrow('Evenly matched', align: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'A genuine toss-up — identical on every measure.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: palette.inkSecondary,
            ),
          ),
        ],
      );
    }
    return Column(
      children: <Widget>[
        const Eyebrow('Better choice', align: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          winner.productName,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 24,
            height: 1.1,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: palette.inkPrimary,
          ),
        ),
        const SizedBox(height: 12),
        MetaPill(
          text: best.reason,
          leading: '🏆',
          fg: _emeraldText,
          bg: const Color(0xFFECFDF5),
          border: const Color(0xFFA7F3D0),
        ),
      ],
    );
  }
}

class _NameCell extends StatelessWidget {
  const _NameCell({
    required this.result,
    required this.winner,
    this.left = false,
  });

  final AnalysisResult result;
  final bool winner;
  final bool left;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      decoration: BoxDecoration(
        color: winner ? _winTint : palette.surface,
        border: left
            ? Border(left: BorderSide(color: palette.hairlineFaint))
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (winner) ...<Widget>[
            const Eyebrow(
              '★ Better pick',
              size: 9,
              spacing: 1,
              color: _emeraldText,
              align: TextAlign.center,
            ),
            const SizedBox(height: 4),
          ],
          Text(
            result.productName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: palette.inkPrimary,
            ),
          ),
          if (result.brand != null && result.brand!.isNotEmpty)
            Text(
              result.brand!,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: palette.inkFaint),
            ),
        ],
      ),
    );
  }
}

class _ScoreCell extends StatelessWidget {
  const _ScoreCell({required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final tone = verdictToneFor(result.verdict);
    return Text.rich(
      TextSpan(
        children: <TextSpan>[
          TextSpan(
            text: '${result.verdictScore}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: tone.word,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          TextSpan(
            text: ' /90',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: context.palette.inkGhost,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerdictCell extends StatelessWidget {
  const _VerdictCell({required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: WebVerdictBadge(verdict: result.verdict, size: 10),
    );
  }
}

class _NovaCell extends StatelessWidget {
  const _NovaCell(this.nova);

  final int? nova;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final n = nova;
    if (n == null || n < 1 || n > 4) {
      return Icon(Icons.remove, size: 14, color: palette.inkGhost);
    }
    final color = n == 4
        ? const Color(0xFFEF4444)
        : (n == 3 ? const Color(0xFFF59E0B) : const Color(0xFF10B981));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ConcernDot(color: color, size: 7, semanticLabel: 'NOVA $n'),
        const SizedBox(width: 6),
        Text(
          'NOVA $n',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: palette.inkSecondary,
          ),
        ),
      ],
    );
  }
}

class _YesNo extends StatelessWidget {
  const _YesNo(this.value);

  final bool value;

  @override
  Widget build(BuildContext context) {
    if (!value) {
      return Icon(Icons.remove, size: 16, color: context.palette.inkGhost);
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: const Icon(Icons.check, size: 13, color: _emeraldText),
    );
  }
}

class _CountCell extends StatelessWidget {
  const _CountCell(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (count == 0) {
      return Icon(Icons.remove, size: 16, color: palette.inkGhost);
    }
    return Text(
      '$count',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: palette.inkPrimary,
      ),
    );
  }
}

class _FlaggedCell extends StatelessWidget {
  const _FlaggedCell(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$count',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: count > 0 ? _redText : _emeraldText,
      ),
    );
  }
}

class _HonestyCell extends StatelessWidget {
  const _HonestyCell(this.misleading);

  final int misleading;

  @override
  Widget build(BuildContext context) {
    return Text(
      misleading > 0 ? '$misleading flagged' : 'Clean',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: misleading > 0 ? _redText : _emeraldText,
      ),
    );
  }
}
