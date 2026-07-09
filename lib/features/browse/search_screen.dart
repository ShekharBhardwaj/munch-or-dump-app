import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munch_or_dump/core/api/api_exception.dart';
import 'package:munch_or_dump/core/models/catalog.dart';
import 'package:munch_or_dump/core/models/verdict.dart';
import 'package:munch_or_dump/core/providers.dart';
import 'package:munch_or_dump/core/widgets/async_states.dart';
import 'package:munch_or_dump/core/widgets/product_row.dart';
import 'package:munch_or_dump/features/auth/sign_in_prompts.dart';

const List<({String key, String label})> _dietaryFilters =
    <({String key, String label})>[
      (key: 'vegan', label: 'Vegan'),
      (key: 'vegetarian', label: 'Vegetarian'),
      (key: 'gluten_free', label: 'Gluten-free'),
      (key: 'dairy_free', label: 'Dairy-free'),
      (key: 'no_nuts', label: 'Nut-free'),
      (key: 'no_soy', label: 'Soy-free'),
      (key: 'no_eggs', label: 'Egg-free'),
    ];

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({this.onPick, super.key});

  /// When set, tapping a result calls this instead of opening product detail —
  /// used by the compare picker.
  final void Function(ProductListItem)? onPick;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Verdict? _verdict;
  final Set<String> _dietary = <String>{};
  bool _busy = false;
  String? _error;
  ProductSearchResult? _result;
  int _searchSeq = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    // Sequence token: rapid filter toggles spawn overlapping requests, and
    // responses can resolve out of order — only apply the latest.
    final seq = ++_searchSeq;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(munchApiProvider)
          .searchProducts(
            search: _controller.text.trim(),
            verdict: _verdict?.apiValue,
            dietary: _dietary.toList(),
          );
      if (!mounted || seq != _searchSeq) return;
      setState(() => _result = result);
    } on ApiException catch (e) {
      if (!mounted || seq != _searchSeq) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted && seq == _searchSeq) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.onPick != null ? 'Pick a product' : 'Search'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Search products or brands',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _busy ? null : _search,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: <Widget>[
                for (final v in Verdict.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(v.label),
                      selected: _verdict == v,
                      onSelected: (s) {
                        setState(() => _verdict = s ? v : null);
                        _search();
                      },
                    ),
                  ),
                for (final f in _dietaryFilters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f.label),
                      selected: _dietary.contains(f.key),
                      onSelected: (s) {
                        setState(() {
                          s ? _dietary.add(f.key) : _dietary.remove(f.key);
                        });
                        _search();
                      },
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildResults(theme)),
        ],
      ),
    );
  }

  Widget _buildResults(ThemeData theme) {
    if (_busy && _result == null) {
      return const SkeletonList(showLeading: false);
    }
    if (_error != null) {
      return ErrorRetry(message: _error!, onRetry: _search);
    }
    final result = _result;
    if (result == null) {
      return const EmptyState(
        icon: Icons.search,
        message: 'Search the catalog by product, brand, verdict, or diet.',
      );
    }
    if (result.items.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off,
        message: 'No matches — try a different term or fewer filters.',
      );
    }
    final showGated = result.gated && result.total > result.items.length;
    return ListView.separated(
      itemCount: result.items.length + (showGated ? 1 : 0),
      separatorBuilder: (_, i) => showGated && i == result.items.length - 1
          ? const SizedBox.shrink()
          : const Divider(height: 1),
      itemBuilder: (context, i) {
        if (showGated && i == result.items.length) {
          return SignInGate(
            shown: result.items.length,
            total: result.total,
            unit: 'products',
            fullLabel: 'every product in the catalog',
          );
        }
        final item = result.items[i];
        return ProductRow(
          item: item,
          onTap: widget.onPick == null ? null : () => widget.onPick!(item),
        );
      },
    );
  }
}
