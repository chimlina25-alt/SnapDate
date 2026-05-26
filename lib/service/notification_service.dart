import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:rxdart/rxdart.dart';

import '../models/friend_request_model.dart';
import '../models/memory_notification_model.dart';

class NotificationService {
  NotificationService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseMessaging? messaging,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;

  Future<void> initialize() async {
    try {
      await _messaging.requestPermission();
      _auth.authStateChanges().listen((user) {
        if (user != null) {
          syncToken(user.uid);
        }
      });
      _messaging.onTokenRefresh.listen((token) {
        final uid = _auth.currentUser?.uid;
        if (uid != null) {
          _saveToken(uid, token);
        }
      });
    } catch (e) {
      print("NotificationService initialization ignored or failed: $e");
    }
  }

  Future<void> syncToken(String uid) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveToken(uid, token);
      }
    } catch (e) {
      print("FCM token sync ignored or failed: $e");
    }
  }

  Future<void> _saveToken(String uid, String token) {
    return _firestore.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<FriendRequestModel>> streamFriendRequests(String uid) {
    return _firestore
        .collection('friend_requests')
        .where('receiverId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(FriendRequestModel.fromDoc).toList());
  }

  Stream<List<MemoryNotificationModel>> streamMemoryAlerts(String uid) {
    final now = DateTime.now();
    final oneYearAgo = DateTime(now.year - 1, now.month, now.day);
    final startOfDay = DateTime(
      oneYearAgo.year,
      oneYearAgo.month,
      oneYearAgo.day,
    );
    final endOfDay = DateTime(
      oneYearAgo.year,
      oneYearAgo.month,
      oneYearAgo.day,
      23,
      59,
      59,
      999,
    );

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('memories')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(MemoryNotificationModel.fromDoc).toList());
  }

  Stream<List<dynamic>> streamAllNotifications(String uid) {
    return Rx.combineLatest2<
      List<FriendRequestModel>,
      List<MemoryNotificationModel>,
      List<dynamic>
    >(streamFriendRequests(uid), streamMemoryAlerts(uid), (
      friendRequests,
      memoryAlerts,
    ) {
      final allNotifications = <dynamic>[...friendRequests, ...memoryAlerts];
      allNotifications.sort((a, b) {
        final aTime = _notificationTimestamp(a);
        final bTime = _notificationTimestamp(b);
        return bTime.compareTo(aTime);
      });
      return allNotifications;
    });
  }

  DateTime _notificationTimestamp(dynamic notification) {
    if (notification is FriendRequestModel) {
      return notification.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    if (notification is MemoryNotificationModel) {
      return notification.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Stream<int> streamPendingNotificationCount(String uid) {
    return _firestore
        .collection('friend_requests')
        .where('receiverId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Stream<int> streamUnreadChatMessageCount(String uid) {
    return _firestore
        .collectionGroup('messages')
        .where('receiverId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}
