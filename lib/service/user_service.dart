import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_user.dart';
import 'cloudinary_service.dart';

class UserService {
  UserService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    CloudinaryService? cloudinaryService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _cloudinaryService = cloudinaryService ?? CloudinaryService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final CloudinaryService _cloudinaryService;

  DocumentReference<Map<String, dynamic>> userRef(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  Stream<AppUser?> streamUser(String uid) {
    return userRef(
      uid,
    ).snapshots().map((doc) => doc.exists ? AppUser.fromDoc(doc) : null);
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
      'profileImageUrl':
          doc.data()?['profileImageUrl'] ?? doc.data()?['avatarUrl'] ?? '',
      'profileImagePath':
          doc.data()?['profileImagePath'] ??
          doc.data()?['profileImageUrl'] ??
          doc.data()?['avatarUrl'] ??
          '',
      'profileImageStoragePath':
          doc.data()?['profileImageStoragePath'] ??
          doc.data()?['profileImagePath'] ??
          doc.data()?['profileImageUrl'] ??
          doc.data()?['avatarUrl'] ??
          '',
      'avatarUrl':
          doc.data()?['avatarUrl'] ?? doc.data()?['profileImageUrl'] ?? '',
      'bio': doc.data()?['bio'] ?? '',
      'highlightUrls':
          doc.data()?['highlightUrls'] ?? doc.data()?['highlights'] ?? [],
      'highlights':
          doc.data()?['highlights'] ?? doc.data()?['highlightUrls'] ?? [],
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
    XFile? profileImageXFile,
    List<String>? highlightUrls,
  }) async {
    String? profileImageUrl;
    if (profileImage != null || profileImageXFile != null) {
      final imageFile = profileImage ?? File(profileImageXFile!.path);
      profileImageUrl = await _cloudinaryService.uploadImage(
        imageFile,
        isAvatar: true,
      );

      if (profileImageUrl == null || profileImageUrl.isEmpty) {
        throw Exception('Cloudinary profile image upload failed.');
      }
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
      data['profileImageStoragePath'] = profileImageUrl;
    }
    if (highlightUrls != null) {
      data['highlightUrls'] = highlightUrls;
      data['highlights'] = highlightUrls;
    }
    await userRef(uid).set(data, SetOptions(merge: true));
    await _auth.currentUser?.updateDisplayName(username);
  }

  Future<String> updateProfilePicture({
    required String uid,
    required File avatarFile,
  }) async {
    final profileImageUrl = await _cloudinaryService.uploadImage(
      avatarFile,
      isAvatar: true,
    );

    if (profileImageUrl == null || profileImageUrl.isEmpty) {
      throw Exception('Cloudinary profile image upload failed.');
    }

    await userRef(uid).set({
      'profileImageUrl': profileImageUrl,
      'avatarUrl': profileImageUrl,
      'profileImagePath': profileImageUrl,
      'profileImageStoragePath': profileImageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return profileImageUrl;
  }
}
