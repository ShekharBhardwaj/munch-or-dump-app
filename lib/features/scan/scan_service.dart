import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:munch_or_dump/core/api/munch_api.dart';
import 'package:munch_or_dump/core/models/analysis_result.dart';
import 'package:munch_or_dump/core/providers.dart';
import 'package:munch_or_dump/core/upload_helper.dart';

/// Orchestrates the two scan paths into a single [AnalyzeOutcome]. Both require
/// auth — the API returns 401 for anonymous scan/analyze (the app gates before
/// calling):
///  * barcode → `/api/analyze`
///  * label photos → presigned S3 upload → `/api/scans` → `/api/analyze`
class ScanService {
  const ScanService(this._api);

  final MunchApi _api;

  Future<AnalyzeOutcome> analyzeBarcode(String barcode) =>
      _api.analyze(barcode: barcode);

  Future<AnalyzeOutcome> analyzePhotos(List<XFile> files) async {
    final fileUrls = <String>[
      for (final file in files) await uploadImageFile(_api, file),
    ];
    final draft = await _api.createScan(fileUrls: fileUrls);
    return _api.analyze(
      ingredients: draft.ingredients,
      scanId: draft.scanId,
      barcode: draft.barcode,
      servingSize: draft.servingSize,
      productName: draft.productName,
      brand: draft.brand,
      fileUrls: fileUrls,
    );
  }
}

final scanServiceProvider = Provider<ScanService>(
  (ref) => ScanService(ref.watch(munchApiProvider)),
);
