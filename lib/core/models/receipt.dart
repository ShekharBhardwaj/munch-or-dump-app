import 'package:munch_or_dump/core/models/verdict.dart';

/// Returned by `POST /api/receipt` — the job is queued and polled by id.
class ReceiptStart {
  const ReceiptStart({
    required this.jobId,
    this.isPremium = false,
    this.freeLimit = 3,
  });

  factory ReceiptStart.fromJson(Map<String, dynamic> json) => ReceiptStart(
    jobId: json['job_id']?.toString() ?? '',
    isPremium: json['is_premium'] == true,
    freeLimit: (json['free_limit'] as num?)?.toInt() ?? 3,
  );

  final String jobId;
  final bool isPremium;
  final int freeLimit;
}

/// One line item in a receipt analysis.
class ReceiptItem {
  const ReceiptItem({
    required this.name,
    this.inputName,
    this.brand,
    this.verdict,
    this.score,
    this.shortExplanation,
    this.productSlug,
    this.source,
    this.locked = false,
  });

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] as String?)?.trim();
    return ReceiptItem(
      name: name != null && name.isNotEmpty
          ? name
          : (json['input_name'] as String?)?.trim() ?? '',
      inputName: json['input_name'] as String?,
      brand: json['brand'] as String?,
      verdict: Verdict.tryParse(json['verdict'] as String?),
      score: (json['score'] as num?)?.toInt(),
      shortExplanation: json['short_explanation'] as String?,
      productSlug: json['product_slug'] as String?,
      source: json['source'] as String?,
      locked: json['locked'] == true,
    );
  }

  final String name;
  final String? inputName;
  final String? brand;
  final Verdict? verdict;
  final int? score;
  final String? shortExplanation;
  final String? productSlug;
  final String? source;
  final bool locked;
}

/// `GET /api/receipt/:jobId` — the poll result.
class ReceiptJob {
  const ReceiptJob({
    required this.status,
    this.items = const <ReceiptItem>[],
    this.isPremium = false,
    this.freeLimit = 3,
  });

  factory ReceiptJob.fromJson(Map<String, dynamic> json) => ReceiptJob(
    status: json['status']?.toString() ?? 'processing',
    items:
        (json['items'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(ReceiptItem.fromJson)
            .toList() ??
        const <ReceiptItem>[],
    isPremium: json['is_premium'] == true,
    freeLimit: (json['free_limit'] as num?)?.toInt() ?? 3,
  );

  final String status;
  final List<ReceiptItem> items;
  final bool isPremium;
  final int freeLimit;

  bool get isProcessing => status == 'processing';
  bool get isDone => status == 'done';
  bool get isError => status == 'error';
}
