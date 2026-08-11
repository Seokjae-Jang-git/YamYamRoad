import 'package:flutter/material.dart';

class PointStatusCard extends StatelessWidget {
  final int points;

  const PointStatusCard({
    super.key,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    // 1안: 딥 초콜릿 프리미엄 카드 컬러 팔레트
    const Color cardBgColor = Color(0xFF4A3225); // 메인 딥 초콜릿 배경
    const Color cardBorderColor = Color(0xFF5C3E2E); // 은은한 외각 테두리
    const Color titleTextColor = Color(0xFFFAF6F0); // 크림 아이보리 타이틀
    const Color goldAccentColor = Color(0xFFF5D070); // 골드 옐로우 (아이콘 & 수치)

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardBorderColor,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A1C15).withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // 골드 옐로우 포인트 동전 아이콘
              const Icon(
                Icons.monetization_on_rounded,
                color: goldAccentColor,
                size: 26,
              ),
              const SizedBox(width: 10),
              const Text(
                '내 현재 무료 포인트',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: titleTextColor,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          // 골드 옐로우 포인트 수치 강조
          Text(
            '$points P',
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: goldAccentColor,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}