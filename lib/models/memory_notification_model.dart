import 'package:cloud_firestore/cloud_firestore.dart';

class MemoryNotificationModel {
  final String id;
  final String caption;
  final String imageUrl;
  final DateTime? createdAt;

  const MemoryNotificationModel({
    required this.id,
    required this.caption,
    required this.imageUrl,
    this.createdAt,
  });

  factory MemoryNotificationModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final imageUrl =
        (data['imageUrl'] ??
                data['mediaUrl'] ??
                data['photoUrl'] ??
                data['imagePath'] ??
                '')
            .toString();
    final caption =
        (data['caption'] ??
                data['title'] ??
                data['description'] ??
                'A memory from a year ago')
            .toString();
    return MemoryNotificationModel(
      id: doc.id,
      caption: caption,
      imageUrl: imageUrl,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ??
          (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }
}
