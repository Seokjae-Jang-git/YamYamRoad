import 'package:flutter/material.dart';

class AdRewardCard extends StatelessWidget {
  final String title;
  final String specs;
  final String reward;
  final VoidCallback onTap;
  final bool isSponsor;

  const AdRewardCard({
    super.key,
    required this.title,
    required this.specs,
    required this.reward,
    required this.onTap,
    required this.isSponsor,
  });

  @override
  Widget build(BuildContext context) {
    // 1안: 딥 에스프레소 & 버트 앰버 팔레트 정의
    const Color deepChocolate = Color(0xFF4A3225); // 메인 버튼 & 타이틀 (상단 통일)
    const Color cinnamonAmber = Color(0xFFD98236); // 차분한 버트 앰버 (포인트 강조)
    const Color mochaBrown = Color(0xFF6B4A38);    // AdMob 뱃지 텍스트
    const Color cocoaText = Color(0xFF8C7A6B);     // 서브 설명 문구
    const Color sandBorder = Color(0xFFE5DDD5);    // 소프트 베이지 테두리

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: sandBorder, width: 1.0),
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 미니 뱃지 (스폰서 / AdMob)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSponsor ? const Color(0xFFFAF3EC) : const Color(0xFFF7F4EF),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSponsor ? cinnamonAmber.withOpacity(0.4) : sandBorder,
                  width: 1,
                ),
              ),
              child: Text(
                isSponsor ? 'SPONSOR' : 'ADMOB',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isSponsor ? cinnamonAmber : mochaBrown,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 광고 타이틀 & 설명
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: deepChocolate,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              specs,
              style: const TextStyle(
                fontSize: 12,
                color: cocoaText,
              ),
            ),
            const SizedBox(height: 14),

            // 보상 및 버튼 영역
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    children: [
                      const TextSpan(
                        text: '보상포인트: ',
                        style: TextStyle(color: cocoaText),
                      ),
                      TextSpan(
                        text: reward,
                        style: TextStyle(
                          color: isSponsor ? cinnamonAmber : deepChocolate,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deepChocolate,
                    foregroundColor: const Color(0xFFFAF7F2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    elevation: 0,
                  ),
                  onPressed: onTap,
                  child: Text(
                    isSponsor ? '스폰서 영상 시청' : '광고 시청하기',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}