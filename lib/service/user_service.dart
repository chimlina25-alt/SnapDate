import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import 'storage_service.dart';

class UserService {
  UserService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    StorageService? storageService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storageService = storageService ?? StorageService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final StorageService _storageService;

  DocumentReference<Map<String, dynamic>> userRef(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  Stream<AppUser?> streamUser(String uid) {
    return userRef(uid).snapshots().map((doc) => doc.exists ? AppUser.fromDoc(doc) : null);
  }

  Future<void> ensureUserDocument(User user, {String? username}) async {
    final doc = await userRef(user.uid).get();
    final displayName = username?.trim().isNotEmpty == true
        ? username!.trim()
        : user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : user.email?.split('@').first ?? 'SnapDate User';

    await userRef(user.uid).set({
      'email': user.email ?? '',
      'username': displayName,
      'usernameLower': displayName.toLowerCase(),
      'emailLower': (user.email ?? '').toLowerCase(),
      'profileImageUrl': doc.data()?['profileImageUrl'] ?? doc.data()?['avatarUrl'] ?? '',
      'profileImagePath': doc.data()?['profileImagePath'] ??
          doc.data()?['profileImageUrl'] ??
          doc.data()?['avatarUrl'] ??
          '',
      'avatarUrl': doc.data()?['avatarUrl'] ?? doc.data()?['profileImageUrl'] ?? '',
      'bio': doc.data()?['bio'] ?? '',
      'highlightUrls': doc.data()?['highlightUrls'] ?? doc.data()?['highlights'] ?? [],
      'highlights': doc.data()?['highlights'] ?? doc.data()?['highlightUrls'] ?? [],
      if (!doc.exists) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<AppUser>> searchUsers(String query, String currentUid) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return [];

    final usernameSnap = await _firestore
        .collection('users')
        .orderBy('usernameLower')
        .startAt([normalized])
        .endAt(['$normalized\uf8ff'])
        .limit(10)
        .get();
    final emailSnap = await _firestore
        .collection('users')
        .orderBy('emailLower')
        .startAt([normalized])
        .endAt(['$normalized\uf8ff'])
        .limit(10)
        .get();

    final docs = {
      for (final doc in [...usernameSnap.docs, ...emailSnap.docs])
        if (doc.id != currentUid) doc.id: doc,
    };
    return docs.values.map(AppUser.fromDoc).toList();
  }

  Future<void> updateProfile({
    required String uid,
    required String username,
    required String bio,
    File? profileImage,
    List<String>? highlightUrls,
  }) async {
    String? profileImageUrl;
    if (profileImage != null) {
      final upload = await _storageService.uploadImage(
        ownerId: uid,
        file: profileImage,
        folder: 'profile_images',
      );
      profileImageUrl = upload.url;
    }

    final data = <String, dynamic>{
      'username': username,
      'usernameLower': username.toLowerCase(),
      'bio': bio,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (profileImageUrl != null) {
      data['profileImageUrl'] = profileImageUrl;
      data['avatarUrl'] = profileImageUrl;
      data['profileImagePath'] = profileImageUrl;
    }
    if (highlightUrls != null) {
      data['highlightUrls'] = highlightUrls;
      data['highlights'] = highlightUrls;
    }
    await userRef(uid).set(data, SetOptions(merge: true));
    await _auth.currentUser?.updateDisplayName(username);
  }
}
