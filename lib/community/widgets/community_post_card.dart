import 'package:flutter/material.dart';
import '../../features/emoticon/emoticon_span_builder.dart';
import '../community_post.dart';
import 'post_header_with_badges.dart';
import 'post_image_carousel.dart';

class CommunityPostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback onTap;
  final ValueChanged<String> onTagTap;

  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color subTextColor = Color(0xFF7A6B63);

  const CommunityPostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onTagTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: deepChocolate.withOpacity(0.12),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: deepChocolate.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PostHeaderWithBadges(
              userId: post.userId,
              authorNickname: post.nickname ?? '익명',
              authorProfileImage: post.profileImage,
              createdAt: post.createdAt,
            ),
            const SizedBox(height: 12),
            EmoticonRichContent(
              content: post.content,
              emojiSize: 16,
              style: const TextStyle(fontSize: 13, height: 1.4, color: deepChocolate),
            ),
            if (post.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: post.tags.map((tag) {
                  return GestureDetector(
                    onTap: () => onTagTap(tag),
                    child: Text(
                      '#$tag',
                      style: const TextStyle(
                        fontSize: 12,
                        color: pointCoralRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (post.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              PostImageCarousel(imageUrls: post.imageUrls),
            ],
            const SizedBox(height: 12),
            Text(
              '좋아요 ${post.likeCount}   댓글 ${post.commentCount}   스크랩 ${post.scrapCount}',
              style: const TextStyle(fontSize: 12, color: subTextColor, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}