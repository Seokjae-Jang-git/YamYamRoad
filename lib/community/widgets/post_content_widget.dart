import 'package:flutter/material.dart';
import '../../features/emoticon/emoticon_span_builder.dart';
import '../community_post.dart';
import '../community_search.dart';
import 'author_badge_row.dart';

class PostContentWidget extends StatelessWidget {
  final CommunityPost post;
  final String currentUserId;
  final bool isMine;
  final bool isLiked;
  final bool isScrapped;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReport;
  final VoidCallback onLikeToggle;
  final VoidCallback onScrapToggle;

  const PostContentWidget({
    Key? key,
    required this.post,
    required this.currentUserId,
    required this.isMine,
    required this.isLiked,
    required this.isScrapped,
    required this.onEdit,
    required this.onDelete,
    required this.onReport,
    required this.onLikeToggle,
    required this.onScrapToggle,
  }) : super(key: key);

  // 🌟 태그를 누르면 바로 검색 화면으로 이동해서 그 태그로 검색된 결과를 보여줍니다.
  void _openTagSearch(BuildContext context, String tag) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunitySearchScreen(initialQuery: '#$tag'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFF5F5F5),
              backgroundImage: post.profileImage != null ? NetworkImage(post.profileImage!) : null,
              child: post.profileImage == null ? const Icon(Icons.person_outline, color: Colors.grey) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(post.nickname ?? '익명',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  const SizedBox(width: 6),
                  AuthorBadgeRow(userId: post.userId),
                ],
              ),
            ),
            isMine
                ? PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('수정')),
                PopupMenuItem(value: 'delete', child: Text('삭제')),
              ],
            )
                : PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'report') onReport();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'report', child: Text('신고')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        EmoticonRichContent(
          content: post.content,
          style: const TextStyle(fontSize: 14, color: Colors.black),
        ),
        // 🌟 태그 표시 - 누르면 해당 태그로 검색 화면 이동
        if (post.tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: post.tags.map((tag) {
              return GestureDetector(
                onTap: () => _openTagSearch(context, tag),
                child: Text(
                  '#$tag',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFFF8A3D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        if (post.imageUrls.isNotEmpty) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(post.imageUrls.first, fit: BoxFit.cover),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            GestureDetector(
              onTap: onLikeToggle,
              child: Icon(isLiked ? Icons.favorite : Icons.favorite_border,
                  size: 20, color: isLiked ? Colors.red : Colors.grey),
            ),
            const SizedBox(width: 4),
            Text('좋아요 ${post.likeCount}', style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 16),
            const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey),
            const SizedBox(width: 4),
            Text('댓글 ${post.commentCount}', style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: onScrapToggle,
              child: Icon(isScrapped ? Icons.bookmark : Icons.bookmark_border,
                  size: 20, color: isScrapped ? const Color(0xFFFF8A3D) : Colors.grey),
            ),
            const SizedBox(width: 4),
            Text('스크랩 ${post.scrapCount}', style: const TextStyle(fontSize: 13)),
          ],
        ),
      ],
    );
  }
}
