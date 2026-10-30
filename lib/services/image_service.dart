import 'package:image_picker/image_picker.dart';

import '../errors/app_error.dart';
import '../errors/error_messages.dart';

/// Picks prescription photos already reduced for upload (FE-018).
class ImageService {
  ImageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  static const maxDimension = 2048.0;
  static const quality = 85;

  final ImagePicker _picker;

  Future<XFile?> camera() => _pick(ImageSource.camera);
  Future<XFile?> gallery() => _pick(ImageSource.gallery);

  Future<XFile?> _pick(ImageSource source) async {
    try {
      return await _picker.pickImage(
        source: source,
        maxWidth: maxDimension,
        maxHeight: maxDimension,
        imageQuality: quality,
      );
    } catch (error) {
      throw AppError(
        kind: AppErrorKind.unknown,
        userMessage: ErrorMessages.imagePick,
        retryable: true,
        cause: error,
      );
    }
  }
}
