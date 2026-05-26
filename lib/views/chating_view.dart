import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/app_user.dart';
import '../models/chat_message.dart';
import '../models/memory.dart';
import '../utils/app_image.dart'; // Uses your appImage/appImageProvider helper functions
import '../service/chat_service.dart';
import '../service/friend_service.dart';
import '../service/memory_service.dart';
import '../service/user_service.dart';

class ChatView extends StatefulWidget {
  final String initialQuery;

  const ChatView({super.key, this.initialQuery = ''});

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
  ChatMessage? _editingMessage;

  // Services
  final UserService _userService = UserService();
  final FriendService _friendService = FriendService();
  final ChatService _chatService = ChatService();

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery.trim().toLowerCase();
    _searchController.text = widget.initialQuery.trim();
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: _activeFriend != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => setState(() => _activeFriend = null),
              )
            : null,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFCD7D9), // Pastel Pink from Mockup
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'SnapDate',
            style: TextStyle(
              fontFamily:
                  'Billabong', // Change to your cursive font if applicable
              fontSize: 24,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      body: _activeFriend == null ? _buildInbox() : _buildConversation(),
    );
  }

  /// 1. Inbox Main View (Matches your Mockup Screen 1 & 2 layout)
  Widget _buildInbox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal Stories/Active Friends bubble track (Mockup top section)
        _buildActiveFriendsRow(),

        // Search Bar Area
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search profile name',
              prefixIcon: const Icon(Icons.search, color: Colors.black45),
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
              fillColor: const Color(0xFFEDF6F4), // Mint/light teal background
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),

        if (_query.isNotEmpty) _buildSearchResults(),
        _buildIncomingRequests(),

        // Chat List items below the search
        Expanded(child: _buildFriendList()),
      ],
    );
  }

  /// Top Horizontal Profile Bubbles Row (Mockup Section)
  Widget _buildActiveFriendsRow() {
    return StreamBuilder<List<AppUser>>(
      stream: _friendService.streamFriends(_uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final friends = snapshot.data!;
        return SizedBox(
          height: 90,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            scrollDirection: Axis.horizontal,
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              return GestureDetector(
                onTap: () => setState(() => _activeFriend = friend),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFE26A97), // Pink Accent ring
                        ),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFFFCD7D9),
                            backgroundImage: appImageProvider(
                              friend.profileImageUrl,
                            ),
                            child:
                                appImageProvider(friend.profileImageUrl) == null
                                ? const Icon(
                                    Icons.person,
                                    color: Colors.black45,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        friend.username,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
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

        final sortedDocs =
            List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(docs);
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
                leading: _avatar(
                  (data['profileImageUrl'] ?? data['avatarUrl'] ?? '')
                      .toString(),
                ),
                title: Text((data['username'] ?? 'SnapDate User').toString()),
                subtitle: const Text('Friend request'),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline),
                      color: const Color(0xFFE26A97),
                      onPressed: () => _acceptFriendRequest(
                        (data['senderId'] ?? data['fromUid'] ?? doc.id)
                            .toString(),
                        data,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined),
                      color: Colors.black38,
                      onPressed: () => _rejectFriendRequest(
                        (data['senderId'] ?? data['fromUid'] ?? doc.id)
                            .toString(),
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
          separatorBuilder: (context, index) =>
              const Divider(height: 1, color: Color(0xFFF1F1F1)),
          itemBuilder: (context, index) {
            final friend = snapshot.data![index];

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 8,
              ),
              leading: _avatar(friend.profileImageUrl),
              title: Text(
                friend.username,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: _LastMessage(
                chatId: ChatService.getChatId(_uid, friend.uid),
              ),
              onTap: () => setState(() => _activeFriend = friend),
            );
          },
        );
      },
    );
  }

  /// 2. Inside Chat Conversation Room View
  Widget _buildConversation() {
    final friend = _activeFriend!;
    final friendId = friend.uid;
    final chatId = ChatService.getChatId(_uid, friendId);

    return Column(
      children: [
        // Dedicated Context Header bar for active conversation partner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(
            0xFFEDF6F4,
          ), // Light background style matching mockups
          child: Row(
            children: [
              _avatar(friend.profileImageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      'Active now',
                      style: TextStyle(color: Colors.black45, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Chat Bubbles Stream list
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_editingMessage != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5E5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit, size: 18, color: Colors.black87),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Editing message',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black54),
                      onPressed: _cancelEditing,
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.photo_library_outlined,
                    color: Colors.black54,
                  ),
                  onPressed: _isSending
                      ? null
                      : () => _showMemoryPicker(friendId),
                ),
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.black54),
                  onPressed: _isSending
                      ? null
                      : () => _sendPickedImage(friendId),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF6F4),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            minLines: 1,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: _editingMessage != null
                                  ? 'Edit message...'
                                  : 'custom message...',
                              border: InputBorder.none,
                              hintStyle: const TextStyle(color: Colors.black38),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFCD7D9),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _editingMessage != null ? Icons.check : Icons.send,
                      color: const Color(0xFFE26A97),
                    ),
                    tooltip: _editingMessage != null
                        ? 'Save edit'
                        : 'Send message',
                    onPressed: _isSending ? null : () => _sendText(friendId),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageBubble(ChatMessage message, bool mine) {
    final text = message.text;
    final imageUrl = message.imageUrl;
    final isDeleted = message.isDeleted;
    final isEdited = message.isEdited && !isDeleted;
    final bubbleColor = isDeleted
        ? const Color(0xFFEEEEEE)
        : mine
        ? const Color(0xFFFCD7D9)
        : const Color(0xFFEDF6F4);
    final chatPartnerId = message.senderId == _uid
        ? message.receiverId
        : message.senderId;
    final chatId = ChatService.getChatId(_uid, chatPartnerId);

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (mine && !isDeleted)
            Align(
              alignment: Alignment.topRight,
              child: PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.more_vert,
                  size: 18,
                  color: Colors.black54,
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    _startEditingMessage(message);
                  } else if (value == 'delete') {
                    _confirmDeleteMessage(chatId, message);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ),
          Container(
            constraints: const BoxConstraints(maxWidth: 260),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: EdgeInsets.all(imageUrl.isEmpty ? 12 : 6),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: mine
                    ? const Radius.circular(16)
                    : const Radius.circular(0),
                bottomRight: mine
                    ? const Radius.circular(0)
                    : const Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: mine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isDeleted) ...[
                  const Text(
                    'This message was deleted',
                    style: TextStyle(
                      color: Colors.black45,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ] else ...[
                  if (imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: appImage(imageUrl, fit: BoxFit.cover),
                    )
                  else
                    Text(
                      text,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.createdAt),
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.black.withValues(alpha: 0.35),
                        ),
                      ),
                      if (isEdited) ...[
                        const SizedBox(width: 6),
                        const Text(
                          '(edited)',
                          style: TextStyle(fontSize: 9, color: Colors.black54),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(String avatarUrl) {
    final imageProvider = appImageProvider(avatarUrl);
    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFFFCD7D9),
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? const Icon(Icons.person, color: Colors.black45, size: 24)
          : null,
    );
  }

  // Logic Operations (Keep matching your system backend architecture)
  Future<void> _sendFriendRequest(AppUser toUser) async {
    try {
      final current = await _userService.userRef(_uid).get();
      final currentUser = current.exists
          ? AppUser.fromDoc(current)
          : AppUser(
              uid: _uid,
              email: FirebaseAuth.instance.currentUser?.email ?? '',
              username:
                  FirebaseAuth.instance.currentUser?.displayName ??
                  'SnapDate User',
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request sent to ${toUser.username}.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not add friend: $e')));
    }
  }

  Future<void> _acceptFriendRequest(
    String fromUid,
    Map<String, dynamic> data,
  ) async {
    final current = await _userService.userRef(_uid).get();
    if (!current.exists) return;
    await _friendService.acceptRequest(
      uid: _uid,
      currentUser: AppUser.fromDoc(current),
      fromUid: fromUid,
      requestData: data,
    );
  }

  Future<void> _rejectFriendRequest(String fromUid) async {
    await _friendService.rejectRequest(uid: _uid, fromUid: fromUid);
  }

  Future<void> _sendText(String friendId) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    if (_editingMessage != null) {
      await _performEdit(friendId, text);
      return;
    }
    _messageController.clear();
    await _sendMessage(friendId: friendId, text: text);
  }

  Future<void> _performEdit(String friendId, String newText) async {
    final editingMessage = _editingMessage;
    if (editingMessage == null) return;
    final chatId = ChatService.getChatId(_uid, friendId);
    setState(() => _isSending = true);

    try {
      await _chatService.editMessage(chatId, editingMessage.id, newText);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Message updated.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not edit message: $e')));
    } finally {
      if (!mounted) return;
      _messageController.clear();
      setState(() {
        _editingMessage = null;
        _isSending = false;
      });
    }
  }

  void _startEditingMessage(ChatMessage message) {
    if (message.isDeleted) return;
    _messageController.text = message.text;
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
    setState(() => _editingMessage = message);
  }

  void _cancelEditing() {
    _messageController.clear();
    setState(() => _editingMessage = null);
  }

  Future<void> _confirmDeleteMessage(String chatId, ChatMessage message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete message'),
          content: const Text(
            'Delete this message? This will hide it from the conversation.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    setState(() => _isSending = true);
    try {
      await _chatService.deleteMessage(chatId, message.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Message deleted.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not delete message: $e')));
    } finally {
      if (!mounted) return;
      setState(() => _isSending = false);
    }
  }

  Future<void> _sendPickedImage(String friendId) async {
    final selected = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 65,
    );
    if (selected == null) return;
    await _sendMessage(friendId: friendId, imageFile: File(selected.path));
  }

  Future<void> _showMemoryPicker(String friendId) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
    File? imageFile,
  }) async {
    if (text.isEmpty && imageUrl.isEmpty && imageFile == null) return;
    setState(() => _isSending = true);
    try {
      if (imageFile != null) {
        await _chatService.sendImage(
          fromUid: _uid,
          toUid: friendId,
          file: imageFile,
        );
      } else if (imageUrl.isNotEmpty) {
        await _chatService.sendExistingImage(
          fromUid: _uid,
          toUid: friendId,
          imageUrl: imageUrl,
        );
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

/// Dynamic Widget displaying the summary content info for list items
class _LastMessage extends StatelessWidget {
  final String chatId;
  const _LastMessage({required this.chatId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(chatId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final text = (data?['lastMessage'] ?? 'Tap to message...').toString();
        final date =
            (data?['lastMessageAt'] as Timestamp?)?.toDate() ??
            (data?['updatedAt'] as Timestamp?)?.toDate();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black45, fontSize: 13),
              ),
            ),
            if (date != null)
              Text(
                '  ${_formatMessageTime(date)}',
                style: const TextStyle(color: Colors.black26, fontSize: 11),
              ),
          ],
        );
      },
    );
  }
}

String _formatMessageTime(DateTime? date) {
  if (date == null) return '';
  final now = DateTime.now();
  final sameDay =
      now.year == date.year && now.month == date.month && now.day == date.day;
  return sameDay
      ? DateFormat('h:mm a').format(date)
      : DateFormat('MMM d').format(date);
}
