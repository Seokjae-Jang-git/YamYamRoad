import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home_header.dart';
import 'location_bar.dart';
import 'home_stamp_dashboard.dart';
import 'home_recommended_roads_section.dart';
import 'ad_banner.dart';
import 'ai_recommendation_banner.dart';
import '../../AI/ai_recommendation_page.dart';
import '../../ad/ad_station_page.dart';
import '../../road/models/place_model.dart';
import '../../providers/user_location_provider.dart';
import '../../stamp/logic/stamp_verification_navigator.dart';
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
  @override
  Widget build(BuildContext context) {
    // 전역 위치 상태 구독 (추천 로드 섹션 연동용)
    final locationProvider = context.watch<UserLocationProvider>();

    // 안전한 Getter(userLat, userLng) 사용
    final double userLat = locationProvider.userLat;
    final double userLng = locationProvider.userLng;

    // 🌟 버튼 클릭 시 Firestore 위치 기반으로 최신 매장 10개를 직접 조회하므로 기본값은 빈 리스트 전달
    const List<PlaceModel> stampVerifiablePlaces = [];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. 상단 헤더 (로고, 알림 버튼, 프로필 메뉴)
          HomeHeader(
            onTabChanged: widget.onTabChanged,
          ),

          // 🐛 [디버그 전용] 가짜 위치(Mock Location) 개발자 토글 스위치 바
          if (kDebugMode)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bug_report, size: 18, color: Colors.amber.shade900),
                      const SizedBox(width: 8),
                      Text(
                        '가짜 위치 사용 (서초구청)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: LocationService.useMockLocation,
                    activeColor: Colors.amber.shade800,
                    onChanged: (bool value) {
                      setState(() {
                        LocationService.setMockLocation(value);
                      });
                      // 위치 토글 상태 변경 시 Provider의 refreshLocation 호출
                      try {
                        context
                            .read<UserLocationProvider>()
                            .refreshLocation(forceRefresh: true);
                      } catch (_) {}
                    },
                  ),
                ],
              ),
            ),

          // 2. 위치 안내 및 위치 재설정 바 (Provider 내부 구독)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: LocationBar(),
          ),

          const SizedBox(height: 20),

          // 3. 스탬프 인증 현황 대시보드
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: HomeStampDashboard(
              verifiablePlaces: stampVerifiablePlaces,
              onPlaceSelected: (selectedPlace) async {
                Navigator.of(context).pop();
                await StampVerificationNavigator.open(
                  context: context,
                  placeId: selectedPlace.id,
                  placeName: selectedPlace.name,
                );
              },
            ),
          ),

          const SizedBox(height: 28),

          // 4. 내 위치 기반 추천 로드 섹션 (Provider 좌표 연동)
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

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: AiRecommendationBanner(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AiRecommendationPage(
                      userId: AuthService.currentUser!.uid,
                    ),
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
