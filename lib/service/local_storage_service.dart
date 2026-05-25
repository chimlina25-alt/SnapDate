import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LocalStoredFile {
  final String path;

  const LocalStoredFile({required this.path});
}

class LocalStorageService {
  Future<LocalStoredFile> saveImage({
    required File file,
    required String ownerId,
    required String folder,
  }) async {
    final dir = await _ensureDirectory(folder, ownerId);
    final targetPath = p.join(
      dir.path,
      '${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 72,
      minWidth: 1440,
      minHeight: 1440,
      format: CompressFormat.jpeg,
    );

    if (result == null) {
      await file.copy(targetPath);
    }

    return LocalStoredFile(path: targetPath);
  }

  Future<LocalStoredFile> saveVideo({
    required File file,
    required String ownerId,
    required String folder,
  }) async {
    final dir = await _ensureDirectory(folder, ownerId);
    final extension = p.extension(file.path).isEmpty ? '.mp4' : p.extension(file.path);
    final targetPath = p.join(
      dir.path,
      '${DateTime.now().microsecondsSinceEpoch}$extension',
    );
    await file.copy(targetPath);
    return LocalStoredFile(path: targetPath);
  }

  Future<void> deleteFile(String path) async {
    if (path.trim().isEmpty) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Directory> _ensureDirectory(String folder, String ownerId) async {
    final documents = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(documents.path, 'snapdate', folder, ownerId));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
