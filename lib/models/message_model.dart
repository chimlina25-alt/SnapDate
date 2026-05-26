import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final String imageUrl;
  final String storagePath;
  final bool isEdited;
  final bool isDeleted;
  final DateTime? timestamp;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.imageUrl,
    required this.storagePath,
    this.isEdited = false,
    this.isDeleted = false,
    this.timestamp,
  });

  String get imagePath => imageUrl;

  factory MessageModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return MessageModel(
      id: doc.id,
      senderId: (data['senderId'] ?? '').toString(),
      text: (data['text'] ?? '').toString(),
      imageUrl: (data['imagePath'] ?? data['imageUrl'] ?? '').toString(),
      storagePath: (data['storagePath'] ?? data['imagePath'] ?? '').toString(),
      isEdited: data['isEdited'] == true,
      isDeleted: data['isDeleted'] == true,
      timestamp:
          (data['timestamp'] as Timestamp?)?.toDate() ??
          (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text.trim(),
      'imagePath': imageUrl,
      'imageUrl': imageUrl,
      'storagePath': storagePath,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
