import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/road.dart';

class RoadRepository {
  final FirebaseFirestore _firestore;

  RoadRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 지역별/메뉴별 단일 필터 및 정렬 조건에 맞추어 코스 목록 조회
  Future<List<Road>> fetchRoads({
    String? selectedRegion,
    String? selectedCategory,
    String sortBy = '최신순',
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('road');

      // 1. 선택된 탭 조건에 맞춰 단일 조건 쿼리 적용 (최신 규격 regionId 기준)
      if (selectedRegion != null &&
          selectedRegion.isNotEmpty &&
          selectedRegion != '전체') {
        query = query.where('regionId', isEqualTo: selectedRegion);
      } else if (selectedCategory != null &&
          selectedCategory.isNotEmpty &&
          selectedCategory != '전체') {
        query = query.where('categoryIds', arrayContains: selectedCategory);
      }

      // 2. 파이어스토어에서 데이터 가져오기
      final querySnapshot = await query.get();

      // 3. DocumentSnapshot -> Road 객체 목록 변환 (Fallback 매핑 적용)
      List<Road> roads = querySnapshot.docs
          .map((doc) => Road.fromFirestore(doc))
          .toList();

      // 4. 앱 내(In-Memory) 정렬 처리 (Firestore 색인 생성 오류 방지)
      switch (sortBy) {
        case '이름순':
          roads.sort((a, b) => a.title.compareTo(b.title));
          break;
        case '스탬프 순':
        case '포인트 순':
          roads.sort((a, b) => b.stampRewardPoint.compareTo(a.stampRewardPoint));
          break;
        case '최신순':
        default:
          roads.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
      }

      return roads;
    } catch (e) {
      print('RoadRepository.fetchRoads 오류 발생: $e');
      rethrow;
    }
  }
}