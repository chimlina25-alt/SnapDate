import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/friend_request_model.dart';

class NotificationService {
  NotificationService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseMessaging? messaging,
  })  : _auth = auth ?? FirebaseAuth.instance,
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
}
