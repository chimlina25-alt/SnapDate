import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendRequestStatus { pending, accepted, rejected }

class FriendRequestModel {
  final String id;
  final String senderId;
  final String receiverId;
  final FriendRequestStatus status;
  final DateTime? timestamp;

  const FriendRequestModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    this.timestamp,
  });

  factory FriendRequestModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final statusName = (data['status'] ?? 'pending').toString();
    return FriendRequestModel(
      id: doc.id,
      senderId: (data['senderId'] ?? data['fromUid'] ?? '').toString(),
      receiverId: (data['receiverId'] ?? data['toUid'] ?? '').toString(),
      status: FriendRequestStatus.values.firstWhere(
        (status) => status.name == statusName,
        orElse: () => FriendRequestStatus.pending,
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ??
          (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'fromUid': senderId,
      'toUid': receiverId,
      'status': status.name,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
