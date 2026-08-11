import 'package:flutter/material.dart';

class SortingBar extends StatelessWidget {
  final String selectedSort;
  final ValueChanged<String> onSortChanged;

  const SortingBar({
    super.key,
    required this.selectedSort,
    required this.onSortChanged,
  });

  // YamYamRoad 브랜드 공식 컬러 상수 정의
  static const Color deepChocolate = Color(0xFF4A3225); // 딥 초콜릿 (선택 항목)
  static const Color subBrown = Color(0xFF7A6B63);      // 부드러운 서브 브라운 (미선택 항목)
  static const Color dividerColor = Color(0xFFE6DDD0);  // 은은한 크림 구분선

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildSortOption('최신순'),
          _buildDivider(),
          _buildSortOption('이름순'),
        ],
      ),
    );
  }

  Widget _buildSortOption(String text) {
    final isSelected = text == selectedSort;
    return GestureDetector(
      onTap: () => onSortChanged(text),
      behavior: HitTestBehavior.opaque,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? deepChocolate : subBrown,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.0),
      child: Text(
        '|',
        style: TextStyle(
          color: dividerColor,
          fontSize: 10,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }
}