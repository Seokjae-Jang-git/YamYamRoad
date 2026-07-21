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
}