import 'package:cloud_firestore/cloud_firestore.dart';

class Road {
  final String id;
  final String title;
  final String description;
  final String regionId;
  final List<String> categoryIds;
  final List<String> roadPlace;
  final String thumbnailUrl;
  final String badgeName;
  final int stampRewardPoint;
  final int estimatedTimeMinutes;
  final List<String> searchKeywords;
  final bool isActive;
  final DateTime createdAt;

  Road({
    required this.id,
    required this.title,
    required this.description,
    required this.regionId,
    required this.categoryIds,
    required this.roadPlace,
    required this.thumbnailUrl,
    required this.badgeName,
    required this.stampRewardPoint,
    required this.estimatedTimeMinutes,
    required this.searchKeywords,
    required this.isActive,
    required this.createdAt,
  });

  /// 파이어스토어 DocumentSnapshot ➔ Road 객체 변환 (하위 호환 Fallback 적용)
  factory Road.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return Road.fromMap(map, doc.id);
  }

  /// Map ➔ Road 객체 변환 (옛날 DB 필드와 새 DB 필드 모두 지원 및 타입 방어)
  factory Road.fromMap(Map<String, dynamic> map, String docId) {
    // DateTime 파싱 헬퍼
    DateTime parseCreatedAt(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is DateTime) {
        return value;
      } else if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    // bool 타입 안전 파싱 헬퍼 (String, num, bool 모두 대응)
    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is String) {
        final lower = value.trim().toLowerCase();
        return lower == 'true' || lower == 'y' || lower == '1';
      }
      if (value is num) {
        return value == 1;
      }
      return true; // 기본값
    }

    return Road(
      id: docId,
      title: map['title']?.toString() ?? '제목 없음',
      description: map['description']?.toString() ?? '',

      // regionId가 없으면 기존 region 필드 탐색
      regionId: map['regionId']?.toString() ?? map['region']?.toString() ?? '전체',

      categoryIds: (map['categoryIds'] is List)
          ? List<String>.from((map['categoryIds'] as List).map((e) => e.toString()))
          : <String>[],

      // roadPlace가 없으면 기존 placeIds 필드 탐색
      roadPlace: (map['roadPlace'] is List)
          ? List<String>.from((map['roadPlace'] as List).map((e) => e.toString()))
          : (map['placeIds'] is List)
          ? List<String>.from((map['placeIds'] as List).map((e) => e.toString()))
          : <String>[],

      // thumbnailUrl이 없으면 기존 imageUrl 필드 탐색
      thumbnailUrl: map['thumbnailUrl']?.toString() ?? map['imageUrl']?.toString() ?? '',

      badgeName: map['badgeName']?.toString() ?? '',

      // stampRewardPoint가 없으면 기존 rewardPoints 필드 탐색
      stampRewardPoint: ((map['stampRewardPoint'] ?? map['rewardPoints']) as num?)?.toInt() ?? 0,

      estimatedTimeMinutes: (map['estimatedTimeMinutes'] as num?)?.toInt() ?? 0,

      searchKeywords: (map['searchKeywords'] is List)
          ? List<String>.from((map['searchKeywords'] as List).map((e) => e.toString()))
          : <String>[],

      isActive: parseBool(map['isActive']),

      createdAt: parseCreatedAt(map['createdAt']),
    );
  }

  /// Road 객체 ➔ 파이어스토어 저장용 Map 변환 (최신 DB 규격 기준)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'regionId': regionId,
      'categoryIds': categoryIds,
      'roadPlace': roadPlace,
      'thumbnailUrl': thumbnailUrl,
      'badgeName': badgeName,
      'stampRewardPoint': stampRewardPoint,
      'estimatedTimeMinutes': estimatedTimeMinutes,
      'searchKeywords': searchKeywords,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}