import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../service/chat_service.dart';
import '../service/friend_service.dart';
import '../utils/app_image.dart';

class ShareMemoryView extends StatefulWidget {
  final String mediaUrl;

  const ShareMemoryView({super.key, required this.mediaUrl});

  @override
  State<ShareMemoryView> createState() => _ShareMemoryViewState();
}

class _ShareMemoryViewState extends State<ShareMemoryView> {
  final FriendService _friendService = FriendService();
  final ChatService _chatService = ChatService();
  final Set<String> _selectedFriendIds = {};
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isSending = false;

  Future<void> _sendSharedMemory() async {
    if (_selectedFriendIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one friend to share with.'),
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await Future.wait(
        _selectedFriendIds.map((friendId) {
          return _chatService.sendExistingImage(
            fromUid: _uid,
            toUid: friendId,
            imageUrl: widget.mediaUrl,
          );
        }),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Memory shared to selected friends.')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not share memory: $error')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_uid.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Share Memory')),
        body: const Center(child: Text('Please sign in to share memories.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Friends to Share'),
        backgroundColor: const Color(0xFFA3D2CA),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<AppUser>>(
              stream: _friendService.streamFriends(_uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text('Could not load friends: ${snapshot.error}'),
                    ),
                  );
                }

                final friends = snapshot.data ?? [];
                if (friends.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'You have no friends yet to share this memory with.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: friends.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    return CheckboxListTile(
                      value: _selectedFriendIds.contains(friend.uid),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedFriendIds.add(friend.uid);
                          } else {
                            _selectedFriendIds.remove(friend.uid);
                          }
                        });
                      },
                      title: Text(friend.username),
                      subtitle: Text(friend.email),
                      secondary: CircleAvatar(
                        backgroundColor: const Color(0xFFFCD7D9),
                        backgroundImage: appImageProvider(
                          friend.profileImageUrl,
                        ),
                        child: appImageProvider(friend.profileImageUrl) == null
                            ? const Icon(Icons.person, color: Colors.black45)
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(18),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE26A97),
                ),
                onPressed: _isSending ? null : _sendSharedMemory,
                child: _isSending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Send to Selected Friends'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
