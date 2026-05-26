import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/friend_request_model.dart';
import 'chat_service.dart';

class FriendService {
  FriendService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<AppUser>> streamFriends(String uid) {
    return _firestore
        .collection('friends')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          final docs = snap.docs.toList();
          docs.sort((a, b) {
            final aTime = (a.data()['addedAt'] ?? a.data()['createdAt']) as Timestamp?;
            final bTime = (b.data()['addedAt'] ?? b.data()['createdAt']) as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });
          return docs.map((doc) => AppUser.fromDoc(doc)).toList();
        });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamIncomingRequests(String uid) {
    return _firestore
        .collection('friend_requests')
        .where('receiverId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Stream<List<FriendRequestModel>> streamPendingRequests(String uid) {
    return streamIncomingRequests(uid).map(
      (snap) => snap.docs.map(FriendRequestModel.fromDoc).toList(),
    );
  }

  Future<void> sendRequest({
    required String fromUid,
    required AppUser fromUser,
    required AppUser toUser,
  }) async {
    final requestId = requestDocumentId(fromUid, toUser.uid);
    final ref = _firestore.collection('friend_requests').doc(requestId);
    final request = FriendRequestModel(
      id: requestId,
      senderId: fromUid,
      receiverId: toUser.uid,
      status: FriendRequestStatus.pending,
    ).toMap();
    await ref.set({
      ...request,
      'fromUid': fromUid,
      'toUid': toUser.uid,
      'senderId': fromUid,
      'receiverId': toUser.uid,
      'username': fromUser.username,
      'profileImageUrl': fromUser.profileImageUrl,
      'profileImagePath': fromUser.profileImageUrl,
      'avatarUrl': fromUser.profileImageUrl,
      'email': fromUser.email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> acceptRequest({
    required String uid,
    required AppUser currentUser,
    required String fromUid,
    required Map<String, dynamic> requestData,
  }) async {
    final batch = _firestore.batch();
    final myFriend = _firestore.collection('friends').doc(friendDocumentId(uid, fromUid));
    final theirFriend = _firestore.collection('friends').doc(friendDocumentId(fromUid, uid));
    final requestRef =
        _firestore.collection('friend_requests').doc(requestDocumentId(fromUid, uid));
    final chatId = ChatService.getChatId(uid, fromUid);
    final chatRef = _firestore.collection('chat_rooms').doc(chatId);
    final members = [uid, fromUid]..sort();

    batch.set(myFriend, {
      'uid': fromUid,
      'userId': uid,
      'friendId': fromUid,
      'email': requestData['email'] ?? '',
      'username': requestData['username'] ?? 'SnapDate User',
      'usernameLower': (requestData['username'] ?? 'SnapDate User').toString().toLowerCase(),
      'profileImageUrl': requestData['profileImageUrl'] ?? requestData['avatarUrl'] ?? '',
      'profileImagePath': requestData['profileImagePath'] ??
          requestData['profileImageUrl'] ??
          requestData['avatarUrl'] ??
          '',
      'avatarUrl': requestData['profileImageUrl'] ?? requestData['avatarUrl'] ?? '',
      'addedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(theirFriend, {
      'uid': uid,
      'userId': fromUid,
      'friendId': uid,
      'email': currentUser.email,
      'username': currentUser.username,
      'usernameLower': currentUser.usernameLower,
      'profileImageUrl': currentUser.profileImageUrl,
      'profileImagePath': currentUser.profileImageUrl,
      'avatarUrl': currentUser.profileImageUrl,
      'addedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(chatRef, {
      'members': members,
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderId': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.update(requestRef, {
      'status': 'accepted',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> rejectRequest({
    required String uid,
    required String fromUid,
  }) async {
    await _firestore
        .collection('friend_requests')
        .doc(requestDocumentId(fromUid, uid))
        .update({
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static String requestDocumentId(String fromUid, String toUid) => '${fromUid}_$toUid';

  static String friendDocumentId(String uid, String friendId) => '${uid}_$friendId';
}
