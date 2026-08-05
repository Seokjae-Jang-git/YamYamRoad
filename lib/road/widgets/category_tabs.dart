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

  // YamYamRoad 브랜드 공식 컬러 상수 정의
  static const Color pointCoralRed = Color(0xFFFF6B57); // 시그니처 코랄 레드 (활성)
  static const Color subBrown = Color(0xFF7A6B63);      // 부드러운 서브 브라운 (비활성)
  static const Color deepChocolate = Color(0xFF4A3225); // 메인 텍스트 & 아이콘 컬러

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
          // 우측 단독 돋보기 아이콘 버튼 (배경/테두리 제거)
          GestureDetector(
            onTap: onSearchPressed,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.search_rounded,
                color: deepChocolate,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String text) {
    final bool isSelected = text == selectedTab;

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
              color: isSelected ? pointCoralRed : subBrown,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          // 선택 시 나타나는 라운드 형태의 코랄 레드 밑줄 인디케이터
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3,
            width: 32,
            decoration: BoxDecoration(
              color: isSelected ? pointCoralRed : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}