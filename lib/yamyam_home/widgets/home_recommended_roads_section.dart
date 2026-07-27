import 'package:flutter/material.dart';
import '../../road/models/road.dart';
import '../../services/road_service.dart';
import 'home_road_swiper.dart';

/// 내 위치 기반 추천 로드 섹션 (타이틀 + DB 스트림 구독 + 스위퍼)
class HomeRecommendedRoadsSection extends StatelessWidget {
  final double userLat;
  final double userLng;

  const HomeRecommendedRoadsSection({
    super.key,
    required this.userLat,
    required this.userLng,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. 섹션 타이틀 Header
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

        // 2. Firestore 실시간 스트림 연동 (RoadService를 통해 거리 오름차순 정렬 상위 5개 수신)
        StreamBuilder<List<Road>>(
          stream: RoadService.getRecommendedRoadsStream(
            userLat: userLat,
            userLng: userLng,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 220,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                ),
              );
            }

            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox(
                height: 220,
                child: Center(child: Text('추천 코스 데이터를 불러올 수 없습니다.')),
              );
            }

            final topFiveRoads = snapshot.data!;

            return HomeRoadSwiper(
              recommendedRoads: topFiveRoads,
              userLat: userLat,
              userLng: userLng,
            );
          },
        ),
      ],
    );
  }
}