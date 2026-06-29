import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:munch_or_dump/core/api/api_exception.dart';
import 'package:munch_or_dump/core/models/receipt.dart';
import 'package:munch_or_dump/core/providers.dart';
import 'package:munch_or_dump/core/router/routes.dart';
import 'package:munch_or_dump/core/upload_helper.dart';
import 'package:munch_or_dump/core/widgets/async_states.dart';
import 'package:munch_or_dump/core/widgets/verdict_badge.dart';
import 'package:munch_or_dump/features/auth/auth_controller.dart';

enum _Phase { idle, working, done, error }

/// Snap a grocery receipt and get a verdict for each item (async job + poll).
/// Auth-gated; free tier analyzes the first few items.
class ReceiptScreen extends ConsumerStatefulWidget {
  const ReceiptScreen({super.key});

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  _Phase _phase = _Phase.idle;
  String? _message;
  ReceiptJob? _job;

  bool get _loggedIn => ref.read(authControllerProvider).valueOrNull != null;

  Future<void> _start() async {
    if (!_loggedIn) {
      setState(() => _message = 'Sign in to scan receipts.');
      return;
    }
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2200,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() {
      _phase = _Phase.working;
      _message = null;
      _job = null;
    });
    try {
      final api = ref.read(munchApiProvider);
      final fileUrl = await uploadImageFile(api, file);
      final start = await api.startReceiptFromImage(fileUrl);
      await _poll(start.jobId);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _phase = _Phase.error;
          _message = e.message;
        });
      }
    }
  }

  Future<void> _poll(String jobId) async {
    final api = ref.read(munchApiProvider);
    for (var attempt = 0; attempt < 45 && mounted; attempt++) {
      final job = await api.pollReceipt(jobId);
      if (!mounted) return;
      if (!job.isProcessing) {
        setState(() {
          _job = job;
          _phase = job.isError ? _Phase.error : _Phase.done;
          if (job.isError) _message = 'We couldn’t read that receipt.';
        });
        return;
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    if (mounted) {
      setState(() {
        _phase = _Phase.error;
        _message = 'This is taking longer than expected — try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt')),
      body: switch (_phase) {
        _Phase.working => const _Working(),
        _Phase.error => ErrorRetry(
          message: _message ?? 'Something went wrong.',
          // Back to idle so a picker-cancel lands on the clear start screen and
          // the sign-in prompt renders in the idle layout.
          onRetry: () => setState(() {
            _phase = _Phase.idle;
            _message = null;
          }),
        ),
        _Phase.done => _Results(job: _job!),
        _Phase.idle => _Idle(message: _message, onStart: _start),
      },
    );
  }
}

class _Idle extends StatelessWidget {
  const _Idle({required this.onStart, this.message});

  final VoidCallback onStart;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.receipt_long,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Snap a grocery receipt',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get a verdict for everything you bought.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(message!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Choose a receipt photo'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Working extends StatelessWidget {
  const _Working();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Reading your receipt…'),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.job});

  final ReceiptJob job;

  @override
  Widget build(BuildContext context) {
    if (job.items.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long,
        message: 'No items found on that receipt.',
      );
    }
    final unlocked = job.items.where((ReceiptItem i) => !i.locked).length;
    return ListView(
      children: <Widget>[
        for (final item in job.items) _ReceiptRow(item: item),
        if (!job.isPremium && unlocked < job.items.length)
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Upgrade to unlock every item'),
            subtitle: Text('Free scans analyze the first ${job.freeLimit}.'),
          ),
      ],
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.item});

  final ReceiptItem item;

  @override
  Widget build(BuildContext context) {
    final verdict = item.verdict;
    final slug = item.productSlug;
    final tappable = slug != null && slug.isNotEmpty;
    return ListTile(
      title: Text(
        item.name.isEmpty ? (item.inputName ?? 'Item') : item.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: item.brand != null && item.brand!.isNotEmpty
          ? Text(item.brand!, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: item.locked
          ? const Icon(Icons.lock_outline)
          : verdict != null
          ? VerdictBadge(verdict: verdict, score: item.score)
          : const Text('—'),
      onTap: tappable && !item.locked
          ? () => context.pushNamed(
              Routes.product,
              pathParameters: <String, String>{'slug': slug},
            )
          : null,
    );
  }
}
