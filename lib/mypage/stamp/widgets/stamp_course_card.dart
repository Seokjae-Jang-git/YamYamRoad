import 'package:flutter/material.dart';

class StampCourseCard extends StatelessWidget {
  final Map<String, dynamic> roadData;
  final VoidCallback onTap;

  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color creamyIvory = Color(0xFFFFFDF9);
  static const Color subTextColor = Color(0xFF7A6B63);

  const StampCourseCard({
    super.key,
    required this.roadData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 🌟 전체 스탬프 개수 계산 logic
    int totalStampCount = 0;
    if (roadData['placeCount'] != null && roadData['placeCount'] is int) {
      totalStampCount = roadData['placeCount'];
    } else {
      final List<dynamic> places =
          roadData['roadPlace'] ?? roadData['placeIds'] ?? [];
      totalStampCount = places.length;
    }

    final int myStampCount = roadData['myStampCount'] ?? 0;
    final String imageUrl = roadData['imageUrl'] ??
        roadData['thumbnailUrl'] ??
        roadData['thumbnail'] ??
        '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: deepChocolate.withOpacity(0.12)),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: deepChocolate.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 코스 사진 영역
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: creamyIvory,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.hardEdge,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Text('사진 없음',
                      style:
                      TextStyle(color: subTextColor, fontSize: 11)),
                ),
              )
                  : const Center(
                child: Text('코스사진',
                    style: TextStyle(color: subTextColor, fontSize: 11)),
              ),
            ),
            const SizedBox(width: 12),
            // 정보 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    roadData['title'] ?? '제목 없음',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: deepChocolate,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.verified,
                        size: 16,
                        color: pointCoralRed,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '스탬프 $myStampCount / $totalStampCount 개',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: deepChocolate,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}