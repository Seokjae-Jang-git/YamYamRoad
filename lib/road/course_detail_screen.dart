import 'package:flutter/material.dart';
import 'models/road.dart';
import 'models/place_model.dart';
import 'repositories/place_repository.dart';
import 'widgets/detail_place_card.dart';

class CourseDetailScreen extends StatefulWidget {
  final Road road;

  const CourseDetailScreen({
    super.key,
    required this.road,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final PlaceRepository _placeRepository = PlaceRepository();

  String _sortOption = '거리순';
  List<PlaceModel> _places = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPlaces();
  }

  /// 코스의 placeIds를 기반으로 Firestore에서 실제 장소 목록을 조회합니다.
  Future<void> _fetchPlaces() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fetchedPlaces = await _placeRepository.fetchPlacesByIds(widget.road.placeIds);
      setState(() {
        _places = fetchedPlaces;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '장소 정보를 불러오지 못했습니다: $e';
        _isLoading = false;
      });
    }
  }

  // 실시간 매칭된 장소 데이터를 선택된 옵션으로 정렬하여 반환
  List<PlaceModel> get _getSortedPlaces {
    List<PlaceModel> sorted = List.from(_places);

    if (_sortOption == '거리순') {
      sorted.sort((a, b) => a.distanceValue.compareTo(b.distanceValue));
    } else if (_sortOption == '스탬프 순') {
      sorted.sort((a, b) => b.stampCount.compareTo(a.stampCount));
    }

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final sortedPlaces = _getSortedPlaces;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.road.title,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      )
          : Stack(
        children: [
          // 🗺️ 상단 레이어: 지도 영역 대체 위젯
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: _buildMapArea(),
          ),

          // 🛗 하단 레이어: 드래그 가능한 슬라이딩 시트
          Positioned.fill(
            child: DraggableScrollableSheet(
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
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),

                      // 1. 헤더: 코스명 & 개수 표시 및 정렬 칩
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.road.title,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${sortedPlaces.length}개',
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

                      // 2. 실시간 장소 목록 영역
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: sortedPlaces.length,
                          itemBuilder: (context, index) {
                            final place = sortedPlaces[index];
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

  /// 지도 영역 (네이버 지도 SDK 제거 및 대체 안내 영역)
  Widget _buildMapArea() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              '지도 영역',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

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