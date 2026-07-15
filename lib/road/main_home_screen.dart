import 'package:flutter/material.dart';
import 'widgets/top_circle_button.dart';
import 'widgets/location_bar.dart';
import 'widgets/theme_carousel.dart';
import 'widgets/ad_banner.dart';
import '../common/bottom_circle_tab_bar.dart';
import 'widgets/stamp_verification_dialog.dart';
import '../ad/ad_station_page.dart';

// TODO: 실제 로그인 상태 관리 방식에 맞게 교체하세요.
// - firebase_auth 쓰는 경우: FirebaseAuth.instance.currentUser != null
// - Provider/Riverpod 쓰는 경우: ref.watch(authProvider).isLoggedIn 등
// - 자체 토큰 저장 방식이면: SharedPreferences에 저장된 accessToken 존재 여부
class LocalAuthState {
  static bool isLoggedIn = false; // 임시 값 (기본: 비로그인)
  static String? profileImageUrl; // 로그인 시 서버에서 받아온 프로필 이미지 URL
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentTabIndex = 0;
  String _currentLocationText = '[자동 위치 설정]\n(e.g., 강남구 역삼동)';

  final List<String> _themes = [
    '디저트 정복 테마 1',
    '디저트 정복 테마 2',
    '디저트 정복 테마 3',
    '디저트 정복 테마 4',
    '디저트 정복 테마 5',
  ];

  // 근처 인증 가능 업체 가상 데이터 리스트
  final List<VerifiablePlace> _mockVerifiablePlaces = [
    const VerifiablePlace(
      placeId: 'place_001',
      name: '얌얌 마카롱 부평점',
      category: '마카롱/구움과자',
      distance: '150m 이내',
      rating: 4.8,
      stampCount: 120,
    ),
    const VerifiablePlace(
      placeId: 'place_002',
      name: '앤티크 케이크 팩토리',
      category: '조각케이크/디저트',
      distance: '340m 이내',
      rating: 4.5,
      stampCount: 85,
    ),
    const VerifiablePlace(
      placeId: 'place_003',
      name: '도넛홀릭 문화의거리점',
      category: '도넛/베이커리',
      distance: '420m 이내',
      rating: 4.2,
      stampCount: 210,
    ),
  ];

  void _handleResetLocation() {
    setState(() {
      _currentLocationText = '인천광역시 부평구 문화의거리\n(최신 위치 갱신 완료)';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('GPS 정보를 통해 현재 위치 정보가 데이터베이스에 반영되었습니다.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // 스탬프 인증 팝업 호출 함수
  void _showStampVerificationPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return StampVerificationDialog(
          places: _mockVerifiablePlaces,
          onPlaceSelected: (selectedPlace) {
            Navigator.pop(context);

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
        );
      },
    );
  }

  // 우측 상단 프로필 영역 탭 처리
  // - 비로그인: 로그인 화면으로 이동
  // - 로그인: 마이페이지로 이동
  void _handleProfileTap() {
    if (LocalAuthState.isLoggedIn) {
      Navigator.pushNamed(context, '/mypage');
    } else {
      // ⚠️ main.dart의 routes 테이블에 등록된 이름('/login')과 반드시 일치해야 합니다.
      Navigator.pushNamed(context, '/login').then((_) {
        // 로그인 화면에서 돌아왔을 때 로그인 상태가 바뀌었을 수 있으므로 갱신
        setState(() {});
      });
    }
  }

  // 우측 상단 프로필 영역 위젯
  // - 비로그인: '로그인' 텍스트 버튼 (TopCircleButton)
  // - 로그인: 프로필 이미지 원형 아바타
  Widget _buildProfileArea() {
    if (LocalAuthState.isLoggedIn) {
      return GestureDetector(
        onTap: _handleProfileTap,
        child: CircleAvatar(
          radius: 22,
          backgroundColor: Colors.grey[200],
          backgroundImage: LocalAuthState.profileImageUrl != null
              ? NetworkImage(LocalAuthState.profileImageUrl!)
              : null,
          child: LocalAuthState.profileImageUrl == null
              ? const Icon(Icons.person, color: Colors.grey, size: 22)
              : null,
        ),
      );
    }

    return TopCircleButton(
      text: '로그인',
      onTap: _handleProfileTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 상단 바 (AppBar 영역)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                      ),
                      child: const Text(
                        'YamYam Map 로그',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
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
                        _buildProfileArea(), // 🔁 로그인 상태에 따라 로그인 버튼 / 프로필 이미지 분기
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // 2. 내 위치 설정 바
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: LocationBar(
                  currentLocation: _currentLocationText,
                  onResetLocation: _handleResetLocation,
                ),
              ),

              const SizedBox(height: 24),

              // 스탬프 인증 대시보드 카드
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.blue, width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '지금 매장에 계신가요?',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '근처 제휴 업체 스탬프 인증하기',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          onPressed: () {
                            // 스탬프 인증은 로그인 필요 기능이므로 비로그인 시 로그인 화면으로 유도
                            if (!LocalAuthState.isLoggedIn) {
                              Navigator.pushNamed(context, '/login');
                              return;
                            }
                            _showStampVerificationPopup();
                          },
                          child: const Text('인증하기'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 3. 섹션 타이틀
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '내위치 기반 추천 테마',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
              ),

              const SizedBox(height: 16),

              // 4. 중간 캐러셀 영역
              ThemeCarousel(themes: _themes),

              const SizedBox(height: 24),

              // 5. 하단 광고 보고 무료 포인트 받기 배너
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
        ),
      ),
      bottomNavigationBar: BottomCircleTabBar(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
      ),
    );
  }
}