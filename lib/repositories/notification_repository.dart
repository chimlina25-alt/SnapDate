import '../models/friend_request_model.dart';
import '../service/notification_service.dart';

class NotificationRepository {
  NotificationRepository({NotificationService? service})
      : _service = service ?? NotificationService();

  final NotificationService _service;

  Stream<List<FriendRequestModel>> streamFriendRequests(String uid) {
    return _service.streamFriendRequests(uid);
  }
}
