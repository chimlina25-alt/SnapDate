import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final String imageUrl;
  final String storagePath;
  final DateTime? timestamp;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.imageUrl,
    required this.storagePath,
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
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ??
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
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
