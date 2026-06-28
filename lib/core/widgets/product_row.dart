import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:munch_or_dump/core/models/catalog.dart';
import 'package:munch_or_dump/core/router/routes.dart';
import 'package:munch_or_dump/core/widgets/verdict_badge.dart';

/// A tappable product list row → product detail. Reused across search, brand,
/// category, and ingredient screens.
class ProductRow extends StatelessWidget {
  const ProductRow({required this.item, super.key});

  final ProductListItem item;

  @override
  Widget build(BuildContext context) {
    final verdict = item.verdict;
    final brand = item.brandName;
    return ListTile(
      title: Text(
        item.name.isEmpty ? item.slug : item.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: brand != null && brand.isNotEmpty
          ? Text(brand, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: verdict != null
          ? VerdictBadge(verdict: verdict, score: item.score)
          : null,
      onTap: item.slug.isEmpty
          ? null
          : () => context.pushNamed(
              Routes.product,
              pathParameters: <String, String>{'slug': item.slug},
            ),
    );
  }
}
