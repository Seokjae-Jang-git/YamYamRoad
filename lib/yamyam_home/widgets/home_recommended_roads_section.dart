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

  // 브랜드 공식 컬러 상수 정의
  static const Color coralRed = Color(0xFFFF6B57);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color subTextColor = Color(0xFF7A6B63);

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
                  color: coralRed,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '내 위치 기반 추천 로드',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: deepChocolate,
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
                  child: CircularProgressIndicator(color: coralRed),
                ),
              );
            }

            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox(
                height: 220,
                child: Center(
                  child: Text(
                    '추천 코스 데이터를 불러올 수 없습니다.',
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 14,
                    ),
                  ),
                ),
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