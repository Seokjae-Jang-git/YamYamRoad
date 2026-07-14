import 'package:flutter/material.dart';
import 'widgets/top_circle_button.dart';
import 'widgets/location_bar.dart';
import 'widgets/theme_carousel.dart';
import 'widgets/ad_banner.dart';
import 'widgets/bottom_circle_tab_bar.dart';
import 'widgets/stamp_verification_dialog.dart';
import '../ad/ad_station_page.dart'; // 🆕 오직 이 파일만 상위 폴더(../)로 거슬러 올라가서 임포트합니다!

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
            // 팝업 닫기
            Navigator.pop(context);

            // 디버그 콘솔에 placeId 명시적으로 확인 출력
            debugPrint('================================================');
            debugPrint('부모 화면 수신 데이터 [Selected Place ID]: ${selectedPlace.placeId}');
            debugPrint('================================================');

            // 화면상 피드백 유지
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
                          onPressed: _showStampVerificationPopup,
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
                    // 빈 광고 충전소 페이지로 화면 라우팅 이동
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