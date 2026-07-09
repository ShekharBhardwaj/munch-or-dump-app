import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/router/routes.dart';
import 'package:munch_or_dump/core/theme/palette.dart';
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
    final palette = context.palette;
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
                color: palette.surfaceAlt,
                shape: BoxShape.circle,
                border: Border.all(color: palette.hairline),
              ),
              child: Icon(
                Icons.lock_outline,
                size: 24,
                color: palette.inkSecondary,
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
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: palette.inkPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: palette.inkSecondary,
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
    final palette = context.palette;
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
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: palette.brand,
                ),
              ),
              TextSpan(text: rest),
            ],
          ),
          textAlign: align,
          style: TextStyle(fontSize: 13, color: palette.inkSecondary),
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

  String get _singular {
    if (unit.endsWith('ies')) return '${unit.substring(0, unit.length - 3)}y';
    if (unit.endsWith('s')) return unit.substring(0, unit.length - 1);
    return unit;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final more = (total ?? 0) - shown;
    final headline = more > 0 ? '$more more $unit' : 'See every $_singular';
    // A soft-paywall: the list quietly dissolves into the page, then one
    // confident, on-brand CTA. No card, no glow — restraint reads premium.
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        children: <Widget>[
          ClipRect(
            child: SizedBox(
              height: 84,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  IgnorePointer(
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: const Opacity(
                        opacity: 0.5,
                        child: Column(
                          children: <Widget>[_GhostRow(), _GhostRow()],
                        ),
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[Colors.transparent, palette.canvas],
                        stops: const <double>[0.0, 0.9],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Text(
            headline,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: palette.inkPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            fullLabel == null
                ? 'Free — and we don’t sell your data.'
                : 'Sign in to unlock ${fullLabel!}. It’s free.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: palette.inkFaint),
          ),
          const SizedBox(height: 18),
          BlackCtaButton(
            label: 'Sign in — it’s free',
            trailingIcon: null,
            onTap: () => context.pushNamed(Routes.login),
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
    final palette = context.palette;
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
                    color: palette.hairline,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 11,
                  width: 110,
                  decoration: BoxDecoration(
                    color: palette.hairlineFaint,
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
              color: palette.surfaceAlt,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}
