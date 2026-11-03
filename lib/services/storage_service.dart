import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Uploads and deletes report photos in Firebase Storage.
class StorageService {
  StorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Uploads [file] to report_photos/{uid}/ and returns its download URL.
  Future<String> uploadReportPhoto({
    required File file,
    required String uid,
  }) async {
    final isPng = file.path.toLowerCase().endsWith('.png');
    final extension = isPng ? 'png' : 'jpg';
    final contentType = isPng ? 'image/png' : 'image/jpeg';

    final name = '${DateTime.now().millisecondsSinceEpoch}.$extension';
    final ref = _storage.ref('report_photos/$uid/$name');

    await ref.putFile(file, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }

  /// Best-effort delete, used to clean up if saving the report fails.
  Future<void> deleteByUrl(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {
      // Ignore: cleanup should never crash the app.
    }
  }
}
