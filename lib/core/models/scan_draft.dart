/// Result of `POST /api/scans` — the fast OCR ingest. Carries the extracted
/// ingredient names (fed into `/api/analyze`) plus any barcode/serving read off
/// the images.
class ScanDraft {
  const ScanDraft({
    this.scanId,
    this.ingredients = const <String>[],
    this.barcode,
    this.servingSize,
  });

  factory ScanDraft.fromJson(Map<String, dynamic> json) {
    final rawIngredients = json['ingredients'];
    return ScanDraft(
      scanId: (json['scan_id'] ?? json['id'])?.toString(),
      ingredients: rawIngredients is List
          ? rawIngredients.map((dynamic e) => e.toString()).toList()
          : const <String>[],
      barcode: json['barcode'] as String?,
      servingSize: json['serving_size'] as String?,
    );
  }

  final String? scanId;
  final List<String> ingredients;
  final String? barcode;
  final String? servingSize;
}
