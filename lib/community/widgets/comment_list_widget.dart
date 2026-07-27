import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/emoticon/emoticon_span_builder.dart';
import '../community_comment.dart';

class CommentListWidget extends StatelessWidget {
  final String postId;
  final String currentUserId;
  final Function(CommunityComment) onStartReply;
  final Function(CommunityComment) onDeleteComment;

  const CommentListWidget({
    Key? key,
    required this.postId,
    required this.currentUserId,
    required this.onStartReply,
    required this.onDeleteComment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .orderBy('createdAt')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(color: Colors.black)),
          );
        }

        final allComments = snapshot.data!.docs.map((doc) => CommunityComment.fromFirestore(doc)).toList();
        final topLevel = allComments.where((c) => c.parentId == null).toList();
        final repliesByParent = <String, List<CommunityComment>>{};

        for (final c in allComments.where((c) => c.parentId != null)) {
          repliesByParent.putIfAbsent(c.parentId!, () => []).add(c);
        }

        if (topLevel.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text('첫 댓글을 남겨보세요!', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ),
          );
        }

        return Column(
          children: topLevel.map((comment) {
            final replies = repliesByParent[comment.id] ?? [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCommentTile(comment, isReply: false),
                ...replies.map((reply) => _buildCommentTile(reply, isReply: true)),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCommentTile(CommunityComment comment, {required bool isReply}) {
    final bool isMine = comment.userId == currentUserId;

    return Padding(
      padding: EdgeInsets.only(left: isReply ? 40 : 0, top: 12, bottom: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isReply)
            const Padding(
              padding: EdgeInsets.only(right: 6, top: 2),
              child: Icon(Icons.subdirectory_arrow_right, size: 16, color: Colors.grey),
            ),
          CircleAvatar(
            radius: isReply ? 14 : 16,
            backgroundColor: const Color(0xFFF5F5F5),
            backgroundImage: comment.authorProfileImage != null ? NetworkImage(comment.authorProfileImage!) : null,
            child: comment.authorProfileImage == null
                ? Icon(Icons.person_outline, size: isReply ? 14 : 16, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment.authorNickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 6),
                    if (comment.createdAt != null)
                      Text(_formatTime(comment.createdAt!), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 3),
                EmoticonRichContent(
                  content: comment.content,
                  emojiSize: 16,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  leadingSpans: comment.replyToNickname != null
                      ? [
                    TextSpan(
                      text: '@${comment.replyToNickname} ',
                      style: const TextStyle(color: Color(0xFFFF8A3D), fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ]
                      : const [],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => onStartReply(comment),
                      child: const Text('답글쓰기',
                          style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => onDeleteComment(comment),
                        child: const Text('삭제', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${time.month}/${time.day}';
  }
}