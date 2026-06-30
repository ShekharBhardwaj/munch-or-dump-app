import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/models/catalog.dart';
import 'package:munch_or_dump/core/providers.dart';
import 'package:munch_or_dump/core/router/routes.dart';
import 'package:munch_or_dump/core/theme/app_colors.dart';
import 'package:munch_or_dump/core/theme/verdict_palette.dart';
import 'package:munch_or_dump/core/widgets/editorial.dart';
import 'package:munch_or_dump/features/auth/auth_controller.dart';

/// A handful of recently-analyzed products for the home feed.
final recentProductsProvider =
    FutureProvider.autoDispose<List<ProductListItem>>((ref) async {
      final result = await ref.watch(munchApiProvider).searchProducts(limit: 6);
      return result.items;
    });

/// Landing screen — the website's editorial identity: graph-paper canvas, the
/// "Munch or Dump · BETA" wordmark, a two-tone headline, the black "Analyze a
/// product" CTA, trust taglines, and a live "Recently analyzed" feed.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(authControllerProvider).valueOrNull != null;

    return Scaffold(
      body: GridBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 36),
            children: <Widget>[
              _Navbar(loggedIn: loggedIn),
              const SizedBox(height: 36),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Eyebrow(
                      'Ingredient intelligence',
                      align: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const TwoToneHeadline(
                      dark: 'Know what you’re',
                      muted: 'really eating.',
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Scan what you’re actually putting in your body — not '
                      'what the label wants you to think.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: AppColors.inkSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SearchField(onTap: () => context.pushNamed(Routes.search)),
                    const SizedBox(height: 14),
                    Center(
                      child: BlackCtaButton(
                        label: 'Analyze a product',
                        leadingIcon: Icons.file_upload_outlined,
                        onTap: () => context.pushNamed(Routes.scan),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Photo · Barcode · Search — verdict in seconds',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.inkFaint),
                    ),
                    const SizedBox(height: 28),
                    const _TrustLine(),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: SectionLabel('Recently analyzed'),
              ),
              const SizedBox(height: 16),
              const _RecentFeed(),
              const SizedBox(height: 28),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: SectionLabel('Browse'),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _BrowseRow(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Navbar extends StatelessWidget {
  const _Navbar({required this.loggedIn});

  final bool loggedIn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
      child: Row(
        children: <Widget>[
          const _Wordmark(),
          const SizedBox(width: 8),
          const _BetaBadge(),
          const Spacer(),
          _AvatarButton(loggedIn: loggedIn),
        ],
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    const bold = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      color: AppColors.inkPrimary,
    );
    const light = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w300,
      letterSpacing: -0.4,
      color: AppColors.inkFaint,
    );
    return const Text.rich(
      TextSpan(
        children: <TextSpan>[
          TextSpan(text: 'Munch', style: bold),
          TextSpan(text: ' or ', style: light),
          TextSpan(text: 'Dump', style: bold),
        ],
      ),
    );
  }
}

class _BetaBadge extends StatelessWidget {
  const _BetaBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.inkGhost),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'BETA',
        style: TextStyle(
          fontSize: 9,
          height: 1,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
          color: AppColors.inkFaint,
        ),
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({required this.loggedIn});

  final bool loggedIn;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: loggedIn ? 'Account' : 'Sign in',
      child: InkWell(
        onTap: () => loggedIn
            ? context.goNamed(Routes.account)
            : context.pushNamed(Routes.login),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.hairline),
          ),
          child: Icon(
            loggedIn ? Icons.person : Icons.person_outline,
            size: 20,
            color: AppColors.inkSecondary,
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.hairline),
        ),
        child: const Row(
          children: <Widget>[
            Icon(Icons.search, color: AppColors.inkFaint, size: 20),
            SizedBox(width: 12),
            Text(
              'Search a product or brand…',
              style: TextStyle(fontSize: 14, color: AppColors.inkFaint),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustLine extends StatelessWidget {
  const _TrustLine();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: <Widget>[
        _Trust(bold: 'No brand deals.', rest: ' Ever.'),
        SizedBox(height: 8),
        _Trust(bold: 'Every red flag', rest: ' named by ingredient.'),
        SizedBox(height: 8),
        _Trust(bold: 'DUMP means dump.', rest: ' No softening.'),
      ],
    );
  }
}

class _Trust extends StatelessWidget {
  const _Trust({required this.bold, required this.rest});

  final String bold;
  final String rest;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: <TextSpan>[
          TextSpan(
            text: bold,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.ctaPressed,
            ),
          ),
          TextSpan(
            text: rest,
            style: const TextStyle(fontSize: 12, color: AppColors.inkSecondary),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _RecentFeed extends ConsumerWidget {
  const _RecentFeed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentProductsProvider);
    return recent.when(
      loading: () => const _FeedSkeleton(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          children: <Widget>[
            for (final p in items.take(5))
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _RecentCard(product: p),
              ),
          ],
        );
      },
    );
  }
}

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (var i = 0; i < 2; i++)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Container(
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.hairline),
              ),
            ),
          ),
      ],
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.product});

  final ProductListItem product;

  @override
  Widget build(BuildContext context) {
    final verdict = product.verdict;
    final accent = verdict == null
        ? AppColors.inkGhost
        : verdictToneFor(verdict).bar;
    final category = product.category?.trim() ?? '';
    final brand = product.brandName?.trim() ?? '';
    return AccentTopBorderCard(
      accent: accent,
      padding: const EdgeInsets.all(20),
      onTap: product.slug.isEmpty
          ? null
          : () => context.pushNamed(
              Routes.product,
              pathParameters: <String, String>{'slug': product.slug},
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Eyebrow(
                  category.isEmpty ? 'Product' : category,
                  size: 10,
                  spacing: 3,
                ),
              ),
              if (verdict != null) WebVerdictBadge(verdict: verdict, size: 11),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            product.name.trim().isEmpty ? 'Unknown product' : product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: AppColors.inkPrimary,
            ),
          ),
          if (brand.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              brand,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BrowseRow extends StatelessWidget {
  const _BrowseRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        _BrowseChip(
          icon: Icons.category_outlined,
          label: 'Categories',
          onTap: () => context.pushNamed(Routes.categories),
        ),
        _BrowseChip(
          icon: Icons.storefront_outlined,
          label: 'Brands',
          onTap: () => context.pushNamed(Routes.brands),
        ),
        _BrowseChip(
          icon: Icons.compare_arrows,
          label: 'Compare',
          onTap: () => context.pushNamed(Routes.compare),
        ),
        _BrowseChip(
          icon: Icons.article_outlined,
          label: 'News',
          onTap: () => context.pushNamed(Routes.news),
        ),
        _BrowseChip(
          icon: Icons.videogame_asset_outlined,
          label: 'Game',
          onTap: () => context.pushNamed(Routes.game),
        ),
      ],
    );
  }
}

class _BrowseChip extends StatelessWidget {
  const _BrowseChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 16, color: AppColors.inkSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.inkPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
