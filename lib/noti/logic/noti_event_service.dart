import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/noti_model.dart';
import '../models/noti_reference.dart';

class NotiEventService {
  NotiEventService({
    FirebaseFirestore? firestore,
    this.usersCollection = 'users',
    this.notificationCollection = 'users_notification',
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final String usersCollection;
  final String notificationCollection;

  Future<String?> createLikeNotification({
    required String recipientUserId,
    required String actorUserId,
    required String actorName,
    required String postId,
    String? thumbnailUrl,
  }) {
    return _createSocialNotification(
      recipientUserId: recipientUserId,
      actorUserId: actorUserId,
      type: NotiType.like,
      title: '좋아요',
      body: '${_normalizedActorName(actorName)}님이 회원님의 게시글을 좋아합니다.',
      postId: postId,
      thumbnailUrl: thumbnailUrl,
    );
  }

  Future<String?> createScrapNotification({
    required String recipientUserId,
    required String actorUserId,
    required String actorName,
    required String postId,
    String? thumbnailUrl,
  }) {
    return _createSocialNotification(
      recipientUserId: recipientUserId,
      actorUserId: actorUserId,
      type: NotiType.scrap,
      title: '스크랩',
      body: '${_normalizedActorName(actorName)}님이 회원님의 게시글을 스크랩했습니다.',
      postId: postId,
      thumbnailUrl: thumbnailUrl,
    );
  }

  Future<String?> createCommentNotification({
    required String recipientUserId,
    required String actorUserId,
    required String actorName,
    required String postId,
    String? thumbnailUrl,
  }) {
    return _createSocialNotification(
      recipientUserId: recipientUserId,
      actorUserId: actorUserId,
      type: NotiType.comment,
      title: '새 댓글',
      body: '${_normalizedActorName(actorName)}님이 회원님의 게시글에 댓글을 남겼습니다.',
      postId: postId,
      thumbnailUrl: thumbnailUrl,
    );
  }

  Future<String> createStampNotification({
    required String userId,
    required String placeName,
    required String stampId,
  }) {
    final normalizedPlaceName = _requiredText(
      placeName,
      parameterName: 'placeName',
      message: '업체명이 비어 있습니다.',
    );
    return _createNotification(
      userId: userId,
      type: NotiType.stamp,
      title: '스탬프 발급 완료',
      body: '$normalizedPlaceName 스탬프가 발급되었습니다.',
      referenceType: NotiReferenceType.stamp,
      referenceId: stampId,
    );
  }

  Future<String> createPointNotification({
    required String userId,
    required int amount,
    required String transactionId,
    String? description,
  }) {
    if (amount == 0) {
      throw ArgumentError.value(amount, 'amount', '포인트 증감량은 0일 수 없습니다.');
    }

    final isEarned = amount > 0;
    final normalizedDescription = description?.trim();
    final amountText = amount.abs().toString();
    return _createNotification(
      userId: userId,
      type: NotiType.point,
      title: isEarned ? '포인트 적립' : '포인트 사용',
      body: normalizedDescription?.isNotEmpty == true
          ? normalizedDescription!
          : '$amountText 포인트가 ${isEarned ? '적립' : '사용'}되었습니다.',
      referenceType: NotiReferenceType.pointTransaction,
      referenceId: transactionId,
    );
  }

  Future<String?> _createSocialNotification({
    required String recipientUserId,
    required String actorUserId,
    required NotiType type,
    required String title,
    required String body,
    required String postId,
    String? thumbnailUrl,
  }) async {
    final recipientId = _requiredText(
      recipientUserId,
      parameterName: 'recipientUserId',
      message: '알림 수신자 ID가 비어 있습니다.',
    );
    final actorId = _requiredText(
      actorUserId,
      parameterName: 'actorUserId',
      message: '알림 발생자 ID가 비어 있습니다.',
    );
    if (recipientId == actorId) return null;

    return _createNotification(
      userId: recipientId,
      type: type,
      title: title,
      body: body,
      referenceType: NotiReferenceType.post,
      referenceId: postId,
      thumbnailUrl: thumbnailUrl,
    );
  }

  Future<String> _createNotification({
    required String userId,
    required NotiType type,
    required String title,
    required String body,
    required NotiReferenceType referenceType,
    required String referenceId,
    String? thumbnailUrl,
  }) async {
    final normalizedUserId = _requiredText(
      userId,
      parameterName: 'userId',
      message: '사용자 ID가 비어 있습니다.',
    );
    final normalizedReferenceId = _requiredText(
      referenceId,
      parameterName: 'referenceId',
      message: '알림 참조 ID가 비어 있습니다.',
    );
    final normalizedThumbnailUrl = thumbnailUrl?.trim();

    final document = _firestore
        .collection(usersCollection)
        .doc(normalizedUserId)
        .collection(notificationCollection)
        .doc();

    await document.set({
      'type': type.name,
      'title': title,
      'body': body,
      'refType': referenceType.value,
      'refId': normalizedReferenceId,
      if (normalizedThumbnailUrl?.isNotEmpty == true)
        'thumbnailUrl': normalizedThumbnailUrl,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return document.id;
  }

  String _normalizedActorName(String actorName) {
    final normalized = actorName.trim();
    return normalized.isEmpty ? '누군가' : normalized;
  }

  String _requiredText(
    String value, {
    required String parameterName,
    required String message,
  }) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(value, parameterName, message);
    }
    return normalized;
  }
}
