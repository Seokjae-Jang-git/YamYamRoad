import 'package:flutter/material.dart';

class SubFilterChips extends StatelessWidget {
  final String selectedTab; // 🆕 '지역별' 혹은 '메뉴별' 대분류 탭 상태 수신
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;
  final VoidCallback onMorePressed;

  const SubFilterChips({
    super.key,
    required this.selectedTab, // 🆕 필수 값 추가
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.onMorePressed,
  });

  // 1. 지역별 필터 목록
  static const List<String> _regionFilters = ['전체', '서울', '인천', '경기', '강원'];

  // 2. 🆕 메뉴별 필터 목록 (요구하신 카테고리 6대 구성 완료)
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
    // 🆕 '메뉴별' 탭이 켜졌을 때의 동적 칩 구성
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

    // 기존의 '지역별' 탭일 때의 동적 더보기 칩 구성
    final bool isDefaultSelected = _regionFilters.contains(selectedFilter);
    final String moreChipLabel = isDefaultSelected ? '지역 더보기' : '$selectedFilter ▾';
    final bool isMoreChipActive = !isDefaultSelected;

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        children: [
          // 기본 5대 지역 칩 루프 출력
          ..._regionFilters.map((filter) {
            final isSelected = filter == selectedFilter;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
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
          }),

          // 동적 지역 더보기 칩 렌더링
          ChoiceChip(
            label: Text(moreChipLabel),
            selected: isMoreChipActive,
            onSelected: (_) => onMorePressed(),
            selectedColor: Colors.orange[50],
            backgroundColor: Colors.white,
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
    );
  }
}