import 'package:cloud_firestore/cloud_firestore.dart';

import 'message_model.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final String imageUrl;
  final String storagePath;
  final bool isEdited;
  final bool isDeleted;
  final bool isDeletedForEveryone;
  final List<String> deletedByUsers;
  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.imageUrl,
    required this.storagePath,
    this.isEdited = false,
    this.isDeleted = false,
    this.isDeletedForEveryone = false,
    this.deletedByUsers = const [],
    this.createdAt,
  });

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final message = MessageModel.fromDoc(doc);
    final data = doc.data() ?? {};
    return ChatMessage(
      id: message.id,
      senderId: message.senderId,
      receiverId: (data['receiverId'] ?? '').toString(),
      text: message.text,
      imageUrl: message.imageUrl,
      storagePath: message.storagePath,
      isEdited: message.isEdited,
      isDeleted: message.isDeleted,
      isDeletedForEveryone: message.isDeletedForEveryone,
      deletedByUsers: message.deletedByUsers,
      createdAt: message.timestamp,
    );
  }
}
