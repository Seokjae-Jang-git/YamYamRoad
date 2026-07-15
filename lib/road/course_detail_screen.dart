import 'package:flutter/material.dart';
import 'data/road_mock_data.dart';
import 'data/place_mock_data.dart';
import 'widgets/detail_mock_map.dart'; // 가상 지도 컴포넌트 임포트
import 'widgets/detail_place_card.dart'; // 가게 카드 컴포넌트 임포트

class CourseDetailScreen extends StatefulWidget {
  final CourseData course;

  const CourseDetailScreen({
    super.key,
    required this.course,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  String _sortOption = '거리순'; // 기본 정렬 옵션 설정

  // 외래키 리스트를 활용해 실시간으로 매칭되는 마스터 가게 데이터 추출 및 필터 정렬
  List<PlaceData> get _getMatchedPlaces {
    // 1. 코스 모델의 placeIds에 등록된 가게만 필터링
    List<PlaceData> filtered = masterPlaces
        .where((place) => widget.course.placeIds.contains(place.placeId))
        .toList();

    // 2. 선택된 기획 사양 정렬 옵션 대입
    if (_sortOption == '거리순') {
      filtered.sort((a, b) => a.distanceValue.compareTo(b.distanceValue));
    } else if (_sortOption == '스탬프 순') {
      filtered.sort((a, b) => b.stampCount.compareTo(a.stampCount));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final matchedPlaces = _getMatchedPlaces;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.course.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(color: Colors.black12, height: 1.0, thickness: 0.5),
        ),
      ),
      body: Stack(
        children: [
          // 🗺️ 상단 레이어: 가상 상호작용 지도 뷰 (고응집 컴포넌트로 온전히 위임!)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: DetailMockMap(places: matchedPlaces),
          ),

          // 🛗 하단 레이어: 드래그 가능한 슬라이딩 시트 (기획서 기조 반영)
          Positioned.fill(
            child: DraggableScrollableSheet(
              initialChildSize: 0.50, // 최초 실행 시 50% 높이 차지
              minChildSize: 0.45,     // 최소 높이 45%
              maxChildSize: 0.85,     // 최대 펼쳤을 때 85%
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
                      // 시트 상단 조작 핸들바 테코레이션
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),

                      // 1. 기획안 헤더: 코스명 & 개수 표시 및 정렬 칩 배치
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.course.title,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${widget.course.placeCount}개',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.orange[800],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            // 거리순 / 스탬프 순 세그먼트 정렬 바
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

                      // 2. 동적 스크롤 가능한 실시간 목록 영역
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: matchedPlaces.length,
                          itemBuilder: (context, index) {
                            final place = matchedPlaces[index];
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
            ),
          ),
        ],
      ),
    );
  }

  // 정렬 제어 칩 빌더
  Widget _buildSortOptionChip(String title) {
    final bool isSelected = _sortOption == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortOption = title;
        });
      },
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
          title,
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