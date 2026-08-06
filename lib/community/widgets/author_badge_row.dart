import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthorBadgeRow extends StatelessWidget {
  final String userId;

  const AuthorBadgeRow({Key? key, required this.userId}) : super(key: key);

  Future<List<Map<String, dynamic>>> _fetchAllUserBadges() async {
    final cleanUid = userId.trim();
    if (cleanUid.isEmpty) return [];

    try {
      final userBadgeSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(cleanUid)
          .collection('users_badge')
          .get();

      if (userBadgeSnap.docs.isEmpty) return [];

      var selectedDocs = userBadgeSnap.docs.where((d) => d.data()['isSelected'] == true).toList();
      selectedDocs.sort((a, b) {
        final orderA = (a.data()['displayOrder'] as num?)?.toInt() ?? 99;
        final orderB = (b.data()['displayOrder'] as num?)?.toInt() ?? 99;
        return orderA.compareTo(orderB);
      });

      var unselectedDocs = userBadgeSnap.docs.where((d) => d.data()['isSelected'] != true).toList();
      final allDocs = [...selectedDocs, ...unselectedDocs];
      final badgeIds = allDocs.map((d) => d.data()['badgeId'] as String?).whereType<String>().toList();

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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchAllUserBadges(),
      builder: (context, snapshot) {
        final allBadges = snapshot.data ?? [];
        if (allBadges.isEmpty) return const SizedBox.shrink();

        const int maxDisplayCount = 3;
        final displayBadges = allBadges.take(maxDisplayCount).toList();
        final bool hasMore = allBadges.length > maxDisplayCount;
        final int extraCount = allBadges.length - maxDisplayCount;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...displayBadges.asMap().entries.map((entry) {
              final int index = entry.key;
              final badge = entry.value;
              final String iconUrl = badge['iconUrl'] ?? '';
              return GestureDetector(
                onTap: () => _showBadgeSliderBottomSheet(context, allBadges, initialIndex: index),
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  width: 22,
                  height: 22,
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
            }),
            if (hasMore)
              GestureDetector(
                onTap: () => _showBadgeSliderBottomSheet(context, allBadges, initialIndex: maxDisplayCount),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+$extraCount',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showBadgeSliderBottomSheet(BuildContext context, List<Map<String, dynamic>> allBadges, {int initialIndex = 0}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        int currentPage = initialIndex;
        final PageController pageController = PageController(initialPage: initialIndex);

        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 16),
                  Text('보유한 뱃지 (${currentPage + 1}/${allBadges.length})',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                  SizedBox(
                    height: 190,
                    child: PageView.builder(
                      controller: pageController,
                      itemCount: allBadges.length,
                      onPageChanged: (index) => setBottomSheetState(() => currentPage = index),
                      itemBuilder: (context, index) {
                        final badge = allBadges[index];
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: Image.network(
                                badge['imageUrl'],
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.workspace_premium, size: 70, color: Colors.orange),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(badge['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                            const SizedBox(height: 6),
                            Text(
                              badge['description'] ?? '',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.3),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  if (allBadges.length > 1) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(allBadges.length, (dotIndex) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: currentPage == dotIndex ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: currentPage == dotIndex ? Colors.black : Colors.grey.shade300,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('확인', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }
}