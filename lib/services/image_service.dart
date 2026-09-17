import 'package:image_picker/image_picker.dart';

class ImageService {
  ImageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;
  Future<XFile?> camera() =>
      _picker.pickImage(source: ImageSource.camera, imageQuality: 88);
  Future<XFile?> gallery() =>
      _picker.pickImage(source: ImageSource.gallery, imageQuality: 88);
}
