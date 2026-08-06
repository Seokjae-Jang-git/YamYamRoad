import 'package:flutter/material.dart';
import '../../features/emoticon/emoticon_span_builder.dart';
import '../community_post.dart';
import '../community_search.dart';
import 'author_badge_row.dart';
import 'post_image_carousel.dart'; // 🌟 메인/상세 공용 이미지 캐러셀

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

  // 🌟 얌얌로드 공식 컬러 토큰 (다른 화면들과 통일)
  static const Color _deepChocolate = Color(0xFF4A3225);
  static const Color _pointCoralRed = Color(0xFFFF6B57);
  static const Color _creamyIvory = Color(0xFFFFFDF9);
  static const Color _subTextColor = Color(0xFF7A6B63);
  static const Color _accentOrange = Color(0xFFFF8A3D);

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

  // 🌟 팝업 메뉴 항목 하나를 아이콘 + 텍스트로 구성 (기본 텍스트 전용 스타일 대체)
  PopupMenuItem<String> _buildMenuItem({
    required String value,
    required IconData icon,
    required String label,
    bool isDestructive = false,
  }) {
    final Color color = isDestructive ? _pointCoralRed : _deepChocolate;
    return PopupMenuItem<String>(
      value: value,
      height: 42,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 "..." 버튼 자체도 동그란 배경을 줘서 터치 영역과 존재감을 살림
  Widget _buildMoreButton() {
    return Container(
      decoration: BoxDecoration(
        color: _deepChocolate.withOpacity(0.06),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.more_horiz_rounded, size: 20, color: _deepChocolate),
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
              padding: EdgeInsets.zero,
              icon: _buildMoreButton(),
              color: _creamyIvory,
              elevation: 4,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: _deepChocolate.withOpacity(0.08)),
              ),
              itemBuilder: (context) => [
                _buildMenuItem(value: 'edit', icon: Icons.edit_outlined, label: '수정'),
                _buildMenuItem(value: 'delete', icon: Icons.delete_outline_rounded, label: '삭제', isDestructive: true),
              ],
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
            )
                : PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: _buildMoreButton(),
              color: _creamyIvory,
              elevation: 4,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: _deepChocolate.withOpacity(0.08)),
              ),
              itemBuilder: (context) => [
                _buildMenuItem(value: 'report', icon: Icons.flag_outlined, label: '신고', isDestructive: true),
              ],
              onSelected: (value) {
                if (value == 'report') onReport();
              },
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
                    color: _accentOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        // 🌟 메인 피드와 동일하게, 여러 장이면 좌우로 넘겨볼 수 있는 캐러셀로 표시
        if (post.imageUrls.isNotEmpty) ...[
          const SizedBox(height: 12),
          PostImageCarousel(imageUrls: post.imageUrls),
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
                  size: 20, color: isScrapped ? _accentOrange : Colors.grey),
            ),
            const SizedBox(width: 4),
            Text('스크랩 ${post.scrapCount}', style: const TextStyle(fontSize: 13)),
          ],
        ),
      ],
    );
  }
}