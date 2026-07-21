import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../common/user_data.dart';

class StampRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 1. 내 전체 스탬프 조회 (Key: placeId, Value: stampData)
  static Future<Map<String, Map<String, dynamic>>> getMyStampsMap() async {
    final String? uid = UserData.uid;
    if (uid == null || uid.isEmpty) return {};

    final snapshot = await _firestore
        .collection('stamp')
        .where('userId', isEqualTo: uid)
        .get();

    Map<String, Map<String, dynamic>> map = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final placeId = data['placeId'] as String?;
      if (placeId != null) {
        map[placeId] = data;
      }
    }
    return map;
  }

  /// 2. 로드 목록 + 내 스탬프 교집합 합산 데이터 실시간 스트림
  static Stream<List<Map<String, dynamic>>> getRoadWithMyStampStream() {
    return _firestore.collection('road').snapshots().asyncMap((roadSnapshot) async {
      // 내 스탬프 맵 가져오기
      final myStamps = await getMyStampsMap();

      List<Map<String, dynamic>> resultList = [];

      for (var doc in roadSnapshot.docs) {
        final data = doc.data();
        data['roadId'] = doc.id;

        // road 컬렉션의 placeIds (해당 로드에 속한 매장 ID 리스트)
        final List<dynamic> placeIds = data['placeIds'] ?? [];
        final int totalCount = data['placeCount'] ?? placeIds.length;

        // 🌟 교집합 계산: 내 스탬프 목록 중 이 로드의 placeIds에 속한 매장이 몇 개인가?
        int myCount = 0;
        for (var pId in placeIds) {
          if (myStamps.containsKey(pId.toString())) {
            myCount++;
          }
        }

        data['myStampCount'] = myCount;
        data['totalStampCount'] = totalCount;

        resultList.add(data);
      }

      return resultList;
    });
  }

  /// 3. 특정 매장 ID 리스트에 해당하는 업체 이름 맵 가져오기 (Key: placeId, Value: placeName)
  static Future<Map<String, String>> getPlaceNames(List<dynamic> placeIds) async {
    if (placeIds.isEmpty) return {};

    // Firestore whereIn은 최대 30개까지 지원하므로 30개씩 끊거나 그대로 전달
    try {
      final snapshot = await _firestore
          .collection('place')
          .where(FieldPath.documentId, whereIn: placeIds)
          .get();

      Map<String, String> placeNames = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        // place 컬렉션의 상호명 필드 이름이 'name' 또는 'storeName'일 수 있습니다. (기본값 'name' 기준)
        final String name = data['name'] ?? data['storeName'] ?? '업체명 없음';
        placeNames[doc.id] = name;
      }
      return placeNames;
    } catch (e) {
      print('업체 이름 조회 오류: $e');
      return {};
    }
  }

  /// 4. DB에서 활성화된 디저트 카테고리 목록 가져오기 (타입 안정성 보장)
  static Future<List<String>> getCategoryNames() async {
    try {
      final snapshot = await _firestore
          .collection('dessert_category')
          .get();

      List<Map<String, dynamic>> items = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final dynamic active = data['isActive'];
        final String? name = data['name'];
        final int order = (data['displayOrder'] as num?)?.toInt() ?? 99;

        // 🌟 boolean true 혹은 string "true" 모두 허용하도록 검사!
        bool isDocActive = (active == true || active.toString().toLowerCase() == 'true');

        if (isDocActive && name != null && name.isNotEmpty) {
          items.add({'name': name, 'order': order});
        }
      }

      // displayOrder 기준 정렬
      items.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));

      List<String> categories = ['전체'];
      for (var item in items) {
        categories.add(item['name'] as String);
      }

      return categories;
    } catch (e) {
      print('카테고리 불러오기 실패: $e');
      // 에러 발생 시 예비용 기본 목록 리턴
      return ['전체', '커피/차', '떡/한과', '빵/도넛', '아이스크림/빙수', '토스트/샌드위치/샐러드'];
    }
  }

  /// 5. DB에서 활성화된 지역 목록 가져오기 (타입 예외 완벽 대응)
  static Future<List<String>> getRegionNames() async {
    try {
      final snapshot = await _firestore.collection('region').get();

      List<Map<String, dynamic>> items = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final dynamic active = data['isActive'];
        final String? name = data['name'];

        // 🌟 displayOrder가 문자열 "6"이든 숫자 6이든 안전하게 int로 변환
        final dynamic orderRaw = data['displayOrder'];
        int order = 99;
        if (orderRaw is num) {
          order = orderRaw.toInt();
        } else if (orderRaw != null) {
          order = int.tryParse(orderRaw.toString()) ?? 99;
        }

        // 🌟 boolean true 혹은 string "true" 모두 허용
        bool isDocActive = (active == true || active.toString().toLowerCase() == 'true');

        if (isDocActive && name != null && name.isNotEmpty) {
          items.add({'name': name, 'order': order});
        }
      }

      // displayOrder 기준 오름차순 정렬
      items.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));

      List<String> regions = ['전체'];
      for (var item in items) {
        regions.add(item['name'] as String);
      }

      print('🌟 불러온 지역 목록 (${regions.length}개): $regions'); // 디버깅용 콘솔 로그
      return regions;
    } catch (e) {
      print('❌ 지역 목록 불러오기 실패: $e');
      // 예외 발생 시 비상용 기본 리스트 반환
      return [
        '전체', '서울', '경기', '인천', '강원', '세종', '대전', '충북', '충남',
        '광주', '전북', '전남', '부산', '대구', '울산', '경북', '경남', '제주'
      ];
    }
  }

  /// 6. 내 최근 수집 스탬프 최대 5개 조회 (복합 인덱스 에러 회피 적용)
  static Stream<List<Map<String, dynamic>>> getMyLatest5StampsStream() {
    return FirebaseFirestore.instance
        .collection('stamp')
        .where('userId', isEqualTo: UserData.uid) // 🌟 orderBy와 limit을 제거 (단일 조건만 사용)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> result = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final String? placeId = data['placeId']?.toString();
        String storeName = '매장';

        // placeId로 가게 이름 가져오기
        if (placeId != null && placeId.isNotEmpty) {
          try {
            var placeDoc = await FirebaseFirestore.instance.collection('place').doc(placeId).get();
            if (placeDoc.exists) {
              final placeData = placeDoc.data();
              storeName = placeData?['name'] ?? placeData?['storeName'] ?? storeName;
            }
          } catch (_) {}
        }

        result.add({
          'stampId': doc.id,
          'storeName': storeName,
          'issuedAt': data['issuedAt'],
        });
      }

      // 🌟 [핵심] Dart 리스트 단에서 최신순(내림차순)으로 직접 정렬합니다!
      result.sort((a, b) {
        final Timestamp? timeA = a['issuedAt'] as Timestamp?;
        final Timestamp? timeB = b['issuedAt'] as Timestamp?;

        if (timeA == null && timeB == null) return 0;
        if (timeA == null) return 1;
        if (timeB == null) return -1;

        return timeB.compareTo(timeA); // 최신 날짜가 위로 오도록 내림차순 정렬
      });

      // 🌟 상위 최대 5개까지만 자르기
      if (result.length > 5) {
        result = result.sublist(0, 5);
      }

      return result;
    });
  }
}