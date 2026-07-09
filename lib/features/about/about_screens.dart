import 'package:flutter/material.dart';
import 'package:munch_or_dump/core/models/verdict.dart';
import 'package:munch_or_dump/core/theme/palette.dart';
import 'package:munch_or_dump/core/widgets/editorial.dart';

/// Shared content-page scaffold: an app bar + a padded scroll of [children].
class _ContentScaffold extends StatelessWidget {
  const _ContentScaffold({required this.appBarTitle, required this.children});

  final String appBarTitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        children: children,
      ),
    );
  }
}

Widget _header(Palette palette, String eyebrow, String title, [String? muted]) {
  final dark = TextStyle(
    fontSize: 30,
    height: 1.12,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
    color: palette.inkPrimary,
  );
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Eyebrow(eyebrow, spacing: 4),
      const SizedBox(height: 12),
      Text.rich(
        TextSpan(
          children: <TextSpan>[
            TextSpan(text: title, style: dark),
            if (muted != null)
              TextSpan(
                text: '\n$muted',
                style: dark.copyWith(color: palette.inkFaint),
              ),
          ],
        ),
      ),
      const SizedBox(height: 20),
    ],
  );
}

Widget _lead(Palette palette, String text) => Padding(
  padding: const EdgeInsets.only(bottom: 14),
  child: Text(
    text,
    style: TextStyle(fontSize: 17, height: 1.55, color: palette.inkSecondary),
  ),
);

Widget _para(Palette palette, String text) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Text(
    text,
    style: TextStyle(fontSize: 14.5, height: 1.55, color: palette.inkSecondary),
  ),
);

Widget _sectionEyebrow(String text) => Padding(
  padding: const EdgeInsets.only(top: 16, bottom: 14),
  child: Eyebrow(text, spacing: 3.2),
);

/// The satire/disclaimer footer echoed from the web footer.
class SatireFooter extends StatelessWidget {
  const SatireFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Divider(color: palette.hairline, height: 32),
        Text.rich(
          TextSpan(
            children: <TextSpan>[
              TextSpan(
                text: 'AI-generated satire. ',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: palette.inkSecondary,
                ),
              ),
              const TextSpan(
                text:
                    'Verdicts are a subjective, automated opinion — not '
                    'statements of fact, and they may be inaccurate. Not '
                    'health, dietary, or safety advice. Not affiliated with '
                    'any brand.',
              ),
            ],
          ),
          style: TextStyle(fontSize: 12, height: 1.5, color: palette.inkFaint),
        ),
        const SizedBox(height: 10),
        Text(
          '© 2026 Munch or Dump · hello@munchordump.com',
          style: TextStyle(fontSize: 12, color: palette.inkFaint),
        ),
      ],
    );
  }
}

/// About — why the product exists + its principles.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return _ContentScaffold(
      appBarTitle: 'About',
      children: <Widget>[
        _header(palette, 'About', 'A tool for truth', 'about products.'),
        _lead(
          palette,
          'Munch or Dump exists because product packaging is designed to sell, '
          'not to inform. Marketing teams spend millions making products look '
          'healthy, natural, or premium.',
        ),
        _lead(
          palette,
          'The ingredient list tells the real story. But it’s small, dense, and '
          'deliberately hard to parse.',
        ),
        _lead(
          palette,
          'We built a tool that reads labels like a scientist and explains them '
          'like a friend. Scan an ingredient label. Get the truth in seconds.',
        ),
        _sectionEyebrow('Our principles'),
        const _Principle(
          title: 'We analyze labels, not brands.',
          detail:
              'We have no relationship with any food, beauty, or supplement '
              'brand. Our analysis is based solely on what appears on the '
              'ingredient list and nutrition panel.',
        ),
        const _Principle(
          title: 'We prioritize transparency.',
          detail:
              'Every verdict shows its evidence — the parsed ingredients and '
              'the reasoning. You can verify everything yourself.',
        ),
        const _Principle(
          title: 'We show evidence.',
          detail:
              'No black boxes. No mysterious algorithms. We tell you exactly '
              'what we found, what concerns us, and why we reached our verdict.',
        ),
        const _Principle(
          title: 'We’re brutally honest.',
          detail:
              'If a product is good, we say so. If it’s garbage with good '
              'marketing, we say that too. The truth doesn’t need a filter.',
        ),
        const SizedBox(height: 20),
        const _DarkQuote(
          quote: 'Packaging says healthy.\nIngredients say otherwise.',
          attribution: 'The problem Munch or Dump was built to solve.',
        ),
        const SizedBox(height: 24),
        const SatireFooter(),
      ],
    );
  }
}

/// How It Works — the 3-step method, the six verdicts, and the disclaimer.
class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  static const Map<Verdict, String> _verdictDesc = <Verdict, String>{
    Verdict.munch: 'Clean formulation. Worth it.',
    Verdict.okay: 'Not great, not terrible. Use occasionally.',
    Verdict.treat: 'Fine as an indulgence. Not everyday.',
    Verdict.engineered: 'Lab-designed for palatability.',
    Verdict.dump: 'Poor ingredients. Avoid if possible.',
    Verdict.bullshit: 'Misleading marketing — the ingredients say otherwise.',
  };

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return _ContentScaffold(
      appBarTitle: 'How it works',
      children: <Widget>[
        _header(
          palette,
          'How it works',
          'From label to verdict, in under 30 seconds.',
        ),
        _lead(
          palette,
          'No jargon. No guesswork. Just an honest read of what’s actually in '
          'the product.',
        ),
        const SizedBox(height: 12),
        const _Step(
          number: '1',
          title: 'Scan the product',
          description: 'Point at a barcode, or snap the ingredient label.',
        ),
        const _Step(
          number: '2',
          title: 'We read the label',
          description:
              'Ingredients and nutrition facts are extracted and '
              'analyzed.',
        ),
        const _Step(
          number: '3',
          title: 'Get a clear verdict',
          description:
              'MUNCH, OKAY, TREAT, ENGINEERED, DUMP, or BULLSHIT — '
              'with the evidence.',
          last: true,
        ),
        const SizedBox(height: 8),
        _sectionEyebrow('The six verdicts'),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.hairline),
          ),
          child: Column(
            children: <Widget>[
              for (final entry in _verdictDesc.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 108,
                        child: WebVerdictBadge(verdict: entry.key, size: 11),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 13,
                            color: palette.inkSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        _sectionEyebrow('How a verdict is made'),
        Text(
          'One automated opinion, generated in seconds.',
          style: TextStyle(
            fontSize: 20,
            height: 1.2,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: palette.inkPrimary,
          ),
        ),
        const SizedBox(height: 10),
        _para(
          palette,
          'Every product is fed to an AI model along with its available label '
          'and nutrition data. The model returns one of six verdicts. That is '
          'the whole process — one automated opinion, generated in seconds, '
          'with all the confidence and none of the accountability of a real '
          'person. Take it as a vibe, not a verdict you’d stake your health on.',
        ),
        _sectionEyebrow('Disclaimer'),
        _para(
          palette,
          'Munch or Dump is satire and entertainment. Every verdict is '
          'generated by an AI model and reflects a subjective, automated '
          'opinion, not a factual assessment of any product, brand, or company.',
        ),
        _para(
          palette,
          'AI makes mistakes. Verdicts may contain errors, including wrong '
          'ingredients, outdated information, or invented details. Nothing here '
          'is a substitute for reading the actual product label, nutrition '
          'facts, or allergen information. Do not rely on this app for health, '
          'dietary, allergy, or safety decisions.',
        ),
        _para(
          palette,
          'Found something wrong? Email hello@munchordump.com and we’ll review '
          'or remove it promptly.',
        ),
        const SizedBox(height: 12),
        const SatireFooter(),
      ],
    );
  }
}

/// Our Story — the why, kept honest.
class OurStoryScreen extends StatelessWidget {
  const OurStoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return _ContentScaffold(
      appBarTitle: 'Our story',
      children: <Widget>[
        _header(
          palette,
          'Our story',
          'We built this so you’d',
          'stop being lied to.',
        ),
        _lead(
          palette,
          'Munch or Dump exists because food packaging is designed to deceive. '
          '“Natural.” “Wholesome.” “Clean.” All marketing. None of it '
          'regulated. We got tired of it.',
        ),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.only(left: 16),
          decoration: Border(
            left: BorderSide(color: palette.inkGhost, width: 2),
          ).toBoxDecoration(),
          child: Text(
            '“So we built something that reads the label like a scientist and '
            'explains it like a friend. No agenda. No sponsors. Just the truth '
            'about what’s in your food.”',
            style: TextStyle(
              fontSize: 15,
              height: 1.55,
              fontStyle: FontStyle.italic,
              color: palette.inkSecondary,
            ),
          ),
        ),
        _sectionEyebrow('How we keep it honest'),
        const _HonestCard(
          stat: 'Independent',
          label: 'no investors, no ads',
          detail:
              'No VC money, no brand sponsorships, no affiliate deals. Nobody '
              'pays us to reach a verdict — so nobody can buy a better one.',
        ),
        const _HonestCard(
          stat: 'Free to use',
          label: 'core scanning, on us',
          detail: 'No selling your scans or your data. You use it for free.',
        ),
        const _HonestCard(
          stat: 'Opinionated',
          label: 'blunt by design',
          detail:
              'Every verdict is one automated, subjective opinion — sometimes '
              'wrong, never sponsored. We’d rather be sharp than safe.',
        ),
        _sectionEyebrow('Why it’s free'),
        _para(
          palette,
          'No ads. No selling your data. No brand money. The verdicts stay '
          'honest because nobody’s paying us to say otherwise.',
        ),
        _para(
          palette,
          'The best thing you can do is simple: keep scanning, and tell a '
          'friend who’s tired of being lied to. That’s what this is for.',
        ),
        const SizedBox(height: 12),
        const SatireFooter(),
      ],
    );
  }
}

class _Principle extends StatelessWidget {
  const _Principle({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: Border(
        top: BorderSide(color: palette.hairline),
      ).toBoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: palette.inkPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: palette.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkQuote extends StatelessWidget {
  const _DarkQuote({required this.quote, required this.attribution});

  final String quote;
  final String attribution;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.ctaBlack,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            quote,
            style: TextStyle(
              fontSize: 24,
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: palette.ctaForeground,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '— $attribution',
            style: TextStyle(
              fontSize: 13,
              color: palette.ctaForeground.withValues(alpha: 0.62),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.description,
    this.last = false,
  });

  final String number;
  final String title;
  final String description;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: palette.inkPrimary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  number,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: palette.ctaForeground,
                  ),
                ),
              ),
              if (!last)
                Expanded(
                  child: SizedBox(
                    width: 1,
                    child: ColoredBox(color: palette.hairline),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 4, bottom: last ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: palette.inkPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: palette.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HonestCard extends StatelessWidget {
  const _HonestCard({
    required this.stat,
    required this.label,
    required this.detail,
  });

  final String stat;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text.rich(
            TextSpan(
              children: <TextSpan>[
                TextSpan(
                  text: stat,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: palette.inkPrimary,
                  ),
                ),
                TextSpan(
                  text: '  $label',
                  style: TextStyle(fontSize: 13, color: palette.inkFaint),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: palette.inkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// A `Border` → `BoxDecoration` shorthand for the one-sided borders above.
extension _BorderDecoration on Border {
  BoxDecoration toBoxDecoration() => BoxDecoration(border: this);
}
