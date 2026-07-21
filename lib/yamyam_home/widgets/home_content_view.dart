import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../road/models/place_model.dart';
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
import '../../services/auth_service.dart';

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

  @override
  void initState() {
    super.initState();
    // 앱 처음 진입 시 최초 구동 주소를 강제로 바인딩합니다.
    _currentLocationText = initialUserLocation;
    // 🌟 로그인 직후 홈 화면에 바로 진입했을 때도 프로필(닉네임/사진)이
    // 반영되도록, 마이페이지를 열지 않아도 여기서 미리 불러옵니다.
    _loadProfileIfNeeded();
  }

  // 🌟 UserData에 아직 현재 로그인한 사용자의 정보가 없으면 Firestore에서 불러와 채웁니다.
  // (마이페이지 화면의 _loadUserData()와 같은 로직 - 두 곳 모두 동일하게 유지해주세요)
  Future<void> _loadProfileIfNeeded() async {
    final String? currentUid = AuthService.currentUser?.uid;
    if (currentUid == null) return;

    // 이미 같은 사용자의 정보가 로드되어 있으면 다시 불러올 필요 없음
    if (UserData.uid == currentUid && UserData.nickname != null) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUid).get();
      if (!mounted) return;
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          UserData.uid = currentUid;
          UserData.nickname = data['nickname'] ?? '이름없음';
          UserData.name = data['name'] ?? '';
          UserData.phone = data['phone'] ?? '';
          UserData.profileImagePath = data['profileImageUrl'];
          UserData.isDefaultProfileImage =
          (data['profileImageUrl'] == null || data['profileImageUrl'].toString().isEmpty);
        });
      }
    } catch (e) {
      debugPrint('🔴 홈 화면 프로필 로드 실패: $e');
    }
  }

  // 🧠 [실시간 최단거리 정복 정렬]: 내 위치에서 가장 가까운 가게를 가진 순서대로 정렬 후 '상위 5개'만 한정 슬라이싱
  List<Map<String, dynamic>> get _getClosestTopFiveRoads {
    List<Map<String, dynamic>> calculatedList = [];
    final allCourses = [...regionCourses, ...menuCourses];

    for (var course in allCourses) {
      final matchedPlaces = masterPlaces
      // 🌟 placeIds 널 안전성(Null Safety) 적용
          .where((place) => course.placeIds?.contains(place.placeId) ?? false)
          .toList();

      if (matchedPlaces.isEmpty) continue;

      matchedPlaces.sort((a, b) => a.distanceValue.compareTo(b.distanceValue));
      final nearestPlace = matchedPlaces.first; // PlaceData 타입

      // 🌟 복잡한 변환 코드 싹 지우고 원래 있던 PlaceData를 그냥 넘깁니다!
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

  // 🌟 프로필 아이콘 탭 시 "마이페이지" / "로그아웃" 팝업 메뉴 표시
  void _showProfileMenu(BuildContext context, TapDownDetails details) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(details.globalPosition, details.globalPosition),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        const PopupMenuItem<String>(
          value: 'mypage',
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 18, color: Colors.black87),
              SizedBox(width: 10),
              Text('마이페이지'),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18, color: Colors.redAccent),
              SizedBox(width: 10),
              Text('로그아웃', style: TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
      ],
    ).then((selected) {
      if (selected == 'mypage') {
        widget.onTabChanged(4);
      } else if (selected == 'logout') {
        _confirmLogout(context);
      }
    });
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _handleLogout();
            },
            child: const Text('로그아웃', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 🌟 실제 로그아웃 처리: Firebase 세션 종료 + 로컬 유저 데이터 초기화
  // 화면 전환(로그인 화면으로 이동)은 main.dart의 StreamBuilder(authStateChanges)가
  // signOut() 이후 자동으로 처리합니다. 여기서 수동으로 Navigator를 건드리면
  // StreamBuilder가 관리하는 네비게이터 스택과 충돌해서 재로그인 후 화면 전환이
  // 안 되는 문제가 생기니, 절대 여기서 push/pop을 직접 하지 마세요.
  Future<void> _handleLogout() async {
    try {
      await AuthService.logout();

      UserData.uid = null;
      UserData.nickname = null;
      UserData.name = null;
      UserData.phone = null;
      UserData.profileImagePath = null;
      UserData.isDefaultProfileImage = true;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그아웃 중 오류가 발생했습니다: $e')),
      );
    }
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

                    // 🌟 프로필 탭 시 "마이페이지"/"로그아웃" 팝업 메뉴 표시
                    GestureDetector(
                      onTapDown: (details) => _showProfileMenu(context, details),
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
                          child: UserData.isDefaultProfileImage || UserData.profileImagePath == null
                              ? const Icon(Icons.person_outline, size: 24, color: Colors.grey)
                              : ClipOval(
                            child: Image.network(
                              UserData.profileImagePath!,
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
