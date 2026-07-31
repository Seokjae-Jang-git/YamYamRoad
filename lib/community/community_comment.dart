import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityComment {
  final String id;
  final String userId;
  final String nickname;
  final String? profileImage;
  final String content;
  final String? parentId;
  final String? replyToNickname;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int likeCount;
  final int reportCount;

  CommunityComment({
    required this.id,
    required this.userId,
    required this.nickname,
    this.profileImage,
    required this.content,
    this.parentId,
    this.replyToNickname,
    this.createdAt,
    this.updatedAt,
    this.likeCount = 0,
    this.reportCount = 0,
  });

  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  static int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return defaultValue;
  }

  factory CommunityComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityComment(
      id: doc.id,
      userId: (data['userId'] ?? '').toString(),
      nickname: (data['nickname'] ?? '익명').toString(),
      profileImage: (data['profileImageUrl'] as String?)?.isNotEmpty == true
          ? data['profileImageUrl'] as String
          : null,
      content: (data['content'] ?? '').toString(),
      parentId: data['parentId'] as String?,
      replyToNickname: data['replyToNickname'] as String?,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      likeCount: _toInt(data['likeCount']),
      reportCount: _toInt(data['reportCount']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'nickname': nickname,
      'profileImageUrl': profileImage,
      'content': content,
      'parentId': parentId,
      'replyToNickname': replyToNickname,
      'createdAt': FieldValue.serverTimestamp(),
      'likeCount': likeCount,
      'reportCount': reportCount,
    };
  }
}
