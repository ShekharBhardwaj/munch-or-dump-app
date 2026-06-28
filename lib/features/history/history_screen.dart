import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munch_or_dump/core/api/api_exception.dart';
import 'package:munch_or_dump/core/models/user_content.dart';
import 'package:munch_or_dump/core/providers.dart';
import 'package:munch_or_dump/core/widgets/async_states.dart';
import 'package:munch_or_dump/core/widgets/verdict_badge.dart';

/// The signed-in user's scan history (`GET /api/scans`).
final scanHistoryProvider = FutureProvider.autoDispose<List<ScanHistoryItem>>((
  ref,
) {
  return ref.watch(munchApiProvider).listScans();
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(scanHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorRetry(
          message: '$error',
          onRetry: () => ref.invalidate(scanHistoryProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.history,
              message: 'No scans yet — scan a product to start your history.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              try {
                // Awaited for the side effect; refresh (not invalidate) keeps
                // the list visible during the reload.
                // ignore: unused_result
                await ref.refresh(scanHistoryProvider.future);
              } on ApiException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.message)));
                }
              }
            },
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) => _HistoryRow(item: items[i]),
            ),
          );
        },
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item});

  final ScanHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final verdict = item.verdict;
    return ListTile(
      title: Text(
        item.productName.isEmpty ? 'Scanned product' : item.productName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(_shortDate(item.createdDate)),
      trailing: verdict != null
          ? VerdictBadge(verdict: verdict, score: item.verdictScore)
          : const Text('—'),
    );
  }
}

String _shortDate(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return '';
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}
