import 'package:flutter/material.dart';

class AdBanner extends StatelessWidget {
  final VoidCallback onTap;

  const AdBanner({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6F0), // 부드러운 크림 베이지 배경
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE6DDD0), // 안정감을 주는 샌드 베이지 테두리
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: const Color(0xFFE6DDD0).withAlpha(80),
          highlightColor: const Color(0xFFE6DDD0).withAlpha(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // 원형 선물 아이콘 배경
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0E8DD),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.card_giftcard_rounded,
                    color: Color(0xFF4A3E3D),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // 메인 안내 텍스트
                const Expanded(
                  child: Text(
                    '광고 보고 무료 포인트 받기',
                    style: TextStyle(
                      color: Color(0xFF4A3E3D), // 가독성 높인 딥 브라운
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                // 우측 화살표 아이콘
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF8C7E7A),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}