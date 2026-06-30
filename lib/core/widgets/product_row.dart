import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/models/catalog.dart';
import 'package:munch_or_dump/core/router/routes.dart';
import 'package:munch_or_dump/core/theme/app_colors.dart';
import 'package:munch_or_dump/core/widgets/editorial.dart';

/// A tappable product list row in the editorial style: name + brand on the left,
/// the web verdict badge on the right. Defaults to opening product detail; pass
/// [onTap] to override (e.g. the compare picker). Reused across search, brand,
/// category, ingredient, watchlist, and history screens.
class ProductRow extends StatelessWidget {
  const ProductRow({required this.item, this.onTap, super.key});

  final ProductListItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final verdict = item.verdict;
    final brand = item.brandName?.trim() ?? '';
    return InkWell(
      onTap:
          onTap ??
          (item.slug.isEmpty
              ? null
              : () => context.pushNamed(
                  Routes.product,
                  pathParameters: <String, String>{'slug': item.slug},
                )),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.name.isEmpty ? item.slug : item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkPrimary,
                    ),
                  ),
                  if (brand.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.inkFaint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (verdict != null) ...<Widget>[
              const SizedBox(width: 12),
              WebVerdictBadge(verdict: verdict, size: 11),
            ],
          ],
        ),
      ),
    );
  }
}

/// A tappable hub row for the categories / brands lists: a name + a sub line,
/// an optional average score, and a chevron.
class BrowseHubRow extends StatelessWidget {
  const BrowseHubRow({
    required this.label,
    required this.sub,
    required this.onTap,
    this.avgScore,
    super.key,
  });

  final String label;
  final String sub;
  final VoidCallback onTap;
  final int? avgScore;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.inkFaint,
                    ),
                  ),
                ],
              ),
            ),
            if (avgScore != null)
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Text(
                  'AVG $avgScore',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.inkSecondary,
                  ),
                ),
              ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.inkGhost,
            ),
          ],
        ),
      ),
    );
  }
}
