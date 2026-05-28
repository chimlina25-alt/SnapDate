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
import '../service/user_service.dart';
import '../service/memory_service.dart';
import 'user_profile_view.dart';

/// Unified ChatRoomScreen - SINGLE entry point for all chat interactions.
/// Both direct chat list taps and profile "Message" buttons route here.
/// Ensures consistent UI, styling, and behavior across all chat entry points.
///
/// Parameters:
///   - chatRoomId: Deterministic chat room ID (e.g., "uid1_uid2" sorted)
///   - recipientId: UID of the recipient (used to fetch recipient details)
class ChatRoomScreen extends StatefulWidget {
  final String chatRoomId;
  final String recipientId;

  const ChatRoomScreen({
    super.key,
    required this.chatRoomId,
    required this.recipientId,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final _messagesController = ScrollController();
  final _picker = ImagePicker();
  final UserService _userService = UserService();
  final ChatService _chatService = ChatService();
  final MemoryService _memoryService = MemoryService();

  bool _isSending = false;
  ChatMessage? _editingMessage;
  AppUser? _recipientUser;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadRecipientDetails();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messagesController.dispose();
    super.dispose();
  }

  /// Fetch recipient user details for header display
  Future<void> _loadRecipientDetails() async {
    try {
      final doc = await _userService.userRef(widget.recipientId).get();
      if (doc.exists) {
        final user = AppUser.fromDoc(doc);
        setState(() => _recipientUser = user);
      }
    } catch (e) {
      debugPrint('Failed to load recipient details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFA3D2CA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: _recipientUser != null
            ? Row(
                children: [
                  _buildAvatar(_recipientUser!.profileImageUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _recipientUser!.username,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            : const CircularProgressIndicator(strokeWidth: 2),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Message Stream
          Expanded(
            child: FutureBuilder<void>(
              future: _chatService.createRoom(
                firstUid: _uid,
                secondUid: widget.recipientId,
              ),
              builder: (context, setupSnapshot) {
                if (setupSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                return StreamBuilder<List<ChatMessage>>(
                  stream: _chatService.streamMessages(
                    widget.chatRoomId,
                    currentUid: _uid,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading messages: ${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    final messages = snapshot.data ?? [];
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_messagesController.hasClients &&
                          messages.isNotEmpty) {
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
                        final isMine = message.senderId == _uid;
                        return _buildMessageBubble(message, isMine);
                      },
                    );
                  },
                );
              },
            ),
          ),
          // Message Composer
          _buildMessageComposer(),
        ],
      ),
    );
  }

  /// Builds a single message bubble with edit/delete options for own messages
  Widget _buildMessageBubble(ChatMessage message, bool isMine) {
    final isDeleted = message.isDeleted || message.isDeletedForEveryone;
    final isEdited = message.isEdited && !isDeleted;
    final bubbleColor = isDeleted
        ? const Color(0xFFEEEEEE)
        : isMine
        ? const Color(0xFFFCD7D9)
        : const Color(0xFFEDF6F4);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: isMine && !isDeleted
            ? () => _showDeleteOptions(message)
            : null,
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Three-dot menu for own messages
            if (isMine && !isDeleted)
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
                    } else if (value == 'deleteMe') {
                      _deleteMessageForMe(message);
                    } else if (value == 'deleteAll') {
                      _deleteMessageForEveryone(message);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(
                      value: 'deleteMe',
                      child: Text('Delete for Me'),
                    ),
                    PopupMenuItem(
                      value: 'deleteAll',
                      child: Text('Delete for Everyone'),
                    ),
                  ],
                ),
              ),
            // Message bubble
            Container(
              constraints: const BoxConstraints(maxWidth: 260),
              margin: const EdgeInsets.symmetric(vertical: 5),
              padding: EdgeInsets.all(message.imageUrl.isEmpty ? 12 : 6),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: isMine
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
                    if (message.imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: appImage(message.imageUrl, fit: BoxFit.cover),
                      )
                    else
                      Text(
                        message.text,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                    if (message.text.isNotEmpty && message.imageUrl.isNotEmpty)
                      const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                        ),
                        if (isEdited) ...[
                          const SizedBox(width: 6),
                          const Text(
                            '(edited)',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
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
      ),
    );
  }

  /// Message composer with edit mode indicator
  Widget _buildMessageComposer() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edit mode indicator
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
            // Input row
            Row(
              children: [
                IconButton(
                  tooltip: 'Send memory',
                  icon: const Icon(Icons.photo_library_outlined),
                  onPressed: _isSending ? null : () => _showMemoryPicker(),
                ),
                IconButton(
                  tooltip: 'Send image',
                  icon: const Icon(Icons.attach_file),
                  onPressed: _isSending ? null : () => _pickImage(),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: _editingMessage != null
                          ? 'Edit message...'
                          : 'Message',
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
                  icon: Icon(
                    _editingMessage != null ? Icons.check : Icons.send,
                    color: const Color(0xFFE26A97),
                  ),
                  tooltip: _editingMessage != null
                      ? 'Save edit'
                      : 'Send message',
                  onPressed: _isSending ? null : () => _sendMessage(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Show delete options dialog
  void _showDeleteOptions(ChatMessage message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete message'),
          content: const Text('How would you like to delete this message?'),
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

  /// Delete message for current user only (adds UID to deletedBy array)
  Future<void> _deleteMessageForMe(ChatMessage message) async {
    setState(() => _isSending = true);
    try {
      await _chatService.deleteMessageForMe(
        widget.chatRoomId,
        message.id,
        _uid,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message removed from your view.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  /// Delete message for everyone
  Future<void> _deleteMessageForEveryone(ChatMessage message) async {
    setState(() => _isSending = true);
    try {
      await _chatService.deleteMessageForEveryone(
        widget.chatRoomId,
        message.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message deleted for everyone.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  /// Send text message (or edit if in edit mode)
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (_editingMessage != null) {
      await _performEdit(text);
      return;
    }

    _messageController.clear();
    setState(() => _isSending = true);

    try {
      await _chatService.sendText(
        fromUid: _uid,
        toUid: widget.recipientId,
        text: text,
      );
    } catch (e) {
      if (!mounted) return;
      _messageController.text = text; // Restore on error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  /// Edit existing message
  Future<void> _performEdit(String newText) async {
    final editing = _editingMessage;
    if (editing == null) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await _chatService.editMessage(widget.chatRoomId, editing.id, newText);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Message updated.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to edit: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _editingMessage = null;
          _isSending = false;
        });
      }
    }
  }

  /// Start editing a message
  void _startEditingMessage(ChatMessage message) {
    if (message.isDeleted || message.isDeletedForEveryone) return;
    _messageController.text = message.text;
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
    setState(() => _editingMessage = message);
  }

  /// Cancel editing
  void _cancelEditing() {
    _messageController.clear();
    setState(() => _editingMessage = null);
  }

  /// Pick image from gallery
  Future<void> _pickImage() async {
    final selected = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 65,
    );
    if (selected == null) return;

    setState(() => _isSending = true);
    try {
      await _chatService.sendImage(
        fromUid: _uid,
        toUid: widget.recipientId,
        xFile: selected,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send image: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  /// Show memory picker for sending stored memories
  Future<void> _showMemoryPicker() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return StreamBuilder<List<Memory>>(
          stream: _memoryService.streamMemories(_uid, limit: 30),
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
                child: Center(child: Text('No memories to share.')),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: memories.length,
              itemBuilder: (context, index) {
                final memory = memories[index];
                return GestureDetector(
                  onTap: () async {
                    Navigator.pop(context);
                    setState(() => _isSending = true);
                    try {
                      await _chatService.sendExistingImage(
                        fromUid: _uid,
                        toUid: widget.recipientId,
                        imageUrl: memory.mediaUrl,
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to send memory: $e')),
                      );
                    } finally {
                      if (mounted) setState(() => _isSending = false);
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: appImage(memory.mediaUrl, fit: BoxFit.cover),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Format timestamp to readable time
  String _formatTime(DateTime? date) {
    if (date == null) return '';
    return DateFormat('HH:mm').format(date);
  }

  /// Build avatar widget
  Widget _buildAvatar(String imageUrl) {
    final provider = appImageProvider(imageUrl);
    return CircleAvatar(
      radius: 20,
      backgroundColor: const Color(0xFFFCD7D9),
      backgroundImage: provider,
      child: provider == null
          ? const Icon(Icons.person, color: Colors.black45, size: 20)
          : null,
    );
  }
}
