import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'post_badge_slider_sheet.dart';

class PostHeaderWithBadges extends StatelessWidget {
  final String userId;
  final String authorNickname;
  final String? authorProfileImage;
  final DateTime createdAt;

  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color subTextColor = Color(0xFF7A6B63);

  const PostHeaderWithBadges({
    super.key,
    required this.userId,
    required this.authorNickname,
    this.authorProfileImage,
    required this.createdAt,
  });

  Future<List<Map<String, dynamic>>> _fetchAllUserBadges(String userId) async {
    final cleanUid = userId.trim();
    if (cleanUid.isEmpty) {
      // debugPrint('⚠️ [BadgeCheck] userId가 없어 뱃지 조회를 건너뜁니다.');
      return [];
    }

    try {
      final userBadgeSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(cleanUid)
          .collection('users_badge')
          .get();

      if (userBadgeSnap.docs.isEmpty) return [];

      var selectedDocs = userBadgeSnap.docs
          .where((d) => d.data()['isSelected'] == true)
          .toList();

      selectedDocs.sort((a, b) {
        int orderA = (a.data()['displayOrder'] as num?)?.toInt() ?? 99;
        int orderB = (b.data()['displayOrder'] as num?)?.toInt() ?? 99;
        return orderA.compareTo(orderB);
      });

      var unselectedDocs = userBadgeSnap.docs
          .where((d) => d.data()['isSelected'] != true)
          .toList();

      final allDocs = [...selectedDocs, ...unselectedDocs];
      final badgeIds = allDocs
          .map((d) => d.data()['badgeId'] as String?)
          .whereType<String>()
          .toList();

      final List<Map<String, dynamic>> badgeDetails = [];
      for (final bId in badgeIds) {
        final badgeDoc = await FirebaseFirestore.instance.collection('badge').doc(bId).get();
        if (badgeDoc.exists && badgeDoc.data()?['isActive'] == true) {
          final data = badgeDoc.data()!;
          badgeDetails.add({
            'id': bId,
            'name': data['name'] ?? '뱃지',
            'description': data['description'] ?? '',
            'imageUrl': data['imageUrl'] ?? '',
            'iconUrl': data['iconUrl'] ?? data['imageUrl'] ?? '',
          });
        }
      }

      return badgeDetails;
    } catch (e) {
      // debugPrint('🔴 [BadgeCheck] 뱃지 로드 중 에러 발생: $e');
      return [];
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${time.month}/${time.day}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchAllUserBadges(userId),
      builder: (context, snapshot) {
        final allBadges = snapshot.data ?? [];

        const int maxDisplayCount = 3;
        final displayBadges = allBadges.take(maxDisplayCount).toList();
        final bool hasMore = allBadges.length > maxDisplayCount;
        final int extraCount = allBadges.length - maxDisplayCount;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFFAF7F5),
              backgroundImage: authorProfileImage != null && authorProfileImage!.isNotEmpty
                  ? NetworkImage(authorProfileImage!)
                  : null,
              child: authorProfileImage == null || authorProfileImage!.isEmpty
                  ? const Icon(Icons.person_outline, size: 20, color: subTextColor)
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  authorNickname,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: deepChocolate,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTime(createdAt),
                  style: const TextStyle(fontSize: 11, color: subTextColor),
                ),
              ],
            ),
            const SizedBox(width: 8),
            if (displayBadges.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: displayBadges.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final badge = entry.value;
                  final String iconUrl = badge['iconUrl'] ?? '';
                  return GestureDetector(
                    onTap: () => showBadgeSliderBottomSheet(context, allBadges, initialIndex: index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 4),
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: ClipOval(
                        child: iconUrl.isEmpty
                            ? const SizedBox.shrink()
                            : Image.network(
                          iconUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            if (hasMore)
              GestureDetector(
                onTap: () => showBadgeSliderBottomSheet(context, allBadges, initialIndex: maxDisplayCount),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: deepChocolate.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+$extraCount',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: deepChocolate),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}