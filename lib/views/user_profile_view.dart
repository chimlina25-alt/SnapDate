import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../service/friend_service.dart';
import '../utils/chat_navigation.dart';

class UserProfileView extends StatefulWidget {
  final AppUser profile;

  const UserProfileView({super.key, required this.profile});

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  final FriendService _friendService = FriendService();
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isRemoving = false;

  Future<void> _unfriend() async {
    if (_uid.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Unfriend user'),
          content: Text(
            'Remove ${widget.profile.username} from your friends list?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Unfriend'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    setState(() => _isRemoving = true);
    try {
      await _friendService.unfriend(uid: _uid, friendUid: widget.profile.uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.profile.username} has been removed.')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not unfriend: $error')));
    } finally {
      if (mounted) setState(() => _isRemoving = false);
    }
  }

  void _openChat() {
    if (_uid.isEmpty) return;
    ChatNavigation.toChatRoom(
      context,
      currentUid: _uid,
      recipientUser: widget.profile,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFA3D2CA),
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          children: [
            CircleAvatar(
              radius: 64,
              backgroundColor: const Color(0xFFFCD7D9),
              child: ClipOval(
                child: SizedBox(
                  width: 128,
                  height: 128,
                  child: CachedNetworkImage(
                    imageUrl: widget.profile.profileImageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.person,
                      size: 64,
                      color: Colors.black45,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.profile.username,
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (widget.profile.email.isNotEmpty)
              Text(
                widget.profile.email,
                style: const TextStyle(color: Colors.black54),
              ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE26A97),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: _openChat,
                    child: const Text('Message'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                    onPressed: _isRemoving ? null : _unfriend,
                    child: _isRemoving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: Colors.redAccent,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Unfriend',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'This profile shows the friend detail and direct actions for messaging or removing the friendship connection.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
