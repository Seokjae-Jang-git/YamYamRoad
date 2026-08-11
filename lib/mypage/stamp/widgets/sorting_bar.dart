import 'package:flutter/material.dart';

class SortingBar extends StatelessWidget {
  final String selectedSort;
  final ValueChanged<String> onSortChanged;

  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color subTextColor = Color(0xFF7A6B63);

  const SortingBar({
    super.key,
    required this.selectedSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
          color: isSelected ? deepChocolate : subTextColor,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Text(
        '|',
        style: TextStyle(color: deepChocolate.withOpacity(0.2), fontSize: 10),
      ),
    );
  }
}