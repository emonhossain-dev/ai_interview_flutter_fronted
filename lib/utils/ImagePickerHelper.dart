import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  static Future<File?> pickFromGallery({int quality = 80}) async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: quality,
    );

    if (file == null) return null;
    return File(file.path);
  }

  /// Pick image from camera
  static Future<File?> pickFromCamera({int quality = 80}) async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: quality,
    );

    if (file == null) return null;
    return File(file.path);
  }






}