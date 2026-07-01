import 'dart:async';

import 'package:flutter/material.dart';
import 'package:munch_or_dump/core/models/verdict.dart';
import 'package:munch_or_dump/core/theme/app_colors.dart';
import 'package:munch_or_dump/core/theme/verdict_palette.dart';

/// The editorial design language ported from munchordump.com: a graph-paper
/// canvas, ultra-letter-spaced eyebrows, two-tone headlines, a pure-black pill
/// CTA, verdict badges, accent-top-border cards, and meta pills.

/// Faint square grid behind hero content. 60px cells, black @ 2.2% — the
/// website's "lab paper" texture.
class GraphPaperPainter extends CustomPainter {
  const GraphPaperPainter({this.cell = 60});

  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromRGBO(0, 0, 0, 0.022)
      ..strokeWidth = 1
      ..isAntiAlias = false;
    for (double x = 0; x <= size.width; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(GraphPaperPainter oldDelegate) => oldDelegate.cell != cell;
}

/// Stacks the graph-paper grid under [child]. With [fade], the grid dissolves
/// toward the bottom so it doesn't fight scrolling content.
class GridBackground extends StatelessWidget {
  const GridBackground({required this.child, this.fade = true, super.key});

  final Widget child;
  final bool fade;

  @override
  Widget build(BuildContext context) {
    Widget grid = const Positioned.fill(
      child: IgnorePointer(child: CustomPaint(painter: GraphPaperPainter())),
    );
    if (fade) {
      grid = Positioned.fill(
        child: IgnorePointer(
          child: ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Colors.white, Colors.transparent],
              stops: <double>[0.5, 1],
            ).createShader(rect),
            blendMode: BlendMode.dstIn,
            child: const CustomPaint(painter: GraphPaperPainter()),
          ),
        ),
      );
    }
    return Stack(children: <Widget>[grid, child]);
  }
}

/// A letter-spaced uppercase label — the signature editorial move.
class Eyebrow extends StatelessWidget {
  const Eyebrow(
    this.text, {
    this.size = 12,
    this.spacing = 5.5,
    this.color = AppColors.inkFaint,
    this.align = TextAlign.start,
    super.key,
  });

  final String text;
  final double size;
  final double spacing;
  final Color color;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      textAlign: align,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: spacing,
        color: color,
        height: 1.2,
      ),
    );
  }
}

/// Two-tone headline: [dark] ink + [muted] grey, w800, tight. The muted phrase
/// usually wraps onto the next line at the available width.
class TwoToneHeadline extends StatelessWidget {
  const TwoToneHeadline({
    required this.dark,
    required this.muted,
    this.size = 34,
    this.align = TextAlign.center,
    super.key,
  });

  final String dark;
  final String muted;
  final double size;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w800,
      height: 1.05,
      letterSpacing: -0.8,
    );
    return Text.rich(
      TextSpan(
        children: <TextSpan>[
          TextSpan(
            text: dark,
            style: base.copyWith(color: AppColors.inkPrimary),
          ),
          const TextSpan(text: ' '),
          TextSpan(
            text: muted,
            style: base.copyWith(color: AppColors.inkFaint),
          ),
        ],
      ),
      textAlign: align,
    );
  }
}

/// The pure-black pill CTA ("Analyze a product"). Not the themed emerald button.
///
/// [expand] stretches it full-width (for form submits); [busy] swaps the label
/// for a spinner and blocks taps; [enabled]:false dims it and blocks taps.
class BlackCtaButton extends StatefulWidget {
  const BlackCtaButton({
    required this.label,
    required this.onTap,
    this.leadingIcon,
    this.trailingIcon = Icons.arrow_forward,
    this.expand = false,
    this.busy = false,
    this.enabled = true,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool expand;
  final bool busy;
  final bool enabled;

  @override
  State<BlackCtaButton> createState() => _BlackCtaButtonState();
}

class _BlackCtaButtonState extends State<BlackCtaButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.busy || !widget.enabled;
    return Semantics(
      button: true,
      enabled: !disabled,
      label: widget.busy ? '${widget.label}, loading' : widget.label,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
          onTapCancel: disabled ? null : () => setState(() => _pressed = false),
          onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
          onTap: disabled ? null : widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 48,
            width: widget.expand ? double.infinity : null,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            decoration: BoxDecoration(
              color: !widget.enabled
                  ? const Color(0xFF9C968F)
                  : (_pressed ? AppColors.ctaPressed : AppColors.ctaBlack),
              borderRadius: BorderRadius.circular(999),
              boxShadow: disabled
                  ? null
                  : const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x141C1917),
                        blurRadius: 18,
                        offset: Offset(0, 6),
                      ),
                    ],
            ),
            child: widget.busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: widget.expand
                        ? MainAxisSize.max
                        : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      if (widget.leadingIcon != null) ...<Widget>[
                        Icon(widget.leadingIcon, size: 16, color: Colors.white),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.trailingIcon != null) ...<Widget>[
                        const SizedBox(width: 10),
                        AnimatedSlide(
                          duration: const Duration(milliseconds: 120),
                          offset: Offset(_pressed ? 0.18 : 0, 0),
                          child: Icon(
                            widget.trailingIcon,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// A verdict pill: `[dot] WORD` in the verdict's tones.
class WebVerdictBadge extends StatelessWidget {
  const WebVerdictBadge({required this.verdict, this.size = 12, super.key});

  final Verdict verdict;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tone = verdictToneFor(verdict);
    return Semantics(
      label: '${verdict.label} verdict',
      child: ExcludeSemantics(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: size * 1.2,
            vertical: size / 3,
          ),
          decoration: BoxDecoration(
            color: tone.tint,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: tone.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: tone.dot,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                verdict.label.toUpperCase(),
                style: TextStyle(
                  fontSize: size,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: tone.word,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A white card with a colored top stripe — the website's product card.
class AccentTopBorderCard extends StatelessWidget {
  const AccentTopBorderCard({
    required this.accent,
    required this.child,
    this.stripeHeight = 4,
    this.padding = const EdgeInsets.all(24),
    this.onTap,
    super.key,
  });

  final Color accent;
  final Widget child;
  final double stripeHeight;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
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
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(height: stripeHeight, color: accent),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: card,
    );
  }
}

/// A small pill (country / NOVA / dietary). [leading] is an emoji or glyph.
class MetaPill extends StatelessWidget {
  const MetaPill({
    required this.text,
    required this.fg,
    required this.bg,
    required this.border,
    this.leading,
    this.upper = false,
    super.key,
  });

  final String text;
  final Color fg;
  final Color bg;
  final Color border;
  final String? leading;
  final bool upper;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        leading == null ? text : '$leading $text',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: upper ? 0.6 : 0.2,
          color: fg,
        ),
      ),
    );
  }
}

/// A small filled circle keyed to a concern color. [semanticLabel] gives
/// VoiceOver the severity that the color alone encodes.
class ConcernDot extends StatelessWidget {
  const ConcernDot({
    required this.color,
    this.size = 8,
    this.semanticLabel,
    super.key,
  });

  final Color color;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    if (semanticLabel == null) return dot;
    return Semantics(label: semanticLabel, child: dot);
  }
}

/// A signed impact score (+10 / −8), green for positive, red for negative.
/// Renders nothing for |score| < 2.
class ImpactScore extends StatelessWidget {
  const ImpactScore({required this.score, super.key});

  final int score;

  @override
  Widget build(BuildContext context) {
    if (score.abs() < 2) return const SizedBox.shrink();
    return Text(
      score > 0 ? '+$score' : '$score',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        color: score > 0 ? AppColors.impactPositive : AppColors.impactNegative,
      ),
    );
  }
}

/// An eyebrow flanked by hairlines — the "Recently analyzed" divider.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(child: Divider(color: AppColors.hairline, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Eyebrow(text, spacing: 4.2),
        ),
        const Expanded(child: Divider(color: AppColors.hairline, thickness: 1)),
      ],
    );
  }
}

class _RollWord {
  const _RollWord(this.word, this.color);
  final String word;
  final Color color;
}

const List<_RollWord> _verdictRoll = <_RollWord>[
  _RollWord('MUNCH', Color(0xFF059669)),
  _RollWord('OKAY', Color(0xFF0EA5E9)),
  _RollWord('TREAT', Color(0xFFF59E0B)),
  _RollWord('ENGINEERED', Color(0xFF64748B)),
  _RollWord('DUMP', Color(0xFFEF4444)),
  _RollWord('BULLSHIT', Color(0xFFA855F7)),
];

const List<String> _analysisSteps = <String>[
  'Reading ingredients',
  'Checking formula',
  'Evaluating additives',
  'Cross-referencing database',
  'Forming verdict',
];

/// The cycling verdict word: MUNCH→OKAY→…→BULLSHIT, one every 600ms, each
/// sliding up + fading in. Shared by [PageLoader] and [AnalysisLoader].
class _RollingWord extends StatefulWidget {
  const _RollingWord();

  @override
  State<_RollingWord> createState() => _RollingWordState();
}

class _RollingWordState extends State<_RollingWord> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (mounted) setState(() => _index = (_index + 1) % _verdictRoll.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roll = _verdictRoll[_index];
    return SizedBox(
      height: 48,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.5),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Text(
            roll.word,
            key: ValueKey<int>(_index),
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 6,
              color: roll.color,
            ),
          ),
        ),
      ),
    );
  }
}

/// General page-load wait (~1-2s): the rolling verdict word over the cream
/// canvas with a "Loading {label}…" caption — the website's PageLoader.
class PageLoader extends StatelessWidget {
  const PageLoader({this.label = 'verdict', super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.canvas,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const _RollingWord(),
            const SizedBox(height: 12),
            Text(
              'LOADING ${label.toUpperCase()}…',
              style: const TextStyle(
                fontSize: 12,
                letterSpacing: 3.6,
                color: AppColors.inkFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen wait state while the verdict is generated: the verdict word rolls
/// (slide-up + fade) every 600ms over the cream canvas, with step labels that
/// advance every 3.2s — the website's AnalysisLoader.
class AnalysisLoader extends StatefulWidget {
  const AnalysisLoader({this.productName, super.key});

  final String? productName;

  @override
  State<AnalysisLoader> createState() => _AnalysisLoaderState();
}

class _AnalysisLoaderState extends State<AnalysisLoader> {
  int _step = 0;
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    _stepTimer = Timer.periodic(const Duration(milliseconds: 3200), (_) {
      if (mounted && _step < _analysisSteps.length - 1) {
        setState(() => _step++);
      }
    });
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.productName?.trim() ?? '';
    return Material(
      color: AppColors.canvas,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const _RollingWord(),
            if (name.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkSecondary,
                ),
              ),
            ],
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                '${_analysisSteps[_step].toUpperCase()}…',
                key: ValueKey<int>(_step),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  letterSpacing: 3.6,
                  color: AppColors.inkFaint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
