import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../road/models/road.dart';
import 'home_road_swiper.dart';

/// 내 위치 기반 추천 로드 섹션 (타이틀 + DB 스트림 조회 + 거리 정렬 + 스위퍼)
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

        // 2. Firestore 실시간 스트림 연동 (거리 오름차순 정렬 상위 5개)
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('road').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 220,
                child: Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                ),
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
      ],
    );
  }
}