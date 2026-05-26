import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  CloudinaryService({String? cloudName, String? uploadPreset})
    : _cloudName = cloudName ?? _defaultCloudName,
      _uploadPreset = uploadPreset ?? _defaultUploadPreset;

  static const String _defaultCloudName = 'dkwq4gsst';
  static const String _defaultUploadPreset = 'snapdate_preset';

  final String _cloudName;
  final String _uploadPreset;

  Uri get _uploadUri =>
      Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

  Future<String?> uploadImage(File file, {bool isAvatar = false}) async {
    try {
      final request = http.MultipartRequest('POST', _uploadUri);
      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = isAvatar ? 'profiles' : 'memories';
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200 && response.statusCode != 201) {
        final body = response.body;
        throw HttpException(
          'Cloudinary upload failed (${response.statusCode}): $body',
        );
      }

      final Map<String, dynamic> bodyMap = jsonDecode(response.body);
      final secureUrl = bodyMap['secure_url'] as String?;

      if (secureUrl == null || secureUrl.isEmpty) {
        throw FormatException('Cloudinary response did not contain secure_url');
      }

      return secureUrl;
    } catch (e, stackTrace) {
      debugPrint('Cloudinary upload error: $e');
      debugPrint('$stackTrace');
      return null;
    }
  }
}
