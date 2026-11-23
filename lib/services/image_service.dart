import 'package:image_picker/image_picker.dart';

import '../errors/app_error.dart';
import '../errors/error_messages.dart';

/// Picks prescription photos already reduced for upload (FE-018).
class ImageService {
  ImageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  static const maxDimension = 2048.0;
  static const quality = 85;

  /// Foto de la prueba de entrega: más pequeña, para no pasar de los 3 MB que acepta el servicio.
  static const proofMaxDimension = 1600.0;
  static const proofQuality = 80;

  final ImagePicker _picker;

  Future<XFile?> camera() => _pick(ImageSource.camera);
  Future<XFile?> gallery() => _pick(ImageSource.gallery);

  /// Foto de la entrega con la cámara (CU-14), siempre con la trasera.
  Future<XFile?> deliveryPhoto() =>
      _pick(ImageSource.camera, maxSide: proofMaxDimension, jpegQuality: proofQuality);

  Future<XFile?> _pick(ImageSource source, {double maxSide = maxDimension, int jpegQuality = quality}) async {
    try {
      return await _picker.pickImage(
        source: source,
        maxWidth: maxSide,
        maxHeight: maxSide,
        imageQuality: jpegQuality,
        preferredCameraDevice: CameraDevice.rear,
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
