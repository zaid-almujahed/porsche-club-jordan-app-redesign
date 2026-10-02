import 'package:image_picker/image_picker.dart';

/// Where a photo comes from.
enum PhotoSource { camera, library }

/// Thin platform boundary for choosing images.
///
/// Keeping the plugin behind this service stops pages from constructing
/// platform dependencies and lets tests inject a controlled implementation.
class ImagePickerService {
  ImagePickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<XFile?> pick(PhotoSource source) =>
      source == PhotoSource.camera ? pickFromCamera() : pickFromGallery();

  Future<XFile?> pickFromGallery() {
    return _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 90,
    );
  }

  Future<XFile?> pickFromCamera() {
    return _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 90,
    );
  }
}
