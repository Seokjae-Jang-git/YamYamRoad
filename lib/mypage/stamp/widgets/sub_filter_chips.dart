import 'package:flutter/material.dart';

class SubFilterChips extends StatelessWidget {
  final String selectedTab;
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;
  final VoidCallback onMorePressed;
  final List<String> menuFilters;

  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color subTextColor = Color(0xFF7A6B63);

  static const List<String> _defaultRegionFilters = ['전체', '서울', '인천', '경기', '강원'];

  const SubFilterChips({
    super.key,
    required this.selectedTab,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.onMorePressed,
    this.menuFilters = const ['전체'],
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
                selectedColor: pointCoralRed,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : subTextColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(19),
                  side: BorderSide(
                    color: isSelected ? pointCoralRed : deepChocolate.withOpacity(0.15),
                    width: 1.0,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    final bool isDefaultSelected = _defaultRegionFilters.contains(selectedFilter);
    final String moreChipLabel = isDefaultSelected ? '지역 더보기' : '$selectedFilter ▾';
    final bool isMoreChipActive = !isDefaultSelected;

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        children: [
          ..._defaultRegionFilters.map((filter) {
            final isSelected = filter == selectedFilter;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                showCheckmark: false,
                label: Text(filter),
                selected: isSelected,
                onSelected: (_) => onFilterSelected(filter),
                selectedColor: pointCoralRed,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : subTextColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(19),
                  side: BorderSide(
                    color: isSelected ? pointCoralRed : deepChocolate.withOpacity(0.15),
                    width: 1.0,
                  ),
                ),
              ),
            );
          }),

          ChoiceChip(
            showCheckmark: false,
            label: Text(moreChipLabel),
            selected: isMoreChipActive,
            onSelected: (_) => onMorePressed(),
            selectedColor: pointCoralRed,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isMoreChipActive ? Colors.white : subTextColor,
              fontWeight: isMoreChipActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(19),
              side: BorderSide(
                color: isMoreChipActive ? pointCoralRed : deepChocolate.withOpacity(0.15),
                width: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}