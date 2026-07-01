import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/router/routes.dart';
import 'package:munch_or_dump/core/theme/app_colors.dart';
import 'package:munch_or_dump/core/widgets/editorial.dart';

/// Full-screen sign-in wall for a gated feature (history, watchlist). Matches
/// the website, which shows an in-place wall rather than redirecting away.
class SignInWall extends StatelessWidget {
  const SignInWall({
    required this.heading,
    required this.body,
    this.subheading,
    this.buttonLabel = 'Create free account',
    super.key,
  });

  final String heading;
  final String body;
  final String? subheading;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.hairline),
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 24,
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: 20),
            if (subheading != null) ...<Widget>[
              Eyebrow(subheading!, align: TextAlign.center),
              const SizedBox(height: 8),
            ],
            Text(
              heading,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: AppColors.inkPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: 24),
            BlackCtaButton(
              label: buttonLabel,
              trailingIcon: null,
              onTap: () => context.pushNamed(Routes.login),
            ),
          ],
        ),
      ),
    );
  }
}

/// An inline "{action} {rest}" prompt — the whole line taps through to sign-in,
/// with the action word in the brand color (e.g. on Scan / Receipt).
class SignInInline extends StatelessWidget {
  const SignInInline({
    required this.action,
    required this.rest,
    this.align = TextAlign.center,
    super.key,
  });

  final String action;
  final String rest;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.pushNamed(Routes.login),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Text.rich(
          TextSpan(
            children: <TextSpan>[
              TextSpan(
                text: action,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.brand,
                ),
              ),
              TextSpan(text: rest),
            ],
          ),
          textAlign: align,
          style: const TextStyle(fontSize: 13, color: AppColors.inkSecondary),
        ),
      ),
    );
  }
}

/// Anonymous browse-teaser gate: a blurred peek of a few ghost rows fading into
/// the page, then a dark card inviting sign-in to see the full list. Rendered
/// after the (server-truncated) teaser items when a browse endpoint returns
/// `gated: true`. Matches the web SignInGate.
class SignInGate extends StatelessWidget {
  const SignInGate({
    required this.shown,
    this.total,
    this.unit = 'results',
    this.fullLabel,
    super.key,
  });

  final int shown;
  final int? total;
  final String unit;
  final String? fullLabel;

  static const Color _amber = Color(0xFFFBBF24);

  String get _singular {
    if (unit.endsWith('ies')) return '${unit.substring(0, unit.length - 3)}y';
    if (unit.endsWith('s')) return unit.substring(0, unit.length - 1);
    return unit;
  }

  @override
  Widget build(BuildContext context) {
    final more = (total ?? 0) - shown;
    final hasMore = more > 0;
    final headline = hasMore ? '$more more $unit' : 'See every $_singular';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        children: <Widget>[
          IgnorePointer(
            child: Stack(
              children: <Widget>[
                ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Opacity(
                    opacity: 0.6,
                    child: Column(
                      children: <Widget>[
                        for (var i = 0; i < 3; i++) const _GhostRow(),
                      ],
                    ),
                  ),
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[Colors.transparent, AppColors.canvas],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
            child: Column(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0x1FFBBF24),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0x4DFBBF24)),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: _amber,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  headline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFDE68A),
                  ),
                ),
                if (hasMore) ...<Widget>[
                  const SizedBox(height: 2),
                  const Text(
                    'a free account away',
                    style: TextStyle(fontSize: 12, color: Color(0xCCFDE68A)),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Unlock ${fullLabel ?? 'the full list'}. It’s free — and we '
                  'don’t sell your data.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xB3FDE68A),
                  ),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () => context.pushNamed(Routes.login),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
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
                    child: const Text(
                      'Sign in — it’s free',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A greyed placeholder row for the blurred teaser peek behind [SignInGate].
class _GhostRow extends StatelessWidget {
  const _GhostRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: 13,
                  width: 180,
                  decoration: BoxDecoration(
                    color: AppColors.hairline,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 11,
                  width: 110,
                  decoration: BoxDecoration(
                    color: AppColors.hairlineFaint,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 22,
            width: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}
