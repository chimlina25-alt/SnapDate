import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

ImageProvider? appImageProvider(String? value) {
  final imageValue = value?.trim() ?? '';
  if (imageValue.isEmpty) return null;

  if (imageValue.startsWith('data:image')) {
    return MemoryImage(base64Decode(imageValue.split(',').last));
  }

  if (_isLocalPath(imageValue)) {
    return FileImage(File(imageValue));
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

  if (_isLocalPath(imageValue)) {
    return Image.file(
      File(imageValue),
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          fallback ?? const Icon(Icons.broken_image_outlined, color: Colors.black26),
    );
  }

  return CachedNetworkImage(
    imageUrl: imageValue,
    fit: fit,
    placeholder: (context, url) => const Center(
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
    errorWidget: (context, url, error) =>
        fallback ?? const Icon(Icons.broken_image_outlined, color: Colors.black26),
  );
}

bool _isLocalPath(String value) {
  return value.startsWith('/') || RegExp(r'^[A-Za-z]:[\\/]').hasMatch(value);
}
