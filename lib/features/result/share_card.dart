import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:munch_or_dump/core/models/analysis_result.dart';
import 'package:munch_or_dump/core/theme/palette.dart';
import 'package:munch_or_dump/core/theme/verdict_palette.dart';
import 'package:munch_or_dump/core/widgets/editorial.dart';

/// The branded verdict share card + its offscreen PNG renderer, behind the
/// "Share this verdict" action.

/// The card always renders the light editorial look — [Palette.light] read
/// directly, never `context.palette` — so the shared image is identical
/// whether the phone is in light or dark mode.
const Palette _light = Palette.light;

/// A fixed-size 1080x1080 branded verdict card in the website's editorial
/// language: graph-paper cream canvas, the letter-spaced wordmark, product
/// name + brand, the giant verdict word in its verdict tones, the score line,
/// a short explanation, and a black `munchordump.com` CTA strip.
///
/// Rendered offscreen by [renderShareCard] and captured at `pixelRatio: 1`,
/// producing a 1080x1080 PNG for the system share sheet.
class ShareCardWidget extends StatelessWidget {
  const ShareCardWidget({required this.result, super.key});

  /// Logical edge length — captured at `pixelRatio: 1` → a 1080x1080 PNG.
  static const double dimension = 1080;

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final tone = verdictToneFor(result.verdict);
    final name = result.productName.trim().isEmpty
        ? 'Product verdict'
        : result.productName.trim();
    final brand = result.brand;
    final lead = result.shortExplanation?.trim() ?? '';

    return SizedBox(
      width: dimension,
      height: dimension,
      child: Material(
        color: _light.canvas,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // The website's "lab paper" texture, pinned to the light grid tone.
            IgnorePointer(
              child: CustomPaint(
                painter: GraphPaperPainter(cell: 72, color: _light.gridLine),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(height: 14, color: tone.bar),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(72, 60, 72, 56),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: tone.bar,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 18),
                            Eyebrow(
                              'Munch or Dump',
                              size: 30,
                              spacing: 9,
                              color: _light.inkFaint,
                            ),
                          ],
                        ),
                        const SizedBox(height: 52),
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 62,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.2,
                            color: _light.inkPrimary,
                          ),
                        ),
                        if (brand != null && brand.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 14),
                          Text(
                            brand,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 32,
                              color: _light.inkFaint,
                            ),
                          ),
                        ],
                        const SizedBox(height: 44),
                        Expanded(
                          child: _VerdictPanel(result: result, tone: tone),
                        ),
                        if (lead.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 44),
                          Text(
                            lead,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 36,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                              color: _light.inkPrimary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const _CtaStrip(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The tinted verdict panel — the hero treatment from the result screen:
/// eyebrow, emoji + giant verdict word in `tone.word`, `SCORE n / 90` in
/// `tone.mid`.
class _VerdictPanel extends StatelessWidget {
  const _VerdictPanel({required this.result, required this.tone});

  final AnalysisResult result;
  final VerdictTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 40),
      decoration: BoxDecoration(
        color: tone.tint,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: tone.border, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Eyebrow(
            'Verdict',
            size: 24,
            spacing: 11,
            color: _light.inkFaint,
            align: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    result.verdict.emoji,
                    style: const TextStyle(fontSize: 104),
                  ),
                  const SizedBox(width: 28),
                  Text(
                    result.verdict.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 190,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -4,
                      color: tone.word,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 34),
          Text(
            'SCORE ${result.verdictScore} / 90',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w600,
              letterSpacing: 9,
              color: tone.mid,
            ),
          ),
        ],
      ),
    );
  }
}

/// The bottom CTA strip — the pure-black editorial pill, stretched into a bar:
/// `munchordump.com` + a letter-spaced "scan it yourself" prompt.
class _CtaStrip extends StatelessWidget {
  const _CtaStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 124,
      color: _light.ctaBlack,
      padding: const EdgeInsets.symmetric(horizontal: 72),
      child: Row(
        children: <Widget>[
          Text(
            'munchordump.com',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: _light.ctaForeground,
            ),
          ),
          const Spacer(),
          const Text(
            'SCAN IT YOURSELF',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              letterSpacing: 6,
              color: Color(0xB3FFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders [ShareCardWidget] offscreen and captures it as a 1080x1080 PNG.
///
/// Inserts an [OverlayEntry] positioned well outside the visible screen
/// (wrapped in [MediaQuery]/[Theme] copies from [context] so fonts and text
/// scaling resolve), waits two frames for layout + paint to settle, then
/// snapshots the [RepaintBoundary]. The entry is always removed, and any
/// failure returns null — callers fall back to text-only sharing.
Future<Uint8List?> renderShareCard(
  BuildContext context,
  AnalysisResult result,
) async {
  final OverlayState? overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return null;

  final boundaryKey = GlobalKey();
  final mediaQuery = MediaQuery.of(context);
  final theme = Theme.of(context);

  final entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -2 * ShareCardWidget.dimension,
      top: 0,
      child: IgnorePointer(
        child: MediaQuery(
          data: mediaQuery.copyWith(
            size: const Size(
              ShareCardWidget.dimension,
              ShareCardWidget.dimension,
            ),
            devicePixelRatio: 1,
            textScaler: TextScaler.noScaling,
            padding: EdgeInsets.zero,
            viewPadding: EdgeInsets.zero,
            viewInsets: EdgeInsets.zero,
          ),
          child: Theme(
            data: theme,
            child: RepaintBoundary(
              key: boundaryKey,
              child: ShareCardWidget(result: result),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  try {
    // Two frames: one to build + lay out the entry, one for paint to settle.
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    final renderObject = boundaryKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return null;
    final ui.Image image = await renderObject.toImage(pixelRatio: 1);
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  } catch (_) {
    return null;
  } finally {
    entry
      ..remove()
      ..dispose();
  }
}
