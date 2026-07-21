import 'package:flutter/material.dart';
import '../models/place_model.dart';
import 'detail_place_card.dart';

class CourseDetailSheet extends StatelessWidget {
  final String title;
  final List<PlaceModel> places;
  final String currentSortOption;
  final ValueChanged<String> onSortOptionChanged;

  const CourseDetailSheet({
    super.key,
    required this.title,
    required this.places,
    required this.currentSortOption,
    required this.onSortOptionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.50,
      minChildSize: 0.45,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // 드래그 핸들바
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),

              // 1. 헤더: 코스명, 장소 개수, 정렬 칩
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${places.length}개',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildSortOptionChip('거리순'),
                        const SizedBox(width: 6),
                        _buildSortOptionChip('스탬프 순'),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.black12, height: 1.0),

              // 2. 장소 카드 목록 영역
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: places.length,
                  itemBuilder: (context, index) {
                    final place = places[index];
                    return DetailPlaceCard(
                      index: index + 1,
                      place: place,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 정렬 선택 칩 위젯
  Widget _buildSortOptionChip(String optionTitle) {
    final bool isSelected = currentSortOption == optionTitle;
    return GestureDetector(
      onTap: () => onSortOptionChanged(optionTitle),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange[50] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey[300]!,
          ),
        ),
        child: Text(
          optionTitle,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.orange[800] : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}