import 'package:flutter/material.dart';

class BottomCircleTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomCircleTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20), // 하단바 상단 모서리 라운딩
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12), // 은은한 상단 그림자 효과
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, '홈', Icons.home_rounded),
              _buildNavItem(1, '얌얌북', Icons.menu_book_rounded),
              _buildNavItem(2, '얌얌로드', Icons.map_rounded),
              _buildNavItem(3, '포인트', Icons.monetization_on_rounded),
              _buildNavItem(4, '마이페이지', Icons.person_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    final bool isSelected = currentIndex == index;
    final bool isRoadTab = index == 2;

    // 테마 컬러 세팅 (앱의 베이지/딥 브라운 톤앤매너 유지)
    const Color activeColor = Color(0xFF4A3E3D); // 딥 브라운
    const Color inactiveColor = Color(0xFFA09891); // 부드러운 차콜 브라운

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 선택 시 나타나는 크림 베이지 캡슐 하이라이트 배경
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFAF6F0) // 따뜻한 크림 베이지
                    : (isRoadTab ? const Color(0xFFFAF6F0).withAlpha(100) : Colors.transparent),
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? Border.all(color: const Color(0xFFE6DDD0), width: 1)
                    : null,
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}