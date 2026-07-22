import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 코스 내 가게의 위도/경도 좌표를 표현하는 클래스
class PlaceCoordinate {
  final double lat;
  final double lng;

  PlaceCoordinate({
    required this.lat,
    required this.lng,
  });

  factory PlaceCoordinate.fromMap(Map<String, dynamic> map) {
    return PlaceCoordinate(
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
    };
  }
}

class Road {
  final String id;
  final String title;
  final String description;
  final String regionId;
  final List<String> categoryIds;
  final List<String> roadPlace;
  final List<PlaceCoordinate> placeCoordinates; // 📍 추가: 반정규화된 가게 좌표 리스트
  final String thumbnailUrl;
  final String badgeName;
  final int stampRewardPoint;
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
    required this.placeCoordinates,
    required this.thumbnailUrl,
    required this.badgeName,
    required this.stampRewardPoint,
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

    // placeCoordinates 파싱 헬퍼 (Map, GeoPoint 등 다양한 형태 대응)
    final rawCoordinates = map['placeCoordinates'] as List<dynamic>? ?? [];
    final parsedCoordinates = rawCoordinates.map((e) {
      if (e is Map<String, dynamic>) {
        return PlaceCoordinate.fromMap(e);
      } else if (e is Map) {
        return PlaceCoordinate.fromMap(Map<String, dynamic>.from(e));
      } else if (e is GeoPoint) {
        return PlaceCoordinate(lat: e.latitude, lng: e.longitude);
      }
      return PlaceCoordinate(lat: 0.0, lng: 0.0);
    }).toList();

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

      // 반정규화된 가게 좌표 파싱 결과 할당
      placeCoordinates: parsedCoordinates,

      // thumbnailUrl이 없으면 기존 imageUrl 필드 탐색
      thumbnailUrl: map['thumbnailUrl']?.toString() ?? map['imageUrl']?.toString() ?? '',

      badgeName: map['badgeName']?.toString() ?? '',

      // stampRewardPoint가 없으면 기존 rewardPoints 필드 탐색
      stampRewardPoint: ((map['stampRewardPoint'] ?? map['rewardPoints']) as num?)?.toInt() ?? 0,

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
      'placeCoordinates': placeCoordinates.map((e) => e.toMap()).toList(),
      'thumbnailUrl': thumbnailUrl,
      'badgeName': badgeName,
      'stampRewardPoint': stampRewardPoint,
      'searchKeywords': searchKeywords,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// 📍 추가: 사용자의 현재 위치(위도/경도) 기반으로 코스 내 가게 중 '최단 거리(km)' 연산
  /// 좌표 리스트가 비어있을 경우 double.infinity 반환
  double getMinDistanceKm(double userLat, double userLng) {
    if (placeCoordinates.isEmpty) {
      return double.infinity;
    }

    double minDistance = double.infinity;

    for (final coord in placeCoordinates) {
      final distance = _calculateHaversineDistance(
        userLat,
        userLng,
        coord.lat,
        coord.lng,
      );
      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    return minDistance;
  }

  /// 하버사인(Haversine) 공식을 이용한 두 위경도 좌표 간 거리 계산 (단위: km)
  double _calculateHaversineDistance(
      double lat1,
      double lon1,
      double lat2,
      double lon2,
      ) {
    const double earthRadiusKm = 6371.0;

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180.0;
  }
}