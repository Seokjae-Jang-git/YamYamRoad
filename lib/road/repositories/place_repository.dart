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
      final List<String> missingIds = placeIds.where((id) => !_placeCache.containsKey(id)).toList();

      // 2. 캐시에 없는 ID가 하나라도 있다면 해당 데이터만 Firestore에서 가져옵니다.
      if (missingIds.isNotEmpty) {
        print('🔥 [Firestore 통신] 새로 불러올 장소 수: ${missingIds.length}개 ($missingIds)');

        final futures = missingIds.map((id) => _firestore.collection('place').doc(id).get());
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

  /// 필요 시 메모리 캐시를 수동으로 비우는 기능 (예: 새로고침 구현 시 사용)
  void clearCache() {
    _placeCache.clear();
  }
}