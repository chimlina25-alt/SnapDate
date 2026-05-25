import '../models/app_user.dart';
import '../models/friend_request_model.dart';
import '../service/friend_service.dart';

class FriendRepository {
  FriendRepository({FriendService? service})
      : _service = service ?? FriendService();

  final FriendService _service;

  Stream<List<AppUser>> streamFriends(String uid) {
    return _service.streamFriends(uid);
  }

  Stream<List<FriendRequestModel>> streamPendingRequests(String uid) {
    return _service.streamPendingRequests(uid);
  }

  Future<void> sendRequest({
    required String fromUid,
    required AppUser fromUser,
    required AppUser toUser,
  }) {
    return _service.sendRequest(
      fromUid: fromUid,
      fromUser: fromUser,
      toUser: toUser,
    );
  }
}
