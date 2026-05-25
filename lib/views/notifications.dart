import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/friend_request_model.dart';
import '../service/friend_service.dart';
import '../service/notification_service.dart';
import '../service/user_service.dart';
import '../utils/app_image.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final notificationService = NotificationService();

    if (uid.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('Please sign in to view notifications.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<List<FriendRequestModel>>(
        stream: notificationService.streamFriendRequests(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Could not load notifications: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black45),
              ),
            );
          }

          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 65,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "No notifications available.",
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      color: Colors.black38,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            itemCount: requests.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return _FriendRequestTile(request: requests[index]);
            },
          );
        },
      ),
    );
  }
}

class _FriendRequestTile extends StatefulWidget {
  final FriendRequestModel request;

  const _FriendRequestTile({required this.request});

  @override
  State<_FriendRequestTile> createState() => _FriendRequestTileState();
}

class _FriendRequestTileState extends State<_FriendRequestTile> {
  final FriendService _friendService = FriendService();
  final UserService _userService = UserService();
  bool _isSaving = false;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _confirm(AppUser sender) async {
    await _runAction(() async {
      final current = await _userService.userRef(_uid).get();
      if (!current.exists) return;
      await _friendService.acceptRequest(
        uid: _uid,
        currentUser: AppUser.fromDoc(current),
        fromUid: widget.request.senderId,
        requestData: {
          'email': sender.email,
          'username': sender.username,
          'profileImagePath': sender.profileImageUrl,
          'profileImageUrl': sender.profileImageUrl,
          'avatarUrl': sender.profileImageUrl,
        },
      );
    });
  }

  Future<void> _reject() async {
    await _runAction(
      () => _friendService.rejectRequest(
        uid: _uid,
        fromUid: widget.request.senderId,
      ),
    );
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() => _isSaving = true);
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update request: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _userService.userRef(widget.request.senderId).get(),
      builder: (context, snapshot) {
        final sender = snapshot.data?.exists == true
            ? AppUser.fromDoc(snapshot.data!)
            : null;
        final imageProvider = appImageProvider(sender?.profileImageUrl);

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFFCD7D9),
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? const Icon(Icons.person, color: Colors.black45)
                : null,
          ),
          title: Text(
            sender?.username ?? 'SnapDate User',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: const Text('sent you a friend request'),
          trailing: _isSaving
              ? const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Wrap(
                  spacing: 6,
                  children: [
                    TextButton(
                      onPressed: sender == null ? null : () => _confirm(sender),
                      child: const Text('Confirm'),
                    ),
                    TextButton(
                      onPressed: _reject,
                      child: const Text(
                        'Reject',
                        style: TextStyle(color: Colors.black45),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
