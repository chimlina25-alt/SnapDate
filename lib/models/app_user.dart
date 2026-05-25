import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String username;
  final String usernameLower;
  final String profileImageUrl;
  final String bio;
  final List<String> highlightUrls;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.username,
    required this.usernameLower,
    required this.profileImageUrl,
    required this.bio,
    required this.highlightUrls,
    this.createdAt,
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final username = (data['username'] ?? 'SnapDate User').toString();
    return AppUser(
      uid: (data['uid'] ?? data['friendId'] ?? doc.id).toString(),
      email: (data['email'] ?? '').toString(),
      username: username,
      usernameLower: (data['usernameLower'] ?? username.toLowerCase()).toString(),
      profileImageUrl:
          (data['profileImagePath'] ??
                  data['profileImageUrl'] ??
                  data['avatarUrl'] ??
                  '')
              .toString(),
      bio: (data['bio'] ?? '').toString(),
      highlightUrls: List<String>.from(data['highlightUrls'] ?? data['highlights'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'usernameLower': usernameLower,
      'profileImageUrl': profileImageUrl,
      'avatarUrl': profileImageUrl,
      'profileImagePath': profileImageUrl,
      'bio': bio,
      'highlightUrls': highlightUrls,
      'highlights': highlightUrls,
      'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
    };
  }
}
