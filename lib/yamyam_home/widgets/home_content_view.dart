import 'package:flutter/material.dart';
import 'top_circle_button.dart';
import 'location_bar.dart';
import 'ad_banner.dart';
import 'home_stamp_dashboard.dart';
import 'home_road_swiper.dart';
import '../../ad/ad_station_page.dart';
import '../../common/data/temp_user_session.dart'; // 강화군/문화의거리 가상 주소 세션 임포트
import '../../road/data/road_mock_data.dart'; // 진짜 로드 데이터셋 임포트
import '../../road/data/place_mock_data.dart'; // 진짜 마스터 가게 데이터셋 임포트

class HomeContentView extends StatefulWidget {
  const HomeContentView({super.key});

  @override
  State<HomeContentView> createState() => _HomeContentViewState();
}

class _HomeContentViewState extends State<HomeContentView> {
  // 세션에 저장해 둔 최초 구동 주소인 '인천광역시 강화군 강화읍'으로 초기화
  String _currentLocationText = initialUserLocation;

  @override
  void initState() {
    super.initState();
    // 앱 처음 진입 시 최초 구동 주소를 강제로 바인딩합니다.
    _currentLocationText = initialUserLocation;
  }

  // 🧠 [실시간 최단거리 정복 정렬]: 내 위치에서 가장 가까운 가게를 가진 순서대로 정렬 후 '상위 5개'만 한정 슬라이싱
  List<Map<String, dynamic>> get _getClosestTopFiveRoads {
    List<Map<String, dynamic>> calculatedList = [];
    final allCourses = [...regionCourses, ...menuCourses];

    for (var course in allCourses) {
      final matchedPlaces = masterPlaces
          .where((place) => course.placeIds.contains(place.placeId))
          .toList();

      if (matchedPlaces.isEmpty) continue;

      // 각 로드 내 매칭되는 가게 중 가장 가까운 가게 한 개 추출 (distanceValue 오름차순)
      matchedPlaces.sort((a, b) => a.distanceValue.compareTo(b.distanceValue));
      final nearestPlace = matchedPlaces.first;

      calculatedList.add({
        'course': course,
        'nearestPlace': nearestPlace,
        'distanceValue': nearestPlace.distanceValue,
      });
    }

    // 내 위치에서 '가장 가까운 거리' 기준 정렬 (가장 가까운 미터값 순 오름차순 정렬)
    calculatedList.sort((a, b) => a['distanceValue'].compareTo(b['distanceValue']));

    // 딱 5개만 동적 노출하도록 컷오프
    return calculatedList.take(5).toList();
  }

  // 📍 [위치 정보 실시간 재설정 시나리오 작동부]: 강화읍 ➔ 부평 문화의거리로 보정 세팅
  void _handleResetLocation() {
    setState(() {
      _currentLocationText = updatedUserLocation; // 갱신용 부평 문화의거리 변수로 이식 갱신!
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('GPS 정보를 통해 현재 위치 정보가 데이터베이스에 반영되었습니다.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // [실데이터 6선]: 가상 데이터를 지워내고 마스터 데이터셋에서 진짜 상위 6대 매장을 실시간 수급합니다!
    final List<PlaceData> stampVerifiablePlaces = masterPlaces.take(6).toList();
    final recommendedRoads = _getClosestTopFiveRoads;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. 상단 바 (로고 이미지 옆 영문명 나란히 조합형 레이아웃 탑재)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 🆕 로고 이미지 + "YamYam Road" 텍스트 가로 배치 구현
                Row(
                  children: [
                    Image.asset(
                      'assets/temp_images/yamyam_logo.png',
                      height: 36,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // 이미지 셋이 아직 없을 때는 귀여운 단일 이모지 체리 하나만 쏙 돌려주어 텍스트 중복 방지!
                        return const Text(
                          '🍒',
                          style: TextStyle(fontSize: 22),
                        );
                      },
                    ),
                    const SizedBox(width: 8), // 이미지와 영문 브랜드명 사이 세련된 간격 설정
                    Text(
                      'YamYam Road',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF504D46),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TopCircleButton(
                      text: '알림',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('새로운 알림이 없습니다.')),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    TopCircleButton(
                      text: '프로필\n이미지',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('마이페이지로 이동합니다.')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. 내 위치 설정 바
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: LocationBar(
              currentLocation: _currentLocationText,
              onResetLocation: _handleResetLocation,
            ),
          ),

          const SizedBox(height: 20),

          // 3. 스탬프 인증 대시보드 카드
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

          // 4. 섹션 타이틀
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.orange[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '내 위치 기반 추천 로드',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 5. 추천 로드 포켓몬 스와이퍼
          HomeRoadSwiper(recommendedRoads: recommendedRoads),

          const SizedBox(height: 16),

          // 6. 하단 광고 배너
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