import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../login/login_screen.dart';
import 'top_circle_button.dart';
import 'location_bar.dart';
import 'ad_banner.dart';
import 'home_stamp_dashboard.dart';
import 'home_road_swiper.dart';
import '../../ad/ad_station_page.dart';
import '../../common/user_data.dart';
import '../../common/data/temp_user_session.dart'; // 강화군/문화의거리 가상 주소 세션 임포트
import '../../road/data/road_mock_data.dart'; // 진짜 로드 데이터셋 임포트
import '../../road/data/place_mock_data.dart'; // 진짜 마스터 가게 데이터셋 임포트

class HomeContentView extends StatefulWidget {
  final ValueChanged<int> onTabChanged;

  const HomeContentView({
    super.key,
    required this.onTabChanged, // 🌟 필수 매개변수로 지정
  });

  @override
  State<HomeContentView> createState() => _HomeContentViewState();
}

class _HomeContentViewState extends State<HomeContentView> {
  // 세션에 저장해 둔 최초 구동 주소인 '인천광역시 강화군 강화읍'으로 초기화
  String _currentLocationText = initialUserLocation;

  // 🆕 로그인 상태 관리: null이면 비로그인
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    // 앱 처음 진입 시 최초 구동 주소를 강제로 바인딩합니다.
    _currentLocationText = initialUserLocation;
    _loadCurrentUser(); // 🆕 앱 진입 시 저장된 세션으로 로그인 상태 복원
  }

  // 🆕 현재 유저 정보 조회 (비로그인이면 null)
  Future<void> _loadCurrentUser() async {
    final user = await AuthService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  // 🌟 통합 로직: 프로필/로그인 버튼 탭 처리
  Future<void> _onProfileButtonTap() async {
    if (_currentUser != null) {
      // 로그인 상태라면 개발자님이 만드신 콜백을 통해 마이페이지(4번 탭)로 이동!
      widget.onTabChanged(4);
      return;
    }

    // 비로그인 상태라면 로그인 화면으로 이동
    final bool? loginSuccess = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );

    if (loginSuccess == true) {
      await _loadCurrentUser(); // 로그인 성공 → 프로필로 전환
    }
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

      matchedPlaces.sort((a, b) => a.distanceValue.compareTo(b.distanceValue));
      final nearestPlace = matchedPlaces.first;

      calculatedList.add({
        'course': course,
        'nearestPlace': nearestPlace,
        'distanceValue': nearestPlace.distanceValue,
      });
    }

    calculatedList.sort((a, b) => a['distanceValue'].compareTo(b['distanceValue']));

    return calculatedList.take(5).toList();
  }

  // 📍 [위치 정보 실시간 재설정 시나리오 작동부]: 강화읍 ➔ 부평 문화의거리로 보정 세팅
  void _handleResetLocation() {
    setState(() {
      _currentLocationText = updatedUserLocation;
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
    final List<PlaceData> stampVerifiablePlaces = masterPlaces.take(6).toList();
    final recommendedRoads = _getClosestTopFiveRoads;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/temp_images/yamyam_logo.png',
                      height: 36,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Text(
                          '🍒',
                          style: TextStyle(fontSize: 22),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text(
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

                    // 🌟 UI 통합: 로그인 안 했으면 버튼, 했으면 예쁜 프로필 사진 표시
                    _currentUser == null
                        ? OutlinedButton(
                      onPressed: _onProfileButtonTap,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: const StadiumBorder(),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: const Text(
                        '로그인',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF504D46)),
                      ),
                    )
                        : GestureDetector(
                      onTap: _onProfileButtonTap, // 누르면 윗부분 함수를 통해 4번 탭으로 이동
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300, width: 1),
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFF5F5F5),
                          child: _currentUser!.profileImageUrl == null
                              ? const Icon(Icons.person_outline, size: 24, color: Colors.grey)
                              : ClipOval(
                            child: Image.network(
                              _currentUser!.profileImageUrl!,
                              width: 38,
                              height: 38,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.person_outline, size: 24, color: Colors.grey);
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: LocationBar(
              currentLocation: _currentLocationText,
              onResetLocation: _handleResetLocation,
            ),
          ),

          const SizedBox(height: 20),

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

          HomeRoadSwiper(recommendedRoads: recommendedRoads),

          const SizedBox(height: 16),

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