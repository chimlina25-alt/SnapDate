# Quick Reference: Key Code Snippets

## 1. Unified ChatRoomScreen - Constructor & Entry Point
```dart
// File: lib/views/chat_room_screen.dart

class ChatRoomScreen extends StatefulWidget {
  final String chatRoomId;
  final String recipientId;

  const ChatRoomScreen({
    super.key,
    required this.chatRoomId,
    required this.recipientId,
  });
  // ...
}
```

## 2. Navigation Helper - Universal Routing
```dart
// File: lib/utils/chat_navigation.dart

static Future<void> toChatRoom(
  BuildContext context, {
  required String currentUid,
  required AppUser recipientUser,
}) async {
  // Compute deterministic chat room ID
  final chatRoomId = ChatService.getChatId(
    currentUid, 
    recipientUser.uid
  );

  // Ensure chat room exists in Firestore
  try {
    await ChatService().createRoom(
      firstUid: currentUid,
      secondUid: recipientUser.uid,
    );
  } catch (e) {
    // Handle error
  }

  // Navigate to unified screen
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
```

## 3. Profile View - Updated Message Button Handler
```dart
// File: lib/views/user_profile_view.dart

void _openChat() {
  if (_uid.isEmpty) return;
  ChatNavigation.toChatRoom(
    context,
    currentUid: _uid,
    recipientUser: widget.profile,
  );
}
```

## 4. Message Stream - Deletion Filter
```dart
// File: lib/service/chat_service.dart

Stream<List<ChatMessage>> streamMessages(
  String chatId, {
  String? currentUid,
}) {
  return _firestore
      .collection('chat_rooms')
      .doc(chatId)
      .collection('messages')
      .orderBy('createdAt')
      .snapshots()
      .map((snap) {
        final messages = snap.docs.map(ChatMessage.fromDoc).toList();
        return messages.where((message) {
          // Hide if deleted for everyone
          if (message.isDeleted || message.isDeletedForEveryone) {
            return false;
          }
          // Hide if current user deleted it for themselves
          if (currentUid != null &&
              message.deletedByUsers.contains(currentUid)) {
            return false;
          }
          return true;
        }).toList();
      });
}
```

## 5. Delete for Me Implementation
```dart
// File: lib/service/chat_service.dart

Future<void> deleteMessageForMe(
  String chatId,
  String messageId,
  String currentUid,
) async {
  final messageRef = _firestore
      .collection('chat_rooms')
      .doc(chatId)
      .collection('messages')
      .doc(messageId);

  await messageRef.update({
    'deletedByUsers': FieldValue.arrayUnion([currentUid]),
    'updatedAt': FieldValue.serverTimestamp(),
  });
}
```

## 6. Delete for Everyone Implementation
```dart
// File: lib/service/chat_service.dart

Future<void> deleteMessageForEveryone(
  String chatId, 
  String messageId
) async {
  final messageRef = _firestore
      .collection('chat_rooms')
      .doc(chatId)
      .collection('messages')
      .doc(messageId);

  await messageRef.update({
    'isDeletedForEveryone': true,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}
```

## 7. Delete Options Dialog - ChatRoomScreen
```dart
// File: lib/views/chat_room_screen.dart

void _showDeleteOptions(ChatMessage message) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Delete message'),
        content: const Text(
          'How would you like to delete this message?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessageForMe(message);
            },
            child: const Text('Delete for Me'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessageForEveryone(message);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete for Everyone'),
          ),
        ],
      );
    },
  );
}
```

## 8. Message Bubble - Menu Options
```dart
// File: lib/views/chat_room_screen.dart

if (isMine && !isDeleted)
  Align(
    alignment: Alignment.topRight,
    child: PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') {
          _startEditingMessage(message);
        } else if (value == 'deleteMe') {
          _deleteMessageForMe(message);
        } else if (value == 'deleteAll') {
          _deleteMessageForEveryone(message);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(value: 'deleteMe', child: Text('Delete for Me')),
        PopupMenuItem(value: 'deleteAll', child: Text('Delete for Everyone')),
      ],
    ),
  ),
```

## 9. Chat Room ID Generation (Deterministic)
```dart
// File: lib/service/chat_service.dart

static String getChatId(String a, String b) {
  final ids = [a, b]..sort();
  return '${ids[0]}_${ids[1]}';
}
```

**Examples**:
- `getChatId('user123', 'user456')` → `'user123_user456'`
- `getChatId('user456', 'user123')` → `'user123_user456'` (same!)

## 10. Firestore Message Document Structure
```json
{
  "id": "msg_abc123",
  "senderId": "user123",
  "receiverId": "user456",
  "text": "Hello there!",
  "imageUrl": "",
  "storagePath": "",
  "createdAt": Timestamp(2025-05-27),
  "isEdited": false,
  "isDeleted": false,
  "isDeletedForEveryone": false,
  "deletedByUsers": [],
  "timestamp": Timestamp(2025-05-27)
}
```

**After "Delete for Me" by user123**:
```json
{
  // ... (other fields unchanged)
  "deletedByUsers": ["user123"]
}
```

**After "Delete for Everyone"**:
```json
{
  // ... (other fields unchanged)
  "isDeletedForEveryone": true
}
```

---

## Migration Guide for Existing Chat References

### Before (Old Pattern)
```dart
// Two different entry points with inconsistent UIs
ChatView(initialActiveFriend: friend)  // Path A
ChatView()  // Path B - different UI when entering from list
```

### After (New Pattern)
```dart
// Single unified entry point
ChatRoomScreen(
  chatRoomId: ChatService.getChatId(uid1, uid2),
  recipientId: uid2,
)

// Recommended: Use navigation helper
ChatNavigation.toChatRoom(context, currentUid: uid1, recipientUser: user);
```

---

## Testing Scenarios

### Scenario 1: Send and Delete for Me
```
1. Open ChatRoomScreen
2. Send: "Test message"
3. Long-press message → "Delete for Me"
4. Message disappears from sender's view
5. ✓ Recipient still sees the message
6. ✓ Firestore: message.deletedByUsers = ["senderUID"]
```

### Scenario 2: Send and Delete for Everyone
```
1. Open ChatRoomScreen
2. Send: "Secret message"
3. Long-press message → "Delete for Everyone"
4. Message shows "This message was deleted" for both users
5. ✓ Firestore: message.isDeletedForEveryone = true
```

### Scenario 3: Edit and Delete
```
1. Send: "Original text"
2. Three-dot menu → "Edit" → "New text"
3. Three-dot menu → "Delete for Me"
4. Message disappears from sender's view
5. ✓ Works correctly after edit
```

### Scenario 4: Routing Consistency
```
1. Click ChatList entry → ChatRoomScreen
2. UI: AppBar, message list, composer
3. Navigate to Profile → "Message" button → ChatRoomScreen
4. UI: IDENTICAL AppBar, message list, composer
5. ✓ Both paths show same UI
```

