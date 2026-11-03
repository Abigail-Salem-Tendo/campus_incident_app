import 'dart:io';

import 'package:image_picker/image_picker.dart';

/// Thrown when a photo is still too big after compression.
class PhotoTooLargeException implements Exception {
  final String message;
  const PhotoTooLargeException(this.message);

  @override
  String toString() => message;
}

/// Picks a photo from the camera or gallery and shrinks it on the phone
/// before it is ever uploaded.
class PhotoService {
  PhotoService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Hard cap on the final file size (1 MB).
  static const int maxBytes = 1024 * 1024;

  /// Longest allowed side in pixels. Plenty for a report photo.
  static const double maxDimension = 1280;

  /// JPEG quality, 0-100.
  static const int quality = 75;

  /// Returns the picked photo, or null if the user cancelled.
  /// Throws [PhotoTooLargeException] if it is still over [maxBytes].
  Future<File?> pickPhoto(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: maxDimension,
      maxHeight: maxDimension,
      imageQuality: quality,
    );

    if (picked == null) return null;

    final file = File(picked.path);
    final size = await file.length();

    if (size > maxBytes) {
      throw const PhotoTooLargeException(
        'That photo is too large. Please choose a smaller one.',
      );
    }

    return file;
  }
}
