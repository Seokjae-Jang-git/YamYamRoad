import 'package:cloud_firestore/cloud_firestore.dart';
import '../road/models/road.dart';

/// 로드(추천 코스) 관련 Firestore DB 조회 및 비즈니스 로직 처리 서비스
class RoadService {
  RoadService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 사용자 현재 위치(userLat, userLng)를 기준으로 최단 거리 추천 로드 목록 스트림 반환
  /// - Firestore 'road' 컬렉션을 구독합니다.
  /// - 가져온 데이터를 Road 모델로 변환한 뒤, 사용자 위치와의 거리를 계산하여 최단거리 순으로 정렬합니다.
  /// - 기본적으로 상위 [limit]개(기본값 5개)만 추출합니다.
  static Stream<List<Road>> getRecommendedRoadsStream({
    required double userLat,
    required double userLng,
    int limit = 5,
  }) {
    return _firestore.collection('road').snapshots().map((snapshot) {
      // 1. Firestore 문서를 Road 객체로 변환
      final List<Road> roads = snapshot.docs
          .map((doc) => Road.fromFirestore(doc))
          .toList();

      // 2. 내 위치(userLat, userLng)로부터 최단 거리 순 정렬
      roads.sort((a, b) {
        final distA = a.getMinDistanceKm(userLat, userLng);
        final distB = b.getMinDistanceKm(userLat, userLng);
        return distA.compareTo(distB);
      });

      // 3. 지정된 개수(기본 5개)만큼 추출하여 반환
      return roads.take(limit).toList();
    });
  }
}