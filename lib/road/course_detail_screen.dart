import 'package:flutter/material.dart';
import 'models/road.dart';
import 'models/place_model.dart';
import 'repositories/place_repository.dart';
import '../services/location_service.dart';
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
  // YamYamRoad 브랜드 공식 컬러 상수 정의
  static const Color pointCoralRed = Color(0xFFFF6B57);    // 시그니처 코랄 레드 (로딩 인디케이터)
  static const Color deepChocolate = Color(0xFF4A3225);    // 텍스트 & 메인 타이틀 & 아이콘
  static const Color creamyIvory = Color(0xFFFFFDF9);      // 스캐폴드/앱바 바탕 크림 아이보리
  static const Color cardBorder = Color(0xFFEFEBE4);       // 구분선 테두리 컬러

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

  /// 코스의 roadPlace(장소 ID 목록)를 기반으로 장소 목록을 즉시 보여주고, GPS 위치는 백그라운드에서 받아와 거리를 업데이트합니다.
  Future<void> _fetchPlaces() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. 캐시/Firestore에서 장소 목록 조회
      final fetchedPlaces = await _placeRepository.fetchPlacesByIds(widget.road.roadPlace);

      if (!mounted) return;

      // 2. 장소 데이터가 확보되었으므로 화면 로딩을 즉시 해제
      setState(() {
        _places = fetchedPlaces;
        _isLoading = false;
      });

      // 3. 화면이 떠 있는 상태에서 백그라운드로 안전하게 GPS 현재 위치를 구함 (5초 타임아웃 / Fallback 적용)
      final locationResult = await LocationService.getCurrentLocationWithFallback();

      // 4. GPS 수신 성공 시 실측 거리를 계산하여 화면 데이터 업데이트
      if (mounted) {
        final updatedPlaces = fetchedPlaces.map((place) {
          return place.copyWithCalculatedDistance(
            locationResult.latitude,
            locationResult.longitude,
          );
        }).toList();

        setState(() {
          _places = updatedPlaces;
        });
      }
    } catch (e) {
      if (!mounted) return;
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
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: creamyIvory,
      appBar: AppBar(
        title: Text(
          widget.road.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: deepChocolate,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        backgroundColor: creamyIvory,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: deepChocolate),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(color: cardBorder, height: 1.0, thickness: 1.0),
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: pointCoralRed),
      )
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: pointCoralRed, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      )
          : Stack(
        children: [
          // 🗺️ 상단 레이어: 배경 전체를 채우되, 시트에 가려지지 않도록 bottom padding 부여
          Positioned.fill(
            child: CourseDetailMap(
              places: _places,
              padding: EdgeInsets.only(
                bottom: screenHeight * 0.45,
              ),
            ),
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