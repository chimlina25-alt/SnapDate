import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../models/chat_message.dart';
import '../models/message_model.dart';
import 'storage_service.dart';

class ChatService {
  ChatService({
    FirebaseFirestore? firestore,
    StorageService? storageService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storageService = storageService ?? StorageService();

  final FirebaseFirestore _firestore;
  final StorageService _storageService;

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
    final upload = await _storageService.uploadImage(
      ownerId: fromUid,
      file: file,
      xFile: xFile,
      folder: 'chat_images',
    );
    await _sendMessage(
      fromUid: fromUid,
      toUid: toUid,
      imageUrl: upload.url,
      storagePath: upload.path,
    );
  }

  Future<void> sendExistingImage({
    required String fromUid,
    required String toUid,
    required String imageUrl,
  }) {
    return _sendMessage(fromUid: fromUid, toUid: toUid, imageUrl: imageUrl);
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
    });
  }

  static String getChatId(String a, String b) {
    final ids = [a, b]..sort();
    return '${ids[0]}_${ids[1]}';
  }
}
