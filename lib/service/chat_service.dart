import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../models/chat_message.dart';
import '../models/message_model.dart';
import 'cloudinary_service.dart';

class ChatService {
  ChatService({
    FirebaseFirestore? firestore,
    CloudinaryService? cloudinaryService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _cloudinaryService = cloudinaryService ?? CloudinaryService();

  final FirebaseFirestore _firestore;
  final CloudinaryService _cloudinaryService;

  Stream<QuerySnapshot<Map<String, dynamic>>> streamChatRooms(String uid) {
    return _firestore
        .collection('chat_rooms')
        .where('members', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  Stream<List<ChatMessage>> streamMessages(String chatId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(ChatMessage.fromDoc).toList());
  }

  Future<void> createRoom({
    required String firstUid,
    required String secondUid,
  }) async {
    final chatId = getChatId(firstUid, secondUid);
    final ids = [firstUid, secondUid]..sort();
    await _firestore.collection('chat_rooms').doc(chatId).set({
      'members': ids,
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderId': '',
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> sendText({
    required String fromUid,
    required String toUid,
    required String text,
  }) {
    return _sendMessage(fromUid: fromUid, toUid: toUid, text: text);
  }

  Future<void> sendImage({
    required String fromUid,
    required String toUid,
    File? file,
    XFile? xFile,
  }) async {
    final imageFile = file ?? File(xFile!.path);
    final secureUrl = await _cloudinaryService.uploadImage(
      imageFile,
      isAvatar: false,
    );
    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary chat image upload failed.');
    }

    await _sendMessage(
      fromUid: fromUid,
      toUid: toUid,
      imageUrl: secureUrl,
      storagePath: secureUrl,
    );
  }

  Future<void> sendExistingImage({
    required String fromUid,
    required String toUid,
    required String imageUrl,
  }) {
    return _sendMessage(fromUid: fromUid, toUid: toUid, imageUrl: imageUrl);
  }

  Future<void> editMessage(
    String chatId,
    String messageId,
    String newText,
  ) async {
    if (newText.trim().isEmpty) return;
    final messageRef = _firestore
        .collection('chat_rooms')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    await messageRef.update({
      'text': newText.trim(),
      'isEdited': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    final messageRef = _firestore
        .collection('chat_rooms')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    await messageRef.update({
      'isDeleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _sendMessage({
    required String fromUid,
    required String toUid,
    String text = '',
    String imageUrl = '',
    String storagePath = '',
  }) async {
    if (text.trim().isEmpty && imageUrl.trim().isEmpty) return;
    final chatId = getChatId(fromUid, toUid);
    final chatRef = _firestore.collection('chat_rooms').doc(chatId);
    final now = FieldValue.serverTimestamp();
    final ids = [fromUid, toUid]..sort();
    await chatRef.set({
      'members': ids,
      'lastMessage': text.trim().isNotEmpty ? text.trim() : 'Image',
      'lastMessageAt': now,
      'lastSenderId': fromUid,
      'updatedAt': now,
      'createdAt': now,
    }, SetOptions(merge: true));
    final message = MessageModel(
      id: '',
      senderId: fromUid,
      text: text,
      imageUrl: imageUrl,
      storagePath: storagePath,
    ).toMap();
    await chatRef.collection('messages').add({
      ...message,
      'senderId': fromUid,
      'receiverId': toUid,
      'isRead': false,
    });
  }

  static String getChatId(String a, String b) {
    final ids = [a, b]..sort();
    return '${ids[0]}_${ids[1]}';
  }
}
