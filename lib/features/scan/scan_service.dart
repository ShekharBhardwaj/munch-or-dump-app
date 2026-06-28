import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:munch_or_dump/core/api/munch_api.dart';
import 'package:munch_or_dump/core/models/analysis_result.dart';
import 'package:munch_or_dump/core/providers.dart';

/// Orchestrates the two scan paths into a single [AnalyzeOutcome]:
///  * barcode → `/api/analyze` (anonymous-friendly fast path)
///  * label photos → presigned S3 upload → `/api/scans` → `/api/analyze` (auth)
class ScanService {
  const ScanService(this._api);

  final MunchApi _api;

  Future<AnalyzeOutcome> analyzeBarcode(String barcode) =>
      _api.analyze(barcode: barcode);

  Future<AnalyzeOutcome> analyzePhotos(List<XFile> files) async {
    final fileUrls = <String>[];
    for (final file in files) {
      final bytes = await file.readAsBytes();
      final contentType = _contentTypeFor(file.name);
      final target = await _api.createUploadUrl(
        filename: file.name,
        contentType: contentType,
      );
      await _api.uploadImage(
        uploadUrl: target.uploadUrl,
        bytes: bytes,
        contentType: contentType,
      );
      fileUrls.add(target.fileUrl);
    }

    final draft = await _api.createScan(fileUrls: fileUrls);
    return _api.analyze(
      ingredients: draft.ingredients,
      scanId: draft.scanId,
      barcode: draft.barcode,
      servingSize: draft.servingSize,
      fileUrls: fileUrls,
    );
  }

  String _contentTypeFor(String filename) {
    final ext = filename.contains('.')
        ? filename.split('.').last.toLowerCase()
        : 'jpg';
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      _ => 'image/jpeg',
    };
  }
}

final scanServiceProvider = Provider<ScanService>(
  (ref) => ScanService(ref.watch(munchApiProvider)),
);
