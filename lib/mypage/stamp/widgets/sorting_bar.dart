import 'package:flutter/material.dart';

class SortingBar extends StatelessWidget {
  final String selectedSort;
  final ValueChanged<String> onSortChanged;

  const SortingBar({
    super.key,
    required this.selectedSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    // 🌟 Row 상위의 Padding(horizontal: 16.0)을 제거하여 상단 Row와 여백을 맞춥니다.
    return Row(
      mainAxisSize: MainAxisSize.min, // 필요한 만큼만 공간 차지
      children: [
        _buildSortOption('최신순'),
        _buildDivider(),
        _buildSortOption('이름순'),
        _buildDivider(),
        _buildSortOption('스탬프 순'),
      ],
    );
  }

  Widget _buildSortOption(String text) {
    final isSelected = text == selectedSort;
    return GestureDetector(
      onTap: () => onSortChanged(text),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.black87 : Colors.grey[500],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Text(
        '|',
        style: TextStyle(color: Colors.grey[300], fontSize: 10),
      ),
    );
  }
}