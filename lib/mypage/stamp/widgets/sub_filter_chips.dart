import 'package:flutter/material.dart';

class SubFilterChips extends StatelessWidget {
  final String selectedTab;
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;
  final VoidCallback onMorePressed;
  final List<String> menuFilters;
  final List<String> regionFilters; // 🌟 DB에서 받아올 전체 지역 리스트

  const SubFilterChips({
    super.key,
    required this.selectedTab,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.onMorePressed,
    this.menuFilters = const ['전체'],
    this.regionFilters = const ['전체', '서울', '경기', '인천'], // 기본 예비값
  });

  @override
  Widget build(BuildContext context) {
    if (selectedTab == '메뉴별') {
      return SizedBox(
        height: 38,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: menuFilters.length,
          itemBuilder: (context, index) {
            final filter = menuFilters[index];
            final isSelected = filter == selectedFilter;

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                showCheckmark: false,
                label: Text(filter),
                selected: isSelected,
                onSelected: (_) => onFilterSelected(filter),
                selectedColor: Colors.orange[50],
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.orange[800] : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(19),
                  side: BorderSide(
                    color: isSelected ? Colors.orange : Colors.grey[300]!,
                    width: 1.0,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    // 🌟 [동적 지역 칩 렌더링]
    // 상단 가로 칩에는 DB 지역 목록 중 상위 4개만 기본 노출 ('전체' + 앞쪽 3개 지역)
    final List<String> defaultDisplayRegions = regionFilters.length >= 4
        ? regionFilters.sublist(0, 4)
        : regionFilters;

    final bool isDefaultSelected = defaultDisplayRegions.contains(selectedFilter);
    final String moreChipLabel = isDefaultSelected ? '지역 더보기' : '$selectedFilter ▾';
    final bool isMoreChipActive = !isDefaultSelected;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        height: 38,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ...defaultDisplayRegions.map((filter) {
              final isSelected = filter == selectedFilter;
              return ChoiceChip(
                showCheckmark: false,
                label: Text(filter),
                selected: isSelected,
                onSelected: (_) => onFilterSelected(filter),
                selectedColor: Colors.orange[50],
                backgroundColor: Colors.white,
                labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.orange[800] : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(19),
                  side: BorderSide(
                    color: isSelected ? Colors.orange : Colors.grey[300]!,
                    width: 1.0,
                  ),
                ),
              );
            }),

            // 지역 더보기 칩
            ChoiceChip(
              showCheckmark: false,
              label: Text(moreChipLabel),
              selected: isMoreChipActive,
              onSelected: (_) => onMorePressed(),
              selectedColor: Colors.orange[50],
              backgroundColor: Colors.white,
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              labelStyle: TextStyle(
                color: isMoreChipActive ? Colors.orange[800] : Colors.black87,
                fontWeight: isMoreChipActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(19),
                side: BorderSide(
                  color: isMoreChipActive ? Colors.orange : Colors.grey[300]!,
                  width: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}