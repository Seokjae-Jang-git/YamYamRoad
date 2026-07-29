import 'package:flutter/material.dart';

class SubFilterChips extends StatelessWidget {
  final String selectedTab; // '지역별' 혹은 '메뉴별' 대분류 탭 상태 수신
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

  // 1. 지역별 필터 목록
  static const List<String> _regionFilters = ['전체', '서울', '인천', '경기', '강원'];

  // 2. 메뉴별 필터 목록 (요구 카테고리 6대 구성)
  static const List<String> _menuFilters = [
    '전체',
    '커피/차',
    '떡/한과',
    '빵/도넛',
    '아이스크림/빙수',
    '토스트/샌드위치/샐러드'
  ];

  @override
  Widget build(BuildContext context) {
    // '메뉴별' 탭이 선택되었을 때의 필터 칩 구성
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
              child: _buildChip(
                label: filter,
                isSelected: isSelected,
                onSelected: () => onFilterSelected(filter),
              ),
            );
          },
        ),
      );
    }

    // '지역별' 탭일 때의 필터 칩 구성
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
              child: _buildChip(
                label: filter,
                isSelected: isSelected,
                onSelected: () => onFilterSelected(filter),
              ),
            );
          }),

          // 동적 지역 더보기 칩 렌더링
          _buildChip(
            label: moreChipLabel,
            isSelected: isMoreChipActive,
            onSelected: onMorePressed,
          ),
        ],
      ),
    );
  }

  // 공통 칩 위젯 생성 함수 (크림 베이지 & 딥 브라운 테마 적용)
  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    // 선택 상태 색상 (크림 베이지 & 딥 브라운)
    const Color activeBg = Color(0xFFFAF6F0);
    const Color activeBorder = Color(0xFFE6DDD0);
    const Color activeText = Color(0xFF504D46);

    // 비선택 상태 색상 (화이트 & 부드러운 차콜 브라운)
    const Color inactiveBg = Colors.white;
    const Color inactiveBorder = Color(0xFFEFEBE4);
    const Color inactiveText = Color(0xFFA09891);

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      showCheckmark: false, // 기본 V 체크 표시 제거하여 뱃지 느낌 강조
      selectedColor: activeBg,
      backgroundColor: inactiveBg,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      labelStyle: TextStyle(
        color: isSelected ? activeText : inactiveText,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12,
        letterSpacing: -0.2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? activeBorder : inactiveBorder,
          width: 1.0,
        ),
      ),
    );
  }
}