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
      padding: const EdgeInsets.only(left: 16.0, right: 8.0, top: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildTabItem('지역별'),
              const SizedBox(width: 24),
              _buildTabItem('메뉴별'),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.orange, size: 28),
            onPressed: onSearchPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String text) {
    final isSelected = text == selectedTab;
    return GestureDetector(
      onTap: () => onTabChanged(text),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.orange[800] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 3,
            width: 48,
            color: isSelected ? Colors.orange : Colors.transparent,
          ),
        ],
      ),
    );
  }
}