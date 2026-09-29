import 'package:image_picker/image_picker.dart';

/// Thin platform boundary for choosing images.
///
/// Keeping the plugin behind this service stops pages from constructing
/// platform dependencies and lets tests inject a controlled implementation.
class ImagePickerService {
  ImagePickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<XFile?> pickFromGallery() {
    return _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 90,
    );
  }
}
