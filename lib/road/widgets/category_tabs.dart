import 'package:flutter/material.dart';

class CategoryTabs extends StatelessWidget {
  final String selectedTab;
  final ValueChanged<String> onTabChanged;
  final VoidCallback onSearchPressed;

  const CategoryTabs({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
    required this.onSearchPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 카테고리 탭 영역 ('지역별', '메뉴별')
          Row(
            children: [
              _buildTabItem('지역별'),
              const SizedBox(width: 20),
              _buildTabItem('메뉴별'),
            ],
          ),
          // 우측 검색 버튼 (상단 알림 버튼과 동일한 베이지 미니멀 원형 디자인)
          GestureDetector(
            onTap: onSearchPressed,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF6F0), // 따뜻한 베이지 배경
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: const Icon(
                Icons.search_rounded,
                color: Color(0xFF504D46),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String text) {
    final bool isSelected = text == selectedTab;
    const Color activeColor = Color(0xFF504D46); // 딥 브라운
    const Color inactiveColor = Color(0xFFA09891); // 부드러운 차콜 브라운

    return GestureDetector(
      onTap: () => onTabChanged(text),
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 18,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? activeColor : inactiveColor,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          // 선택 시 나타나는 라운드 형태의 딥 브라운 밑줄 인디케이터
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3,
            width: 32,
            decoration: BoxDecoration(
              color: isSelected ? activeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}