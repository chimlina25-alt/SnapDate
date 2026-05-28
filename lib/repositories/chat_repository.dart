import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message.dart';
import '../service/chat_service.dart';

class ChatRepository {
  ChatRepository({ChatService? service}) : _service = service ?? ChatService();

  final ChatService _service;

  Stream<QuerySnapshot<Map<String, dynamic>>> streamChatRooms(String uid) {
    return _service.streamChatRooms(uid);
  }

  Stream<List<ChatMessage>> streamMessages(
    String chatId, {
    String? currentUid,
  }) {
    return _service.streamMessages(chatId, currentUid: currentUid);
  }

  Future<void> sendText({
    required String fromUid,
    required String toUid,
    required String text,
  }) {
    return _service.sendText(fromUid: fromUid, toUid: toUid, text: text);
  }

  Future<void> sendImage({
    required String fromUid,
    required String toUid,
    required File file,
  }) {
    return _service.sendImage(fromUid: fromUid, toUid: toUid, file: file);
  }
}
