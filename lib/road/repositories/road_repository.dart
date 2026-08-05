import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/road.dart';

/// 커서 기반 페이징 결과를 전달하기 위한 DTO 클래스
class RoadPagedResult {
  final List<Road> roads;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  RoadPagedResult({
    required this.roads,
    required this.lastDocument,
    required this.hasMore,
  });
}

class RoadRepository {
  final FirebaseFirestore _firestore;

  RoadRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 제목(title) 기준 접두사(Prefix) 검색 커서 기반 페이징
  /// - [query]: 검색어 (제목 시작 문자열)
  /// - [lastDocument]: 이전 페이지의 마지막 문서 Snapshot
  /// - [limit]: 한 번에 불러올 데이터 개수 (기본 6개)
  Future<RoadPagedResult> searchRoadsPaged({
    required String query,
    DocumentSnapshot? lastDocument,
    int limit = 6,
  }) async {
    final trimmedQuery = query.trim();

    // 빈 검색어 입력 시 DB 요청 없이 바로 빈 결과 반환
    if (trimmedQuery.isEmpty) {
      return RoadPagedResult(
        roads: [],
        lastDocument: null,
        hasMore: false,
      );
    }

    try {
      // 1. Firestore 제목 기준 범위 쿼리 및 정렬
      Query<Map<String, dynamic>> firestoreQuery = _firestore
          .collection('road')
          .orderBy('title')
          .startAt([trimmedQuery])
          .endAt(['$trimmedQuery\uf8ff']);

      // 2. 다음 페이지 요청 시 커서 위치 지정
      if (lastDocument != null) {
        firestoreQuery = firestoreQuery.startAfterDocument(lastDocument);
      }

      // 3. 페이징 limit 적용 (기본 6개)
      firestoreQuery = firestoreQuery.limit(limit);

      final querySnapshot = await firestoreQuery.get();

      if (querySnapshot.docs.isEmpty) {
        return RoadPagedResult(
          roads: [],
          lastDocument: lastDocument,
          hasMore: false,
        );
      }

      // 4. DocumentSnapshot을 Road 모델 객체로 변환
      final List<Road> roads = querySnapshot.docs
          .map((doc) => Road.fromFirestore(doc))
          .toList();

      final DocumentSnapshot newLastDocument = querySnapshot.docs.last;
      final bool hasMore = querySnapshot.docs.length == limit;

      return RoadPagedResult(
        roads: roads,
        lastDocument: newLastDocument,
        hasMore: hasMore,
      );
    } catch (e) {
      print('RoadRepository.searchRoadsPaged 오류 발생: $e');
      rethrow;
    }
  }

  /// 커서 기반 페이징 및 복합 색인 없는 인메모리 Loop Fetching
  /// - [type]: 'region' (지역별) 또는 'category' (메뉴별)
  /// - [selectedRegion]: 선택된 지역 필터
  /// - [selectedCategory]: 선택된 메뉴 필터
  /// - [sortBy]: 정렬 방식 ('최신순', '이름순')
  /// - [lastDocument]: 이전 페이지의 마지막 문서 Snapshot
  /// - [limit]: 화면에 표시할 최종 목표 데이터 개수 (기본 6개)
  Future<RoadPagedResult> fetchRoadsPaged({
    String type = 'region',
    String? selectedRegion,
    String? selectedCategory,
    String sortBy = '최신순',
    DocumentSnapshot? lastDocument,
    int limit = 6,
  }) async {
    try {
      List<Road> accumulatedRoads = [];
      DocumentSnapshot? currentLastDoc = lastDocument;
      bool hasMoreInDb = true;

      const int batchSize = 12;

      while (accumulatedRoads.length < limit && hasMoreInDb) {
        Query<Map<String, dynamic>> query = _firestore.collection('road');

        // Firestore 기본 단일 색인(createdAt)으로 DB 조회
        query = query.orderBy('createdAt', descending: true);

        if (currentLastDoc != null) {
          query = query.startAfterDocument(currentLastDoc);
        }

        query = query.limit(batchSize);

        final querySnapshot = await query.get();

        if (querySnapshot.docs.isEmpty) {
          hasMoreInDb = false;
          break;
        }

        for (final doc in querySnapshot.docs) {
          currentLastDoc = doc;
          final road = Road.fromFirestore(doc);

          // 1. 대분류 type 검증
          if (road.type != type) continue;

          // 2. 카테고리 필터 검증
          if (type == 'category' &&
              selectedCategory != null &&
              selectedCategory.isNotEmpty &&
              selectedCategory != '전체') {
            if (!road.categoryIds.contains(selectedCategory)) continue;
          }

          // 3. 지역 필터 검증
          if (type == 'region' &&
              selectedRegion != null &&
              selectedRegion.isNotEmpty &&
              selectedRegion != '전체') {
            if (road.regionId != selectedRegion) continue;
          }

          accumulatedRoads.add(road);

          if (accumulatedRoads.length == limit) break;
        }

        if (querySnapshot.docs.length < batchSize) {
          hasMoreInDb = false;
        }
      }

      // 4. 가져온 1개 페이지(6개) 데이터에 대한 정렬
      if (sortBy == '이름순') {
        accumulatedRoads.sort((a, b) => a.title.compareTo(b.title));
      }

      return RoadPagedResult(
        roads: accumulatedRoads,
        lastDocument: currentLastDoc,
        hasMore: hasMoreInDb,
      );
    } catch (e) {
      print('RoadRepository.fetchRoadsPaged 오류 발생: $e');
      rethrow;
    }
  }

  /// 단발성 전체 조회 메서드
  Future<List<Road>> fetchRoads({
    String type = 'region',
    String? selectedRegion,
    String? selectedCategory,
    String sortBy = '최신순',
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('road');

      final querySnapshot = await query.get();

      List<Road> roads = querySnapshot.docs
          .map((doc) => Road.fromFirestore(doc))
          .where((road) {
        if (road.type != type) return false;

        if (type == 'category' &&
            selectedCategory != null &&
            selectedCategory.isNotEmpty &&
            selectedCategory != '전체') {
          return road.categoryIds.contains(selectedCategory);
        }

        if (type == 'region' &&
            selectedRegion != null &&
            selectedRegion.isNotEmpty &&
            selectedRegion != '전체') {
          return road.regionId == selectedRegion;
        }

        return true;
      })
          .toList();

      if (sortBy == '이름순') {
        roads.sort((a, b) => a.title.compareTo(b.title));
      } else {
        roads.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      return roads;
    } catch (e) {
      print('RoadRepository.fetchRoads 오류 발생: $e');
      rethrow;
    }
  }
}