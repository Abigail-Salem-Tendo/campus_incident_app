import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

/// Uploads report photos to Cloudinary (free plan, unsigned upload preset).
class StorageService {
  // Replace YOUR_CLOUD_NAME with the cloud name from the Cloudinary dashboard.
  static const String _cloudName = 'zebemzxc';
  static const String _uploadPreset = 'campus_reports';

  /// Uploads [file] and returns its public https URL.
  /// [uid] is kept so callers stay the same; the preset sets the folder.
  Future<String> uploadReportPhoto({
    required File file,
    required String uid,
  }) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    try {
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 200) {
        throw FirebaseException(
          plugin: 'cloudinary',
          code: 'upload-failed',
          message: _errorFrom(response.body),
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final url = data['secure_url'];
      if (url is! String || url.isEmpty) {
        throw FirebaseException(
          plugin: 'cloudinary',
          code: 'upload-failed',
          message: 'No image URL returned.',
        );
      }
      return url;
    } on SocketException {
      throw FirebaseException(
        plugin: 'cloudinary',
        code: 'network-request-failed',
        message: 'No connection.',
      );
    } on http.ClientException {
      throw FirebaseException(
        plugin: 'cloudinary',
        code: 'network-request-failed',
        message: 'No connection.',
      );
    }
  }

  /// Does nothing: deleting from Cloudinary needs the secret API key, which
  /// must never be inside a mobile app. Kept so existing calls still work.
  Future<void> deleteByUrl(String url) async {}

  String _errorFrom(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final error = data['error'];
      if (error is Map<String, dynamic> && error['message'] is String) {
        return error['message'] as String;
      }
    } catch (_) {}
    return 'Upload failed.';
  }
}
