import 'package:flutter/material.dart';
import 'models/road.dart';
import 'models/place_model.dart';
import 'repositories/place_repository.dart';
import 'widgets/course_detail_map.dart';
import 'widgets/course_detail_sheet.dart';

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

  /// 코스의 roadPlace(장소 ID 목록)를 기반으로 Firestore에서 실제 장소 목록을 조회합니다.
  Future<void> _fetchPlaces() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fetchedPlaces = await _placeRepository.fetchPlacesByIds(widget.road.roadPlace);
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
          // 🗺️ 상단 레이어: 구글 지도 컴포넌트
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: CourseDetailMap(places: _places),
          ),

          // 🛗 하단 레이어: 드래그 가능한 슬라이딩 시트 컴포넌트
          Positioned.fill(
            child: CourseDetailSheet(
              title: widget.road.title,
              places: sortedPlaces,
              currentSortOption: _sortOption,
              onSortOptionChanged: (newOption) {
                setState(() {
                  _sortOption = newOption;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}