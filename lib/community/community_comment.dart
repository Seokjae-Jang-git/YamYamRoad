import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityComment {
  final String id;
  final String userId; // 🌟 authorId → userId
  final String authorNickname;
  final String? authorProfileImage;
  final String content;
  final String? parentId;
  final String? replyToNickname;
  final DateTime? createdAt;

  CommunityComment({
    required this.id,
    required this.userId,
    required this.authorNickname,
    this.authorProfileImage,
    required this.content,
    this.parentId,
    this.replyToNickname,
    this.createdAt,
  });

  factory CommunityComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityComment(
      id: doc.id,
      userId: (data['userId'] ?? '').toString(),
      authorNickname: (data['authorNickname'] ?? '익명').toString(),
      authorProfileImage: (data['authorProfileImage'] as String?)?.isNotEmpty == true
          ? data['authorProfileImage'] as String
          : null,
      content: (data['content'] ?? '').toString(),
      parentId: data['parentId'] as String?,
      replyToNickname: data['replyToNickname'] as String?,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'authorNickname': authorNickname,
      'authorProfileImage': authorProfileImage,
      'content': content,
      'parentId': parentId,
      'replyToNickname': replyToNickname,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
