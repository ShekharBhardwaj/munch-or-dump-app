import 'package:flutter/material.dart';
import 'package:munch_or_dump/core/api/api_exception.dart';
import 'package:munch_or_dump/core/theme/palette.dart';

/// User-facing text for a provider/async error — unwraps [ApiException] so the
/// UI never shows a raw "ApiException(404): ..." string.
String errorMessage(Object error) =>
    error is ApiException ? error.message : 'Something went wrong.';

/// Centered empty-state placeholder for an empty list.
class EmptyState extends StatelessWidget {
  const EmptyState({required this.icon, required this.message, super.key});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shimmer skeletons ────────────────────────────────────────────────────────

/// Slides the shimmer highlight across the gradient's bounds: progress 0→1
/// maps to a sweep from just off the left edge to just off the right.
class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.progress);

  final double progress;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (progress * 3 - 1.5), 0, 0);
}

/// Sweeps a soft highlight across the grey [ShimmerBox]es beneath it.
///
/// One [AnimationController] drives the whole subtree, so every box in a
/// skeleton pulses in sync (~1100ms loop). When the platform requests reduced
/// motion ([MediaQuery.disableAnimationsOf]), the sweep is skipped and the
/// boxes render as static grey.
class Shimmer extends StatefulWidget {
  const Shimmer({required this.child, super.key});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    final palette = context.palette;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          begin: const Alignment(-1, -0.2),
          end: const Alignment(1, 0.2),
          colors: <Color>[
            palette.hairline,
            palette.surfaceAlt,
            palette.hairline,
          ],
          stops: const <double>[0.35, 0.5, 0.65],
          transform: _SlidingGradientTransform(_controller.value),
        ).createShader(bounds),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// A rounded grey placeholder block (stone-200). Static on its own — place it
/// under a [Shimmer] to pick up the animated sweep.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({this.width, this.height = 12, this.radius = 6, super.key});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.palette.hairline,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Text-bar width fractions, varied per row so the skeleton reads as organic
/// content rather than a repeated tile.
const List<double> _primaryBarWidths = <double>[
  0.72,
  0.54,
  0.66,
  0.48,
  0.7,
  0.58,
  0.76,
  0.5,
];
const List<double> _secondaryBarWidths = <double>[
  0.38,
  0.28,
  0.44,
  0.24,
  0.34,
  0.46,
  0.3,
  0.4,
];

/// Shimmering placeholder rows that hold a list screen's layout while it
/// loads — an optional leading block, two text bars of different widths, and a
/// trailing pill, echoing the [ProductRow] / browse-hub-row silhouette.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    this.rows = 8,
    this.padding = EdgeInsets.zero,
    this.rowHeight = 64,
    this.showLeading = true,
    super.key,
  });

  /// Number of placeholder rows.
  final int rows;

  /// Outer list padding.
  final EdgeInsets padding;

  /// Height of each placeholder row (hairline dividers excluded).
  final double rowHeight;

  /// Whether rows show the leading badge/avatar block. Off for rows that are
  /// just text + a trailing pill (product / browse-hub rows).
  final bool showLeading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: ExcludeSemantics(
        child: Shimmer(
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            padding: padding,
            itemCount: rows,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) => _SkeletonRow(
              index: i,
              height: rowHeight,
              showLeading: showLeading,
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({
    required this.index,
    required this.height,
    required this.showLeading,
  });

  final int index;
  final double height;
  final bool showLeading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: <Widget>[
            if (showLeading) ...<Widget>[
              const ShimmerBox(width: 36, height: 36, radius: 12),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor:
                        _primaryBarWidths[index % _primaryBarWidths.length],
                    child: const ShimmerBox(height: 14, radius: 7),
                  ),
                  const SizedBox(height: 8),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor:
                        _secondaryBarWidths[index % _secondaryBarWidths.length],
                    child: const ShimmerBox(height: 11, radius: 6),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const ShimmerBox(width: 64, height: 24, radius: 999),
          ],
        ),
      ),
    );
  }
}

/// Centered error message with a retry button — for failed async loads.
class ErrorRetry extends StatelessWidget {
  const ErrorRetry({required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
