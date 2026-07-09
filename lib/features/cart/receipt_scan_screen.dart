import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:munch_or_dump/core/api/api_exception.dart';
import 'package:munch_or_dump/core/models/cart.dart';
import 'package:munch_or_dump/core/models/receipt.dart';
import 'package:munch_or_dump/core/providers.dart';
import 'package:munch_or_dump/core/router/routes.dart';
import 'package:munch_or_dump/core/theme/palette.dart';
import 'package:munch_or_dump/core/theme/verdict_palette.dart';
import 'package:munch_or_dump/core/upload_helper.dart';
import 'package:munch_or_dump/core/widgets/async_states.dart';
import 'package:munch_or_dump/core/widgets/editorial.dart';
import 'package:munch_or_dump/core/widgets/forms.dart';
import 'package:munch_or_dump/features/auth/auth_controller.dart';
import 'package:munch_or_dump/features/auth/sign_in_prompts.dart';
import 'package:munch_or_dump/features/cart/cart_controller.dart';
import 'package:munch_or_dump/features/cart/cart_widgets.dart';
import 'package:munch_or_dump/features/scan/scan_quota_modal.dart';

enum _Phase { idle, working, review, error }

/// The server caps a typed pre-shop list at 30 items.
const int _maxTypedItems = 30;

/// The receipt-scan sub-flow that feeds the cart: snap/upload a receipt photo
/// (or type a shopping list), poll the analysis job, review the resolved
/// items, then merge them into the persistent cart and land on `/cart`.
///
/// Receipt analysis requires auth (the API 401s anonymous `POST /api/receipt`)
/// — both entry points gate through the sign-in sheet before any round-trip.
class ReceiptScanScreen extends ConsumerStatefulWidget {
  const ReceiptScanScreen({super.key});

  @override
  ConsumerState<ReceiptScanScreen> createState() => _ReceiptScanScreenState();
}

class _ReceiptScanScreenState extends ConsumerState<ReceiptScanScreen> {
  final TextEditingController _typedList = TextEditingController();
  _Phase _phase = _Phase.idle;
  String? _message;
  ReceiptJob? _job;
  // 'receipt' for an image job, 'typed' for a pre-shop list — stamped on the
  // CartItems so the cart knows where each item came from.
  String _source = 'receipt';

  bool get _loggedIn => ref.read(authControllerProvider).valueOrNull != null;

  @override
  void dispose() {
    _typedList.dispose();
    super.dispose();
  }

  Future<void> _startFromImage() async {
    if (!_loggedIn) {
      await showSignInToScanSheet(context);
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              NavRow(
                icon: Icons.photo_camera_outlined,
                label: 'Take photo',
                trailing: const SizedBox.shrink(),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              Divider(height: 1, color: context.palette.hairlineFaint),
              NavRow(
                icon: Icons.photo_library_outlined,
                label: 'Choose from library',
                trailing: const SizedBox.shrink(),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;
    final XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2200,
        imageQuality: 85,
      );
    } on Object catch (_) {
      return; // camera/library denied — stay on idle
    }
    if (file == null || !mounted) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _phase = _Phase.working;
      _message = null;
      _job = null;
      _source = 'receipt';
    });
    try {
      final api = ref.read(munchApiProvider);
      final fileUrl = await uploadImageFile(api, file);
      final start = await api.startReceiptFromImage(fileUrl);
      await _poll(start.jobId);
    } on ApiException catch (e) {
      _fail(e.message);
    }
  }

  Future<void> _startFromTypedList() async {
    if (!_loggedIn) {
      await showSignInToScanSheet(context);
      return;
    }
    final names = _typedNames;
    if (names.isEmpty) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _phase = _Phase.working;
      _message = null;
      _job = null;
      _source = 'typed';
    });
    try {
      final start = await ref
          .read(munchApiProvider)
          .startReceiptFromItems(names);
      await _poll(start.jobId);
    } on ApiException catch (e) {
      _fail(e.message);
    }
  }

  List<String> get _typedNames => _typedList.text
      .split(RegExp(r'[\n,]'))
      .map((String s) => s.trim())
      .where((String s) => s.isNotEmpty)
      .take(_maxTypedItems)
      .toList();

  Future<void> _poll(String jobId) async {
    final api = ref.read(munchApiProvider);
    for (var attempt = 0; attempt < 45 && mounted; attempt++) {
      final ReceiptJob job;
      try {
        job = await api.pollReceipt(jobId);
      } on ApiException catch (e) {
        _fail(e.message);
        return;
      }
      if (!mounted) return;
      if (!job.isProcessing) {
        if (job.isError) {
          _fail('We couldn’t read that receipt.');
        } else {
          setState(() {
            _job = job;
            _phase = _Phase.review;
          });
        }
        return;
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    if (mounted) _fail('This is taking longer than expected — try again.');
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _phase = _Phase.error;
      _message = message;
    });
  }

  void _addToCart(ReceiptJob job) {
    unawaited(HapticFeedback.mediumImpact());
    ref
        .read(cartControllerProvider.notifier)
        .addAll(
          job.items.map(
            (ReceiptItem i) => CartItem.fromReceiptItem(i, source: _source),
          ),
        );
    if (_source == 'typed') _typedList.clear();
    context.pushReplacementNamed(Routes.cart);
  }

  void _reset() => setState(() {
    _phase = _Phase.idle;
    _message = null;
    _job = null;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: GridBackground(
        child: SafeArea(
          top: false,
          child: switch (_phase) {
            _Phase.working => const AnalysisLoader(),
            _Phase.error => ErrorRetry(
              message: _message ?? 'Something went wrong.',
              onRetry: _reset,
            ),
            _Phase.review => _Review(
              job: _job!,
              onAdd: () => _addToCart(_job!),
              onDiscard: _reset,
            ),
            _Phase.idle => _Idle(
              typedList: _typedList,
              onScan: _startFromImage,
              onAnalyzeTyped: _startFromTypedList,
            ),
          },
        ),
      ),
    );
  }
}

class _Idle extends ConsumerWidget {
  const _Idle({
    required this.typedList,
    required this.onScan,
    required this.onAnalyzeTyped,
  });

  final TextEditingController typedList;
  final VoidCallback onScan;
  final VoidCallback onAnalyzeTyped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final loggedIn = ref.watch(authControllerProvider).valueOrNull != null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 40),
      children: <Widget>[
        const Eyebrow('Cart Intelligence', spacing: 3.6),
        const SizedBox(height: 12),
        const TwoToneHeadline(
          dark: 'Verdict everything',
          muted: 'you bought.',
          size: 30,
          align: TextAlign.left,
        ),
        const SizedBox(height: 12),
        Text(
          'Snap a grocery receipt and every line item gets scored — then the '
          'whole trip lands in your cart.',
          style: TextStyle(
            fontSize: 15,
            height: 1.55,
            color: palette.inkSecondary,
          ),
        ),
        const SizedBox(height: 24),
        BlackCtaButton(
          label: 'Scan a receipt',
          leadingIcon: Icons.receipt_long_outlined,
          expand: true,
          onTap: onScan,
        ),
        const SizedBox(height: 28),
        const SectionLabel('Or type your list'),
        const SizedBox(height: 16),
        TextField(
          controller: typedList,
          minLines: 3,
          maxLines: 6,
          textInputAction: TextInputAction.newline,
          decoration: const InputDecoration(
            hintText:
                'greek yogurt, cold brew, tortilla chips…\n'
                'One item per line or comma-separated.',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: typedList,
          builder: (context, value, _) {
            final count = value.text
                .split(RegExp(r'[\n,]'))
                .where((String s) => s.trim().isNotEmpty)
                .length;
            // Only the first [_maxTypedItems] are sent — say so instead of
            // advertising a count the server will never see.
            return OutlinedButton.icon(
              onPressed: count == 0 ? null : onAnalyzeTyped,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: Text(
                count == 0
                    ? 'Analyze your list'
                    : count > _maxTypedItems
                    ? 'Analyze first $_maxTypedItems of $count items'
                    : 'Analyze $count item${count == 1 ? '' : 's'}',
              ),
            );
          },
        ),
        if (!loggedIn) ...<Widget>[
          const SizedBox(height: 20),
          const Center(
            child: SignInInline(
              action: 'Sign in',
              rest: ' to analyze receipts and lists.',
            ),
          ),
        ],
      ],
    );
  }
}

/// The items-review step between the job finishing and the cart merge, so the
/// user sees what the OCR resolved before it lands in their cart.
class _Review extends StatelessWidget {
  const _Review({
    required this.job,
    required this.onAdd,
    required this.onDiscard,
  });

  final ReceiptJob job;
  final VoidCallback onAdd;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (job.items.isEmpty) {
      return Column(
        children: <Widget>[
          const Expanded(
            child: EmptyState(
              icon: Icons.receipt_long,
              message: 'No items found on that receipt.',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: BlackCtaButton(
              label: 'Try again',
              expand: true,
              trailingIcon: null,
              onTap: onDiscard,
            ),
          ),
        ],
      );
    }
    final lockedCount = job.items.where((ReceiptItem i) => i.locked).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 40),
      children: <Widget>[
        const Eyebrow('Review your items', spacing: 3.6),
        const SizedBox(height: 12),
        Text(
          '${job.items.length} item${job.items.length == 1 ? '' : 's'} found',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: palette.inkPrimary,
          ),
        ),
        const SizedBox(height: 16),
        CartGroupCard(
          children: <Widget>[
            for (final item in job.items) _ReviewRow(item: item),
          ],
        ),
        if (!job.isPremium && lockedCount > 0) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            'Free receipts analyze the first ${job.freeLimit} — the rest '
            'carry a Premium lock.',
            style: TextStyle(fontSize: 12.5, color: palette.inkFaint),
          ),
        ],
        const SizedBox(height: 24),
        BlackCtaButton(
          label:
              'Add ${job.items.length} item${job.items.length == 1 ? '' : 's'} to cart',
          expand: true,
          onTap: onAdd,
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(onPressed: onDiscard, child: const Text('Discard')),
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.item});

  final ReceiptItem item;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final verdict = item.verdict;
    final name = item.name.isEmpty ? (item.inputName ?? 'Item') : item.name;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: <Widget>[
          if (item.locked)
            Icon(Icons.lock_outline, size: 14, color: palette.inkGhost)
          else
            ConcernDot(
              color: verdict != null
                  ? verdictToneFor(verdict).dot
                  : palette.inkGhost,
              size: 7,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: item.locked ? palette.inkFaint : palette.inkPrimary,
                  ),
                ),
                if ((item.brand ?? '').isNotEmpty)
                  Text(
                    item.brand!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: palette.inkFaint),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (item.locked)
            Text(
              'Premium',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: palette.inkFaint,
              ),
            )
          else if (verdict != null) ...<Widget>[
            WebVerdictBadge(verdict: verdict, size: 10),
            if (item.score != null) ...<Widget>[
              const SizedBox(width: 8),
              Text(
                '${item.score}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: palette.inkFaint,
                ),
              ),
            ],
          ] else
            Text(
              '?',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: palette.inkGhost,
              ),
            ),
        ],
      ),
    );
  }
}
