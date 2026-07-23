import '../models/noti_model.dart';
import 'noti_repository.dart';

class NotiController {
  NotiController({required this.userId, required this.repository});

  final String userId;
  final NotiRepository repository;

  Stream<List<NotiItem>> watchNotifications({int limit = 50}) {
    return repository.watchNotifications(userId, limit: limit);
  }

  Stream<int> watchUnreadCount({int maxCount = 100}) {
    return repository.watchUnreadCount(userId, maxCount: maxCount);
  }

  Future<void> markAsRead(String notificationId) {
    return repository.markAsRead(userId, notificationId);
  }

  Future<void> markAllAsRead() {
    return repository.markAllAsRead(userId);
  }
}
