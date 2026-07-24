import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/place_model.dart';

class PlaceRepository {
  final FirebaseFirestore _firestore;

  // 💡 static을 추가하여 PlaceRepository 인스턴스가 새로 생성되어도 캐시 메모리가 유지되도록 합니다.
  static final Map<String, PlaceModel> _placeCache = {};

  PlaceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 코스의 placeIds 목록에 해당하는 장소 문서들을 가져옵니다.
  /// (캐시를 먼저 확인하고, 없는 데이터만 Firestore에서 조회합니다.)
  Future<List<PlaceModel>> fetchPlacesByIds(List<String> placeIds) async {
    if (placeIds.isEmpty) return [];

    try {
      // 1. 요청된 ID 중 캐시에 없는 ID만 필터링합니다.
      final List<String> missingIds =
      placeIds.where((id) => !_placeCache.containsKey(id)).toList();

      // 2. 캐시에 없는 ID가 하나라도 있다면 해당 데이터만 Firestore에서 가져옵니다.
      if (missingIds.isNotEmpty) {
        print('🔥 [Firestore 통신] 새로 불러올 장소 수: ${missingIds.length}개 ($missingIds)');

        final futures = missingIds
            .map((id) => _firestore.collection('place').doc(id).get());
        final snapshots = await Future.wait(futures);

        for (var doc in snapshots) {
          if (doc.exists && doc.data() != null) {
            final place = PlaceModel.fromFirestore(doc);
            // 새로 읽어온 장소를 클래스 공용 static 캐시에 보관
            _placeCache[doc.id] = place;
          }
        }
      } else {
        print('⚡ [메모리 캐시 사용] Firestore 통신 없이 캐시 데이터로 즉시 반환합니다.');
      }

      // 3. 원래 요청했던 placeIds 순서대로 캐시에서 꺼내어 리스트로 조합합니다.
      final List<PlaceModel> result = [];
      for (final id in placeIds) {
        if (_placeCache.containsKey(id)) {
          result.add(_placeCache[id]!);
        }
      }

      return result;
    } catch (e) {
      print('Error fetching places by ids: $e');
      rethrow;
    }
  }

  /// [14-1단계] 현재 위치 기준 주변 제휴 스탬프 매장 조회 (가장 가까운 순 Top 10)
  ///
  /// - [userLat], [userLng]: 현재 사용자 위도/경도 좌표
  /// - [fetchLimit]: DB 1차 스캔 최대 개수 (기본 50개)
  /// - [resultLimit]: 최종 추출할 매장 수 (기본 10개)
  Future<List<PlaceModel>> fetchNearbyStampPlaces({
    required double userLat,
    required double userLng,
    int fetchLimit = 50,
    int resultLimit = 10,
  }) async {
    try {
      // 1차 위도 범위 지정: 약 ±0.06도 (남북 약 13km 구간 집중 스캔)
      final double minLat = userLat - 0.06;
      final double maxLat = userLat + 0.06;

      print('🔥 [Firestore 통신] 주변 스탬프 매장 스캔 중... (기준 위도: $userLat, 범위: $minLat ~ $maxLat)');

      // Firestore 1차 쿼리: 스탬프 가능 & 영업 중 & 위도 범위 조건
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('place')
          .where('stampEnabled', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .where('lat', isGreaterThanOrEqualTo: minLat)
          .where('lat', isLessThanOrEqualTo: maxLat)
          .limit(fetchLimit)
          .get();

      final List<PlaceModel> placesWithDistance = [];

      for (var doc in snapshot.docs) {
        final place = PlaceModel.fromFirestore(doc);

        // 실측 거리 계산 및 거리 포맷이 적용된 새 모델 생성
        final calculatedPlace =
        place.copyWithCalculatedDistance(userLat, userLng);

        // 20km(20,000m) 이내 매장 선택 및 메모리 캐시 저장
        if (calculatedPlace.distanceValue <= 20000) {
          _placeCache[calculatedPlace.id] = calculatedPlace;
          placesWithDistance.add(calculatedPlace);
        }
      }

      // 2차 정렬: 내 위치와 가까운 순서(미터 기준 오름차순) 정렬
      placesWithDistance
          .sort((a, b) => a.distanceValue.compareTo(b.distanceValue));

      // 상위 10개 추출
      final List<PlaceModel> result =
      placesWithDistance.take(resultLimit).toList();

      print('⚡ [조회 완료] 내 근처 스탬프 매장 ${result.length}개 추출 성공');
      for (var p in result) {
        print(' - [${p.id}] ${p.name} (${p.distance})');
      }

      return result;
    } catch (e) {
      print('❌ [Error] fetchNearbyStampPlaces 실패: $e');
      rethrow;
    }
  }

  /// 필요 시 메모리 캐시를 수동으로 비우는 기능 (예: 새로고침 구현 시 사용)
  void clearCache() {
    _placeCache.clear();
  }
}