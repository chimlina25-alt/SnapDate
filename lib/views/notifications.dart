import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/friend_request_model.dart';
import '../models/memory_notification_model.dart';
import '../service/friend_service.dart';
import '../service/notification_service.dart';
import '../service/user_service.dart';
import '../utils/app_image.dart';

class NotificationsView extends StatelessWidget {
  final ValueChanged<AppUser>? onFriendAccepted;

  const NotificationsView({super.key, this.onFriendAccepted});

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
      body: StreamBuilder<List<dynamic>>(
        stream: notificationService.streamAllNotifications(uid),
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

          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
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
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              if (notification is FriendRequestModel) {
                return _FriendRequestTile(
                  request: notification,
                  onFriendAccepted: onFriendAccepted,
                );
              }
              if (notification is MemoryNotificationModel) {
                return _MemoryNotificationTile(notification: notification);
              }
              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}

class _FriendRequestTile extends StatefulWidget {
  final FriendRequestModel request;
  final ValueChanged<AppUser>? onFriendAccepted;

  const _FriendRequestTile({required this.request, this.onFriendAccepted});

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

      if (widget.onFriendAccepted != null) {
        widget.onFriendAccepted!(sender);
      }
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update request: $e')));
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

class _MemoryNotificationTile extends StatelessWidget {
  final MemoryNotificationModel notification;

  const _MemoryNotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final createdAtText = notification.createdAt != null
        ? MaterialLocalizations.of(
            context,
          ).formatFullDate(notification.createdAt!)
        : 'A year ago';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      leading: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: const Color(0xFFF8EEE8),
          borderRadius: BorderRadius.circular(14),
          image: notification.imageUrl.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(notification.imageUrl),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: notification.imageUrl.isEmpty
            ? const Icon(Icons.photo, color: Colors.black38)
            : null,
      ),
      title: Text(
        'Memory from a year ago',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            notification.caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 6),
          Text(
            createdAtText,
            style: const TextStyle(fontSize: 12, color: Colors.black38),
          ),
        ],
      ),
      trailing: TextButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('View memory feature coming soon.')),
          );
        },
        child: const Text('View'),
      ),
    );
  }
}
