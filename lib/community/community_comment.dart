import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityComment {
  final String id;
  final String authorId;
  final String authorNickname;
  final String? authorProfileImage;
  final String content;
  final String? parentId;       // null이면 원댓글, 값이 있으면 대댓글
  final String? replyToNickname; // 대댓글일 때 "누구에게" 답글인지 표시용
  final DateTime? createdAt;

  CommunityComment({
    required this.id,
    required this.authorId,
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
      authorId: data['authorId'] ?? '',
      authorNickname: data['authorNickname'] ?? '익명',
      authorProfileImage: data['authorProfileImage'],
      content: data['content'] ?? '',
      parentId: data['parentId'],
      replyToNickname: data['replyToNickname'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorNickname': authorNickname,
      'authorProfileImage': authorProfileImage,
      'content': content,
      'parentId': parentId,
      'replyToNickname': replyToNickname,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}