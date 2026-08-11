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
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // 메인 탭바 배경 컨테이너
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20), // 하단바 상단 모서리 라운딩
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08), // 은은한 상단 그림자 효과
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 68,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, '홈', Icons.home_rounded),
                  _buildNavItem(1, '얌얌북', Icons.forum_rounded), // 커뮤니티 성격에 맞춘 아이콘
                  _buildNavItem(2, '얌얌로드', Icons.location_on_rounded), // 지도 위치 핀 아이콘
                  _buildNavItem(3, '포인트', Icons.monetization_on_rounded),
                  _buildNavItem(4, '마이페이지', Icons.person_rounded),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon) {
    final bool isSelected = currentIndex == index;
    final bool isRoadTab = index == 2;

    // YamYamRoad 브랜드 공식 컬러
    const Color activeColor = Color(0xFF4A3225); // Deep Chocolate
    const Color inactiveColor = Color(0xFFA09891); // Soft Charcoal
    const Color roadBrandColor = Color(0xFFFF6B57); // Coral Red (시그니처)
    const Color roadBgColor = Color(0xFFFFFDF9); // Cream Ivory

    // 🌟 얌얌로드 탭: 상단 경계를 뚫고 나오는 Floating 디자인
    if (isRoadTab) {
      return Expanded(
        child: InkWell(
          onTap: () => onTap(index),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. 상단으로 14px 솟아오른 원형 시그니처 버튼
                  Transform.translate(
                    offset: const Offset(0, -14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? roadBrandColor : roadBgColor,
                        border: Border.all(
                          color: roadBrandColor,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: roadBrandColor.withOpacity(isSelected ? 0.35 : 0.15),
                            blurRadius: isSelected ? 12 : 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        size: 26,
                        color: isSelected ? Colors.white : roadBrandColor,
                      ),
                    ),
                  ),
                  // 2. 하단 라벨 (위로 이동한 아이콘 위치에 맞춤)
                  Transform.translate(
                    offset: const Offset(0, -8),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? roadBrandColor : activeColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // 🌟 일반 탭 디자인
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFAF6F0) : Colors.transparent,
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