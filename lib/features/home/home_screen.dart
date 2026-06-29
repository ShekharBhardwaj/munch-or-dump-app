import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/router/routes.dart';
import 'package:munch_or_dump/core/theme/app_colors.dart';
import 'package:munch_or_dump/features/auth/auth_controller.dart';

/// Landing screen — a calm, focused home: a confident intro, the Scan action as
/// the hero, a quiet search, and a tidy "discover" grid.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final loggedIn = ref.watch(authControllerProvider).valueOrNull != null;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: <Widget>[
            Row(
              children: <Widget>[
                Text('Munch or Dump', style: theme.textTheme.titleLarge),
                const Spacer(),
                _AvatarButton(loggedIn: loggedIn),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'Know what\nyou’re eating.',
              style: theme.textTheme.displaySmall,
            ),
            const SizedBox(height: 10),
            Text(
              'Scan any product for an honest, personalized verdict.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.inkSecondary,
              ),
            ),
            const SizedBox(height: 24),
            _ScanHero(onTap: () => context.pushNamed(Routes.scan)),
            const SizedBox(height: 12),
            _SearchField(onTap: () => context.pushNamed(Routes.search)),
            const SizedBox(height: 32),
            Text('Discover', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.9,
              children: <Widget>[
                _DiscoverTile(
                  icon: Icons.category_outlined,
                  label: 'Categories',
                  onTap: () => context.pushNamed(Routes.categories),
                ),
                _DiscoverTile(
                  icon: Icons.storefront_outlined,
                  label: 'Brands',
                  onTap: () => context.pushNamed(Routes.brands),
                ),
                _DiscoverTile(
                  icon: Icons.compare_arrows,
                  label: 'Compare',
                  onTap: () => context.pushNamed(Routes.compare),
                ),
                _DiscoverTile(
                  icon: Icons.article_outlined,
                  label: 'News',
                  onTap: () => context.pushNamed(Routes.news),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _GameCard(onTap: () => context.pushNamed(Routes.game)),
          ],
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

class _ScanHero extends StatelessWidget {
  const _ScanHero({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SoftCard(
      onTap: onTap,
      color: AppColors.brand,
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.qr_code_scanner,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Scan a product',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Barcode, label, or receipt',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward, color: Colors.white.withValues(alpha: 0.9)),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        child: Row(
          children: <Widget>[
            const Icon(Icons.search, color: AppColors.inkMuted, size: 22),
            const SizedBox(width: 12),
            Text(
              'Search products or brands',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoverTile extends StatelessWidget {
  const _DiscoverTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 20, color: AppColors.inkPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SoftCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.videogame_asset_outlined,
            color: AppColors.inkPrimary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Play the game', style: theme.textTheme.titleMedium),
                Text(
                  'Guess the ingredients, beat the streak',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.inkMuted),
        ],
      ),
    );
  }
}

/// A white card with a hairline border and a very soft shadow — the redesign's
/// core surface. [color] fills it (e.g. the emerald scan hero).
class _SoftCard extends StatelessWidget {
  const _SoftCard({
    required this.child,
    required this.onTap,
    this.color = AppColors.surface,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final VoidCallback onTap;
  final Color color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final tinted = color != AppColors.surface;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: padding,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            border: tinted ? null : Border.all(color: AppColors.hairline),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: (tinted ? AppColors.brand : Colors.black).withValues(
                  alpha: tinted ? 0.18 : 0.04,
                ),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
