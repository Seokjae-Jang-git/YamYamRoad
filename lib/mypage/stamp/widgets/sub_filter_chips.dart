import 'package:flutter/material.dart';

class SubFilterChips extends StatelessWidget {
  final String selectedTab;
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;
  final VoidCallback onMorePressed;

  const SubFilterChips({
    super.key,
    required this.selectedTab,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.onMorePressed,
  });

  // 1. 지역별 기본 칩 (4개 + 더보기 1개 = 총 5개)
  static const List<String> _regionFilters = ['전체', '서울', '인천', '경기'];

  // 2. 메뉴별 필터 목록
  static const List<String> _menuFilters = [
    '전체',
    '커피/차(카페)',
    '떡/한과',
    '빵/도넛',
    '아이스크림/빙수',
    '토스트/샌드위치/샐러드'
  ];

  @override
  Widget build(BuildContext context) {
    if (selectedTab == '메뉴별') {
      return SizedBox(
        height: 38,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: _menuFilters.length,
          itemBuilder: (context, index) {
            final filter = _menuFilters[index];
            final isSelected = filter == selectedFilter;

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                showCheckmark: false, // 🌟 체크 아이콘 제거
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

    final bool isDefaultSelected = _regionFilters.contains(selectedFilter);
    final String moreChipLabel = isDefaultSelected ? '지역 더보기' : '$selectedFilter ▾';
    final bool isMoreChipActive = !isDefaultSelected;

    // 🌟 [수정] 스크롤 대신 Row + spaceBetween으로 하단 정렬 바(16px 패딩)와 양끝을 딱 맞춥니다!
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        height: 38,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ..._regionFilters.map((filter) {
              final isSelected = filter == selectedFilter;
              return ChoiceChip(
                showCheckmark: false, // 🌟 체크 아이콘 제거
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
              showCheckmark: false, // 🌟 체크 아이콘 제거
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