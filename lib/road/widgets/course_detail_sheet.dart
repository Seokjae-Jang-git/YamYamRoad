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

  // YamYamRoad 브랜드 공식 컬러 상수 정의
  static const Color pointCoralRed = Color(0xFFFF6B57);    // 시그니처 코랄 레드 (선택된 정렬 칩/개수 텍스트)
  static const Color strawberryPink = Color(0xFFFFA09B);   // 연한 스트로베리 핑크 (선택 칩 배경)
  static const Color deepChocolate = Color(0xFF4A3225);    // 타이틀 및 메인 텍스트
  static const Color subBrown = Color(0xFF7A6B63);         // 서브 브라운 텍스트
  static const Color cardBorder = Color(0xFFEFEBE4);       // 구분선 & 테두리 컬러
  static const Color handleBarColor = Color(0xFFE0D8D0);   // 핸들바 소프트 초콜릿 톤

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.50,
      minChildSize: 0.45,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: deepChocolate.withOpacity(0.08),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, -2),
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
                  color: handleBarColor,
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: deepChocolate,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${places.length}개',
                          style: const TextStyle(
                            fontSize: 14,
                            color: pointCoralRed,
                            fontWeight: FontWeight.bold,
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
              const Divider(color: cardBorder, height: 1.0, thickness: 1.0),

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
          color: isSelected ? strawberryPink.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? pointCoralRed : cardBorder,
            width: isSelected ? 1.2 : 1.0,
          ),
        ),
        child: Text(
          optionTitle,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? pointCoralRed : subBrown,
          ),
        ),
      ),
    );
  }
}