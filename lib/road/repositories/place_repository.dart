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

  /// [14-1단계] 현재 위치 기준 주변 제휴 스탬프 매장 조회 (Geohash 5자리 정밀 스캔 & 2km 필터링)
  ///
  /// - [userLat], [userLng]: 현재 사용자 위도/경도 좌표
  /// - [fetchLimit]: DB 1차 스캔 최대 개수 (기본 100개)
  /// - [resultLimit]: 최종 추출할 매장 수 (기본 10개)
  /// - [maxDistanceMeters]: 최대 허용 거리 (기본 2000m = 2km)
  Future<List<PlaceModel>> fetchNearbyStampPlaces({
    required double userLat,
    required double userLng,
    int fetchLimit = 100,
    int resultLimit = 10,
    double maxDistanceMeters = 2000,
  }) async {
    try {
      // 1. 사용자 좌표 기반으로 5자리 Geohash 격자 접두사 생성 (약 4.9km x 4.9km 영역)
      final String geohashPrefix = _encodeGeohash(userLat, userLng, precision: 5);

      print('🔥 [Firestore 통신] Geohash 주변 스탬프 매장 스캔 중... (기준 좌표: $userLat, $userLng / Geohash Prefix: $geohashPrefix)');

      // 2. Firestore Geohash 범위 쿼리: 10만 개 중 내 주변 격자 매장만 핀포인트 스캔
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('place')
          .where('stampEnabled', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .where('geohash', isGreaterThanOrEqualTo: geohashPrefix)
          .where('geohash', isLessThanOrEqualTo: '$geohashPrefix\uf8ff')
          .limit(fetchLimit)
          .get();

      final List<PlaceModel> placesWithDistance = [];

      for (var doc in snapshot.docs) {
        final place = PlaceModel.fromFirestore(doc);

        // 실측 거리 계산 및 거리 포맷이 적용된 새 모델 생성
        final calculatedPlace =
        place.copyWithCalculatedDistance(userLat, userLng);

        // 3. 실측 거리 2km(2,000m) 이내 매장만 최종 필터링 및 캐시 저장
        if (calculatedPlace.distanceValue <= maxDistanceMeters) {
          _placeCache[calculatedPlace.id] = calculatedPlace;
          placesWithDistance.add(calculatedPlace);
        }
      }

      // 4. 2차 정렬: 내 위치와 가까운 순서(미터 기준 오름차순) 정렬
      placesWithDistance
          .sort((a, b) => a.distanceValue.compareTo(b.distanceValue));

      // 상위 최대 10개 추출
      final List<PlaceModel> result =
      placesWithDistance.take(resultLimit).toList();

      print('⚡ [조회 완료] 내 근처 2km 이내 Geohash 매장 ${result.length}개 추출 성공');
      for (var p in result) {
        print(' - [${p.id}] ${p.name} (${p.distance})');
      }

      return result;
    } catch (e) {
      print('❌ [Error] fetchNearbyStampPlaces 실패: $e');
      rethrow;
    }
  }

  /// 좌표(위도/경도)를 지정된 정밀도의 Geohash 문자열로 변환하는 독립 경량 인코더
  String _encodeGeohash(double lat, double lng, {int precision = 5}) {
    const String base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
    bool isEven = true;
    double latMin = -90.0, latMax = 90.0;
    double lngMin = -180.0, lngMax = 180.0;
    int bit = 0;
    int ch = 0;
    StringBuffer geohash = StringBuffer();

    while (geohash.length < precision) {
      if (isEven) {
        double mid = (lngMin + lngMax) / 2;
        if (lng > mid) {
          ch |= (1 << (4 - bit));
          lngMin = mid;
        } else {
          lngMax = mid;
        }
      } else {
        double mid = (latMin + latMax) / 2;
        if (lat > mid) {
          ch |= (1 << (4 - bit));
          latMin = mid;
        } else {
          latMax = mid;
        }
      }

      isEven = !isEven;
      if (bit < 4) {
        bit++;
      } else {
        geohash.write(base32[ch]);
        bit = 0;
        ch = 0;
      }
    }
    return geohash.toString();
  }

  /// 필요 시 메모리 캐시를 수동으로 비우는 기능 (예: 새로고침 구현 시 사용)
  void clearCache() {
    _placeCache.clear();
  }
}