import 'dart:io';

import 'local_storage_service.dart';

class StorageUpload {
  final String url;
  final String path;

  const StorageUpload({required this.url, required this.path});
}

class StorageService {
  StorageService({LocalStorageService? localStorageService})
      : _localStorageService = localStorageService ?? LocalStorageService();

  final LocalStorageService _localStorageService;

  Future<StorageUpload> uploadImage({
    required String ownerId,
    required File file,
    required String folder,
  }) async {
    final saved = await _localStorageService.saveImage(
      file: file,
      ownerId: ownerId,
      folder: folder,
    );
    return StorageUpload(url: saved.path, path: saved.path);
  }

  Future<StorageUpload> uploadVideo({
    required String ownerId,
    required File file,
    required String folder,
  }) async {
    final saved = await _localStorageService.saveVideo(
      file: file,
      ownerId: ownerId,
      folder: folder,
    );
    return StorageUpload(url: saved.path, path: saved.path);
  }

  Future<void> deleteByPath(String path) async {
    await _localStorageService.deleteFile(path);
  }
}
