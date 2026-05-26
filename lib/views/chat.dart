import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/app_user.dart';
import '../models/chat_message.dart';
import '../models/memory.dart';
import '../utils/app_image.dart';
import '../service/chat_service.dart';
import '../service/friend_service.dart';
import '../service/memory_service.dart';
import '../service/user_service.dart';

class ChatView extends StatefulWidget {
  final String initialQuery;
  final AppUser? initialActiveFriend;

  const ChatView({super.key, this.initialQuery = '', this.initialActiveFriend});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _searchController = TextEditingController();
  final _messageController = TextEditingController();
  final _messagesController = ScrollController();
  final _picker = ImagePicker();
  AppUser? _activeFriend;
  String _query = '';
  bool _isSending = false;
  final UserService _userService = UserService();
  final FriendService _friendService = FriendService();
  final ChatService _chatService = ChatService();

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery.trim().toLowerCase();
    _searchController.text = widget.initialQuery.trim();
    if (widget.initialActiveFriend != null) {
      _activeFriend = widget.initialActiveFriend;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    _messagesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_uid.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('Please sign in to chat.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: _activeFriend == null ? _buildInbox() : _buildConversation(),
    );
  }

  Widget _buildInbox() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search profile name',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
              filled: true,
              fillColor: const Color(0xFFEDF6F4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        if (_query.isNotEmpty) _buildSearchResults(),
        _buildIncomingRequests(),
        Expanded(child: _buildFriendList()),
      ],
    );
  }

  Widget _buildSearchResults() {
    return FutureBuilder<List<AppUser>>(
      future: _userService.searchUsers(_query, _uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: LinearProgressIndicator(),
          );
        }

        final results = snapshot.data!;

        if (results.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No profiles found.',
              style: TextStyle(color: Colors.black45),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(18, 4, 18, 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: results.map((user) {
              return ListTile(
                leading: _avatar(user.profileImageUrl),
                title: Text(
                  user.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD6A2A8),
                    foregroundColor: Colors.black87,
                  ),
                  onPressed: () => _sendFriendRequest(user),
                  child: const Text('Add Friend'),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildIncomingRequests() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _friendService.streamIncomingRequests(_uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Text(
              'Error loading requests: ${snapshot.error}',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        final sortedDocs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(docs);
        sortedDocs.sort((a, b) {
          final aTime = a.data()['timestamp'] as Timestamp?;
          final bTime = b.data()['timestamp'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        return Container(
          margin: const EdgeInsets.fromLTRB(18, 4, 18, 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: sortedDocs.map((doc) {
              final data = doc.data();
              return ListTile(
                leading: _avatar((data['profileImageUrl'] ?? data['avatarUrl'] ?? '').toString()),
                title: Text((data['username'] ?? 'SnapDate User').toString()),
                subtitle: const Text('Friend request'),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      tooltip: 'Accept',
                      icon: const Icon(Icons.check_circle_outline),
                      color: const Color(0xFFE26A97),
                      onPressed: () => _acceptFriendRequest(
                        (data['senderId'] ?? data['fromUid'] ?? doc.id).toString(),
                        data,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Reject',
                      icon: const Icon(Icons.cancel_outlined),
                      color: Colors.black38,
                      onPressed: () => _rejectFriendRequest(
                        (data['senderId'] ?? data['fromUid'] ?? doc.id).toString(),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildFriendList() {
    return StreamBuilder<List<AppUser>>(
      stream: _friendService.streamFriends(_uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error loading friends: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 65,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 14),
                const Text(
                  "Your chat inbox is empty.\nSearch a profile name to add friends.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    color: Colors.black38,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
          itemCount: snapshot.data!.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final friend = snapshot.data![index];

            return ListTile(
              leading: _avatar(friend.profileImageUrl),
              title: Text(
                friend.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: _LastMessage(chatId: ChatService.getChatId(_uid, friend.uid)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() => _activeFriend = friend),
            );
          },
        );
      },
    );
  }

  Widget _buildConversation() {
    final friend = _activeFriend!;
    final friendId = friend.uid;
    final chatId = ChatService.getChatId(_uid, friendId);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
          color: const Color(0xFFEDF6F4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _activeFriend = null),
              ),
              _avatar(friend.profileImageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  friend.username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<ChatMessage>>(
            stream: _chatService.streamMessages(chatId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final messages = snapshot.data!;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_messagesController.hasClients) {
                  _messagesController.jumpTo(
                    _messagesController.position.maxScrollExtent,
                  );
                }
              });
              if (messages.isEmpty) {
                return const Center(
                  child: Text(
                    'Start the conversation.',
                    style: TextStyle(color: Colors.black38),
                  ),
                );
              }

              return ListView.builder(
                controller: _messagesController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final mine = message.senderId == _uid;
                  return _messageBubble(message, mine);
                },
              );
            },
          ),
        ),
        _buildComposer(friendId),
      ],
    );
  }

  Widget _buildComposer(String friendId) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Send app image',
              icon: const Icon(Icons.photo_library_outlined),
              onPressed: _isSending ? null : () => _showMemoryPicker(friendId),
            ),
            IconButton(
              tooltip: 'Send computer image',
              icon: const Icon(Icons.attach_file),
              onPressed: _isSending ? null : () => _sendPickedImage(friendId),
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Message',
                  filled: true,
                  fillColor: const Color(0xFFEDF6F4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Color(0xFFE26A97)),
              onPressed: _isSending ? null : () => _sendText(friendId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageBubble(ChatMessage message, bool mine) {
    final text = message.text;
    final imageUrl = message.imageUrl;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: EdgeInsets.all(imageUrl.isEmpty ? 12 : 6),
        decoration: BoxDecoration(
          color: mine ? const Color(0xFFFCD7D9) : const Color(0xFFEDF6F4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: appImage(imageUrl, fit: BoxFit.cover),
              )
            else
              Text(text),
            const SizedBox(height: 4),
            Text(
              _formatMessageTime(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: Colors.black.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(String avatarUrl) {
    final imageProvider = appImageProvider(avatarUrl);
    return CircleAvatar(
      backgroundColor: const Color(0xFFFCD7D9),
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? const Icon(Icons.person, color: Colors.black45)
          : null,
    );
  }

  Future<void> _sendFriendRequest(AppUser toUser) async {
    try {
      final current = await _userService.userRef(_uid).get();
      final currentUser = current.exists
          ? AppUser.fromDoc(current)
          : AppUser(
              uid: _uid,
              email: FirebaseAuth.instance.currentUser?.email ?? '',
              username: FirebaseAuth.instance.currentUser?.displayName ?? 'SnapDate User',
              usernameLower: 'snapdate user',
              profileImageUrl: '',
              bio: '',
              highlightUrls: const [],
            );
      await _friendService.sendRequest(
        fromUid: _uid,
        fromUser: currentUser,
        toUser: toUser,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Request sent to ${toUser.username}.')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not add friend: $e')));
    }
  }

  Future<void> _acceptFriendRequest(String fromUid, Map<String, dynamic> data) async {
    final current = await _userService.userRef(_uid).get();
    if (!current.exists) return;
    await _friendService.acceptRequest(
      uid: _uid,
      currentUser: AppUser.fromDoc(current),
      fromUid: fromUid,
      requestData: data,
    );
    // Automatically navigate/switch to the chat with this new friend!
    final friendUser = AppUser(
      uid: fromUid,
      email: data['email'] ?? '',
      username: data['username'] ?? 'SnapDate User',
      usernameLower: (data['username'] ?? 'SnapDate User').toString().toLowerCase(),
      profileImageUrl: data['profileImageUrl'] ?? data['avatarUrl'] ?? '',
      bio: '',
      highlightUrls: const [],
    );
    setState(() {
      _activeFriend = friendUser;
    });
  }

  Future<void> _rejectFriendRequest(String fromUid) async {
    await _friendService.rejectRequest(uid: _uid, fromUid: fromUid);
  }

  Future<void> _sendText(String friendId) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    await _sendMessage(friendId: friendId, text: text);
  }

  Future<void> _sendPickedImage(String friendId) async {
    final selected = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 65,
    );
    if (selected == null) return;

    await _sendMessage(friendId: friendId, imageXFile: selected);
  }

  Future<void> _showMemoryPicker(String friendId) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return StreamBuilder<List<Memory>>(
          stream: MemoryService().streamMemories(_uid, limit: 30),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final memories = snapshot.data!;
            if (memories.isEmpty) {
              return const SizedBox(
                height: 180,
                child: Center(child: Text('No app gallery images yet.')),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(14),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: memories.length,
              itemBuilder: (context, index) {
                final imageUrl = memories[index].mediaUrl;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _sendMessage(friendId: friendId, imageUrl: imageUrl);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: appImage(imageUrl),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _sendMessage({
    required String friendId,
    String text = '',
    String imageUrl = '',
    XFile? imageXFile,
  }) async {
    if (text.isEmpty && imageUrl.isEmpty && imageXFile == null) return;
    setState(() => _isSending = true);

    try {
      if (imageXFile != null) {
        await _chatService.sendImage(fromUid: _uid, toUid: friendId, xFile: imageXFile);
      } else if (imageUrl.isNotEmpty) {
        await _chatService.sendExistingImage(fromUid: _uid, toUid: friendId, imageUrl: imageUrl);
      } else {
        await _chatService.sendText(fromUid: _uid, toUid: friendId, text: text);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not send message: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

}

class _LastMessage extends StatelessWidget {
  final String chatId;

  const _LastMessage({required this.chatId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('chat_rooms').doc(chatId).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final text = (data?['lastMessage'] ?? 'Tap to chat').toString();
        final date = (data?['lastMessageAt'] as Timestamp?)?.toDate() ??
            (data?['updatedAt'] as Timestamp?)?.toDate();
        final suffix = date == null ? '' : '  ${_formatMessageTime(date)}';
        return Text('$text$suffix', maxLines: 1, overflow: TextOverflow.ellipsis);
      },
    );
  }
}

String _formatMessageTime(DateTime? date) {
  if (date == null) return '';
  final now = DateTime.now();
  final sameDay =
      now.year == date.year && now.month == date.month && now.day == date.day;
  return sameDay ? DateFormat('HH:mm').format(date) : DateFormat('MMM d').format(date);
}
