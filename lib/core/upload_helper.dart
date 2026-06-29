import 'package:image_picker/image_picker.dart';
import 'package:munch_or_dump/core/api/munch_api.dart';

/// Content-type for an image filename, restricted to what the upload endpoint
/// accepts.
String contentTypeForName(String filename) {
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

/// Upload an [XFile] via the presigned-S3 flow and return its `file_url`.
Future<String> uploadImageFile(MunchApi api, XFile file) async {
  final bytes = await file.readAsBytes();
  final contentType = contentTypeForName(file.name);
  final target = await api.createUploadUrl(
    filename: file.name,
    contentType: contentType,
  );
  await api.uploadImage(
    uploadUrl: target.uploadUrl,
    bytes: bytes,
    contentType: contentType,
  );
  return target.fileUrl;
}
