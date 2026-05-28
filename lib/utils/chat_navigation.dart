import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../service/chat_service.dart';
import '../views/chat_room_screen.dart';

/// ChatNavigation - Unified routing for all chat entry points.
/// 
/// This ensures both "Chat List" taps and "Profile Message" buttons
/// route to the exact same ChatRoomScreen with consistent parameters.
class ChatNavigation {
  /// Navigate to a chat room from any entry point.
  /// 
  /// Automatically:
  /// - Computes deterministic chatRoomId by sorting UIDs alphabetically
  /// - Ensures Firestore chat_room document exists (creates if needed)
  /// - Routes to unified ChatRoomScreen
  /// 
  /// Parameters:
  ///   - context: Build context for navigation
  ///   - currentUid: Current user's UID
  ///   - recipientUser: The recipient (AppUser object)
  /// 
  /// Usage:
  ///   ChatNavigation.toChatRoom(context, currentUid, recipientUser);
  static Future<void> toChatRoom(
    BuildContext context, {
    required String currentUid,
    required AppUser recipientUser,
  }) async {
    if (currentUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to chat.')),
      );
      return;
    }

    // Compute deterministic chat room ID (sorted UIDs)
    final chatRoomId = ChatService.getChatId(currentUid, recipientUser.uid);

    // Ensure the chat room exists in Firestore
    try {
      await ChatService().createRoom(
        firstUid: currentUid,
        secondUid: recipientUser.uid,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing chat: $e')),
        );
      }
      return;
    }

    // Navigate to unified ChatRoomScreen
    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            chatRoomId: chatRoomId,
            recipientId: recipientUser.uid,
          ),
        ),
      );
    }
  }

  /// Simpler variant if you already have recipientId string
  static Future<void> toChatRoomById(
    BuildContext context, {
    required String currentUid,
    required String recipientId,
  }) async {
    if (currentUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to chat.')),
      );
      return;
    }

    final chatRoomId = ChatService.getChatId(currentUid, recipientId);

    try {
      await ChatService().createRoom(
        firstUid: currentUid,
        secondUid: recipientId,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing chat: $e')),
        );
      }
      return;
    }

    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            chatRoomId: chatRoomId,
            recipientId: recipientId,
          ),
        ),
      );
    }
  }
}
