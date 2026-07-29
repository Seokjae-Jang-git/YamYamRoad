import 'package:flutter/material.dart';

class SubFilterChips extends StatelessWidget {
  final String selectedTab;
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;
  final VoidCallback onMorePressed;
  final List<String> menuFilters;

  // 🌟 road와 동일하게 노출할 기본 5대 지역을 하드코딩으로 고정합니다.
  static const List<String> _defaultRegionFilters = ['전체', '서울', '인천', '경기', '강원'];

  const SubFilterChips({
    super.key,
    required this.selectedTab,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.onMorePressed,
    this.menuFilters = const ['전체'],
    // regionFilters 파라미터는 더 이상 칩 렌더링에 직접 쓰지 않으므로 제거하거나 무시합니다.
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

    // 🌟 [지역별 탭] road 화면과 동일한 로직 적용
    // 선택된 지역이 기본 5개 안에 있으면 '지역 더보기', 다른 지역(예: 부산)이면 '부산 ▾' 표시
    final bool isDefaultSelected = _defaultRegionFilters.contains(selectedFilter);
    final String moreChipLabel = isDefaultSelected ? '지역 더보기' : '$selectedFilter ▾';
    final bool isMoreChipActive = !isDefaultSelected;

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        children: [
          // 무한 스크롤 대신 고정된 5개 지역만 그립니다.
          ..._defaultRegionFilters.map((filter) {
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

          // 동적 지역 더보기 칩 (클릭 시 onMorePressed 호출)
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