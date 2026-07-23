import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/road.dart';

class RoadRepository {
  final FirebaseFirestore _firestore;

  RoadRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 지역별/메뉴별 단일 필터 및 정렬 조건에 맞추어 코스 목록 조회
  /// - [type]: 'region' (지역별) 또는 'category' (메뉴별)
  /// - [selectedRegion]: 선택된 지역 (예: '서울', '인천' 등)
  /// - [selectedCategory]: 선택된 메뉴 카테고리 (예: '커피/차', '빵/도넛' 등)
  /// - [sortBy]: 정렬 방식 ('최신순', '이름순', '스탬프 순', '포인트 순')
  Future<List<Road>> fetchRoads({
    String type = 'region',
    String? selectedRegion,
    String? selectedCategory,
    String sortBy = '최신순',
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('road');

      // 1. 메뉴별 탭일 경우 DB에서 type: 'category' 데이터 조건부 1차 필터링
      if (type == 'category') {
        query = query.where('type', isEqualTo: 'category');
      }

      // 2. 선택된 카테고리/지역 필터 적용
      if (type == 'category' &&
          selectedCategory != null &&
          selectedCategory.isNotEmpty &&
          selectedCategory != '전체') {
        query = query.where('categoryIds', arrayContains: selectedCategory);
      } else if (type == 'region' &&
          selectedRegion != null &&
          selectedRegion.isNotEmpty &&
          selectedRegion != '전체') {
        query = query.where('regionId', isEqualTo: selectedRegion);
      }

      // 3. 파이어스토어에서 데이터 가져오기
      final querySnapshot = await query.get();

      // 4. DocumentSnapshot -> Road 객체 변환 및 In-Memory type 검증
      // (기존 DB 데이터 중 type 필드가 생략된 문서는 Road 모델에서 기본값 'region'으로 안전하게 수용됨)
      List<Road> roads = querySnapshot.docs
          .map((doc) => Road.fromFirestore(doc))
          .where((road) => road.type == type)
          .toList();

      // 5. 앱 내(In-Memory) 정렬 처리 (Firestore 색인 생성 오류 방지)
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