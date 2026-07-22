import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'top_circle_button.dart';
import 'location_bar.dart';
import 'ad_banner.dart';
import 'home_stamp_dashboard.dart';
import 'home_road_swiper.dart';
import '../../ad/ad_station_page.dart';
import '../../common/user_data.dart';
import '../../common/data/temp_user_session.dart';
import '../../road/data/place_mock_data.dart';
import '../../road/models/road.dart';
import '../../services/auth_service.dart';
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
    _loadProfileIfNeeded();
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

  // UserData 프로필 정보 로드
  Future<void> _loadProfileIfNeeded() async {
    final String? currentUid = AuthService.currentUser?.uid;
    if (currentUid == null) return;

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

  // 프로필 아이콘 탭 시 "마이페이지" / "로그아웃" 팝업 메뉴 표시
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

    // 에뮬레이터 기본 위치 (서울 중심부) - GPS 조회가 안 되었을 경우 fallback
    final double userLat = _currentPosition?.latitude ?? 37.5665;
    final double userLng = _currentPosition?.longitude ?? 126.9780;

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

          // Firestore 실시간 스트림 연동: 거리 기반 오름차순 정렬 상위 5개 추출
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('road').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator(color: Colors.orange)),
                );
              }

              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SizedBox(
                  height: 220,
                  child: Center(child: Text('추천 코스 데이터를 불러올 수 없습니다.')),
                );
              }

              // Firestore 문서들을 Road 객체로 변환
              final List<Road> roads = snapshot.data!.docs
                  .map((doc) => Road.fromFirestore(doc))
                  .toList();

              // 내 위치(userLat, userLng)로부터 최단 거리 순 정렬
              roads.sort((a, b) {
                final distA = a.getMinDistanceKm(userLat, userLng);
                final distB = b.getMinDistanceKm(userLat, userLng);
                return distA.compareTo(distB);
              });

              // 상위 5개 추출
              final topFiveRoads = roads.take(5).toList();

              return HomeRoadSwiper(
                recommendedRoads: topFiveRoads,
                userLat: userLat,
                userLng: userLng,
              );
            },
          ),

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