import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'home_header.dart';
import 'location_bar.dart';
import 'home_stamp_dashboard.dart';
import 'home_recommended_roads_section.dart';
import 'ad_banner.dart';
import '../../ad/ad_station_page.dart';
import '../../common/data/temp_user_session.dart';
import '../../road/data/place_mock_data.dart';
import '../../services/location_service.dart';

class HomeContentView extends StatefulWidget {
  final ValueChanged<int> onTabChanged;

  const HomeContentView({
    super.key,
    required this.onTabChanged,
  });

  @override
  State<HomeContentView> createState() => _HomeContentViewState();
}

class _HomeContentViewState extends State<HomeContentView> {
  String _currentLocationText = initialUserLocation;
  Position? _currentPosition;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _currentLocationText = initialUserLocation;
    _fetchCurrentLocationAndRoads();
  }

  // 사용자의 현재 GPS 위치를 조회하고 주소 텍스트를 업데이트합니다.
  Future<void> _fetchCurrentLocationAndRoads() async {
    if (_isLoadingLocation) return;
    setState(() => _isLoadingLocation = true);

    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null && mounted) {
        setState(() {
          _currentPosition = position;
          _currentLocationText = '현재 위치 (GPS 연동됨)';
        });
      }
    } catch (e) {
      debugPrint('🔴 홈 화면 GPS 수집 실패: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  // GPS 재설정 버튼 탭 시 실시간 위치 업데이트 수행
  Future<void> _handleResetLocation() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('GPS 정보를 통해 현재 위치를 새로고침합니다...'),
        duration: Duration(seconds: 1),
      ),
    );

    await _fetchCurrentLocationAndRoads();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS 정보를 통해 현재 위치가 업데이트되었습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<PlaceData> stampVerifiablePlaces = masterPlaces.take(6).toList();

    // 에뮬레이터 기본 위치 (서울 중심부) - GPS 조회가 안 되었을 경우 fallback
    final double userLat = _currentPosition?.latitude ?? 37.5665;
    final double userLng = _currentPosition?.longitude ?? 126.9780;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. 상단 헤더 (로고, 알림 버튼, 프로필 메뉴)
          HomeHeader(
            onTabChanged: widget.onTabChanged,
          ),

          // 2. 위치 안내 및 위치 재설정 바
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: LocationBar(
              currentLocation: _currentLocationText,
              onResetLocation: _handleResetLocation,
            ),
          ),

          const SizedBox(height: 20),

          // 3. 스탬프 인증 현황 대시보드
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: HomeStampDashboard(
              verifiablePlaces: stampVerifiablePlaces,
              onPlaceSelected: (selectedPlace) {
                debugPrint('================================================');
                debugPrint('부모 화면 수신 데이터 [Selected Place ID]: ${selectedPlace.placeId}');
                debugPrint('================================================');

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '선택 완료: [${selectedPlace.name}] (ID: ${selectedPlace.placeId})\n콘솔 로그에 ID가 기록되었습니다.',
                    ),
                    backgroundColor: Colors.blue[800],
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 28),

          // 4. 내 위치 기반 추천 로드 섹션 (DB 연동 + 거리 정렬 + 지역 매핑 필터)
          HomeRecommendedRoadsSection(
            userLat: userLat,
            userLng: userLng,
          ),

          const SizedBox(height: 16),

          // 5. 하단 광고 배너
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: AdBanner(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdStationPage(),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}