import 'package:flutter/material.dart';

class AdTabBar extends StatelessWidget implements PreferredSizeWidget {
  const AdTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    // 확정된 디자인: 모카 & 베이지 톤 컬러 팔레트
    const Color trackBgColor = Color(0xFFEFEBE4); // 샌드 베이지 트랙
    const Color selectedBgColor = Color(0xFF6B4A38); // 모카 브라운 선택 칩
    const Color selectedTextColor = Color(0xFFFAF6F0); // 크림 아이보리 텍스트
    const Color unselectedTextColor = Color(0xFF8C7A6B); // 코코아 브라운 텍스트

    return Container(
      height: 46,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: trackBgColor,
        borderRadius: BorderRadius.circular(23),
      ),
      child: TabBar(
        // Material3 기본 구분선 제거
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(3),
        indicator: BoxDecoration(
          color: selectedBgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        labelColor: selectedTextColor,
        unselectedLabelColor: unselectedTextColor,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: -0.3,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
          letterSpacing: -0.3,
        ),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        tabs: const [
          Tab(text: '구글 애드몹'),
          Tab(text: '자체 제휴'),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(46);
}