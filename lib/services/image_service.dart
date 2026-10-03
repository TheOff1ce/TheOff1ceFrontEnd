import 'package:image_picker/image_picker.dart';

class ImageService {
  ImageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;
  Future<XFile?> camera() => _pick(ImageSource.camera);
  Future<XFile?> gallery() => _pick(ImageSource.gallery);

  Future<XFile?> _pick(ImageSource source) async {
    try {
      return await _picker.pickImage(source: source, imageQuality: 88);
    } catch (_) {
      throw const ImagePickFailure();
    }
  }
}

class ImagePickFailure implements Exception {
  const ImagePickFailure();
}
