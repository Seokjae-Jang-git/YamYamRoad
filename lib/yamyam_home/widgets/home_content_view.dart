import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home_header.dart';
import 'location_bar.dart';
import 'home_stamp_dashboard.dart';
import 'home_recommended_roads_section.dart';
import 'ad_banner.dart';
import '../../ad/ad_station_page.dart';
import '../../road/models/place_model.dart'; // 🆕 진짜 PlaceModel로 타입 임포트 변경
import '../../providers/user_location_provider.dart';

class HomeContentView extends StatelessWidget {
  final ValueChanged<int> onTabChanged;

  const HomeContentView({
    super.key,
    required this.onTabChanged,
  });

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
            onTabChanged: onTabChanged,
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
              onPlaceSelected: (selectedPlace) {
                // 🌟 placeId -> id (Firestore 문서 고유 ID)로 수정 완료
                debugPrint('================================================');
                debugPrint('부모 화면 수신 데이터 [Selected Place ID]: ${selectedPlace.id}');
                debugPrint('================================================');

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '선택 완료: [${selectedPlace.name}] (ID: ${selectedPlace.id})\n콘솔 로그에 ID가 기록되었습니다.',
                    ),
                    backgroundColor: Colors.blue[800],
                    duration: const Duration(seconds: 3),
                  ),
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

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}