import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/noti_model.dart';

abstract interface class NotiRepository {
  Stream<List<NotiItem>> watchNotifications(String userId, {int limit = 50});

  Stream<int> watchUnreadCount(String userId, {int maxCount = 100});

  Future<void> markAsRead(String userId, String notificationId);

  Future<void> markAllAsRead(String userId);
}

class FirestoreNotiRepository implements NotiRepository {
  FirestoreNotiRepository({
    FirebaseFirestore? firestore,
    this.usersCollection = 'users',
    this.notificationCollection = 'users_notification',
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  static const int _writeBatchSize = 400;

  final FirebaseFirestore _firestore;
  final String usersCollection;
  final String notificationCollection;

  CollectionReference<Map<String, dynamic>> _notifications(String userId) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      throw ArgumentError.value(userId, 'userId', '사용자 ID가 비어 있습니다.');
    }

    return _firestore
        .collection(usersCollection)
        .doc(normalizedUserId)
        .collection(notificationCollection);
  }

  @override
  Stream<List<NotiItem>> watchNotifications(String userId, {int limit = 50}) {
    if (limit <= 0) {
      throw ArgumentError.value(limit, 'limit', '1 이상이어야 합니다.');
    }

    return _notifications(userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => List<NotiItem>.unmodifiable(
            snapshot.docs.map(NotiItem.fromFirestore),
          ),
        );
  }

  @override
  Stream<int> watchUnreadCount(String userId, {int maxCount = 100}) {
    if (maxCount <= 0) {
      throw ArgumentError.value(maxCount, 'maxCount', '1 이상이어야 합니다.');
    }

    return _notifications(userId)
        .where('isRead', isEqualTo: false)
        .limit(maxCount)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Future<void> markAsRead(String userId, String notificationId) async {
    final normalizedId = notificationId.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError.value(
        notificationId,
        'notificationId',
        '알림 ID가 비어 있습니다.',
      );
    }

    await _notifications(userId).doc(normalizedId).update({'isRead': true});
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    final collection = _notifications(userId);

    while (true) {
      final snapshot = await collection
          .where('isRead', isEqualTo: false)
          .limit(_writeBatchSize)
          .get();
      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final document in snapshot.docs) {
        batch.update(document.reference, {'isRead': true});
      }
      await batch.commit();
    }
  }
}
