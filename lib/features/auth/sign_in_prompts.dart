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
