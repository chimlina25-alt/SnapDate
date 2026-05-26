import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

String? appDocumentsDirectoryPath;

String _resolveLocalPath(String originalPath) {
  if (originalPath.isEmpty) return originalPath;
  final snapdateIndex = originalPath.toLowerCase().indexOf('snapdate');
  if (snapdateIndex != -1 && appDocumentsDirectoryPath != null) {
    final partAfterSnapdate = originalPath.substring(
      snapdateIndex + 'snapdate'.length,
    );
    final cleanPart = partAfterSnapdate.replaceFirst(RegExp(r'^[\\/]'), '');
    return p.join(appDocumentsDirectoryPath!, cleanPart);
  }
  return originalPath;
}

ImageProvider? appImageProvider(String? value) {
  final imageValue = value?.trim() ?? '';
  if (imageValue.isEmpty) return null;

  if (imageValue.startsWith('data:image')) {
    return MemoryImage(base64Decode(imageValue.split(',').last));
  }

  if (imageValue.startsWith('blob:')) {
    return NetworkImage(imageValue);
  }

  if (!kIsWeb && _isLocalPath(imageValue)) {
    return FileImage(File(_resolveLocalPath(imageValue)));
  }

  if (kIsWeb && _isLocalPath(imageValue)) {
    return null;
  }

  return CachedNetworkImageProvider(imageValue);
}

Widget appImage(String? value, {BoxFit fit = BoxFit.cover, Widget? fallback}) {
  final imageValue = value?.trim() ?? '';
  if (imageValue.isEmpty) {
    return fallback ?? const Icon(Icons.image_outlined, color: Colors.black26);
  }

  if (imageValue.startsWith('data:image')) {
    return Image.memory(base64Decode(imageValue.split(',').last), fit: fit);
  }

  if (imageValue.startsWith('blob:')) {
    return Image.network(imageValue, fit: fit);
  }

  if (!kIsWeb && _isLocalPath(imageValue)) {
    return Image.file(
      File(_resolveLocalPath(imageValue)),
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          fallback ??
          const Icon(Icons.broken_image_outlined, color: Colors.black26),
    );
  }

  if (kIsWeb && _isLocalPath(imageValue)) {
    return fallback ??
        const Icon(Icons.broken_image_outlined, color: Colors.black26);
  }

  return CachedNetworkImage(
    imageUrl: imageValue,
    fit: fit,
    placeholder: (context, url) =>
        const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    errorWidget: (context, url, error) =>
        fallback ??
        const Icon(Icons.broken_image_outlined, color: Colors.black26),
  );
}

bool _isLocalPath(String value) {
  return value.startsWith('/') || RegExp(r'^[A-Za-z]:[\\/]').hasMatch(value);
}
