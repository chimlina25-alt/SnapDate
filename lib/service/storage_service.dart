import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'local_storage_service.dart';

class StorageUpload {
  final String url;
  final String path;

  const StorageUpload({required this.url, required this.path});
}

class StorageService {
  StorageService({
    LocalStorageService? localStorageService,
    FirebaseStorage? firebaseStorage,
  })  : _localStorageService = localStorageService ?? LocalStorageService(),
        _firebaseStorage = firebaseStorage ?? FirebaseStorage.instance;

  final LocalStorageService _localStorageService;
  final FirebaseStorage _firebaseStorage;

  Future<StorageUpload> uploadImage({
    required String ownerId,
    File? file,
    XFile? xFile,
    Uint8List? bytes,
    required String folder,
  }) async {
    // 1. On Web, we upload directly from bytes or XFile
    if (kIsWeb) {
      try {
        final uploadBytes = bytes ?? await xFile?.readAsBytes();
        if (uploadBytes == null) {
          throw Exception("No image data provided for upload");
        }
        final ref = _firebaseStorage.ref().child('$folder/$ownerId/${DateTime.now().microsecondsSinceEpoch}.jpg');
        
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          cacheControl: 'public, max-age=31536000',
        );
        
        await ref.putData(uploadBytes, metadata);
        final downloadUrl = await ref.getDownloadURL();
        return StorageUpload(url: downloadUrl, path: ref.fullPath);
      } catch (e) {
        debugPrint("Firebase Storage web upload failed: $e");
        final fallbackUrl = xFile?.path ?? (bytes != null ? 'data:image/jpeg;base64,${base64Encode(bytes)}' : '');
        return StorageUpload(url: fallbackUrl, path: '');
      }
    }

    // 2. On Mobile, we follow the original logic
    final fileToUse = file ?? File(xFile!.path);
    final saved = await _localStorageService.saveImage(
      file: fileToUse,
      ownerId: ownerId,
      folder: folder,
    );

    try {
      final ref = _firebaseStorage.ref().child('$folder/$ownerId/${DateTime.now().microsecondsSinceEpoch}.jpg');
      await ref.putFile(fileToUse);
      final downloadUrl = await ref.getDownloadURL();
      return StorageUpload(url: downloadUrl, path: ref.fullPath);
    } catch (e) {
      debugPrint("Firebase Storage upload failed, using local fallback: $e");
      return StorageUpload(url: saved.path, path: saved.path);
    }
  }

  Future<StorageUpload> uploadVideo({
    required String ownerId,
    File? file,
    XFile? xFile,
    Uint8List? bytes,
    required String folder,
  }) async {
    if (kIsWeb) {
      try {
        final uploadBytes = bytes ?? await xFile?.readAsBytes();
        if (uploadBytes == null) {
          throw Exception("No video data provided for upload");
        }
        final ext = xFile?.name.endsWith('.mov') == true ? '.mov' : '.mp4';
        final ref = _firebaseStorage.ref().child('$folder/$ownerId/${DateTime.now().microsecondsSinceEpoch}$ext');
        
        final metadata = SettableMetadata(
          contentType: ext == '.mov' ? 'video/quicktime' : 'video/mp4',
        );
        
        await ref.putData(uploadBytes, metadata);
        final downloadUrl = await ref.getDownloadURL();
        return StorageUpload(url: downloadUrl, path: ref.fullPath);
      } catch (e) {
        debugPrint("Firebase Storage web video upload failed: $e");
        return StorageUpload(url: xFile?.path ?? '', path: '');
      }
    }

    final fileToUse = file ?? File(xFile!.path);
    final saved = await _localStorageService.saveVideo(
      file: fileToUse,
      ownerId: ownerId,
      folder: folder,
    );

    try {
      final ext = fileToUse.path.endsWith('.mov') ? '.mov' : '.mp4';
      final ref = _firebaseStorage.ref().child('$folder/$ownerId/${DateTime.now().microsecondsSinceEpoch}$ext');
      await ref.putFile(fileToUse);
      final downloadUrl = await ref.getDownloadURL();
      return StorageUpload(url: downloadUrl, path: ref.fullPath);
    } catch (e) {
      debugPrint("Firebase Storage upload failed, using local fallback: $e");
      return StorageUpload(url: saved.path, path: saved.path);
    }
  }

  Future<void> deleteByPath(String path) async {
    if (path.isEmpty) return;
    
    // Try to delete from Firebase Storage if it's a cloud storage path
    if (!kIsWeb && !path.startsWith('/') && !path.contains(':\\') && !path.contains(':/')) {
      try {
        await _firebaseStorage.ref().child(path).delete();
      } catch (e) {
        debugPrint("Could not delete from Firebase Storage: $e");
      }
    }
    
    if (kIsWeb && !path.startsWith('blob:') && !path.startsWith('data:')) {
      try {
        await _firebaseStorage.ref().child(path).delete();
      } catch (e) {
        debugPrint("Could not delete from Firebase Storage on Web: $e");
      }
    }
    
    // Delete local file if it exists
    if (!kIsWeb) {
      await _localStorageService.deleteFile(path);
    }
  }
}
