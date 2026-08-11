import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class PlaceModel {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String regionId;
  final List<String> categoryIds;
  final List<String> searchKeywords;
  final bool isActive;
  final String thumbnailUrl;
  final List<String> imageUrls;

  // DB 명세서 기준 추가 필드
  final double ratingAverage; // 평균 평점
  final int stampCount; // 누적 스탬프 수
  final bool stampEnabled; // 스탬프 인증 허용 여부
  final bool waitingNoticeEnabled; // 웨이팅 안내 여부 (DB 저장용)

  // 실시간 거리 연산/표시용 필드
  final double distanceValue; // m 단위 거리 (숫자, 정렬용)
  final String distance; // UI 표시용 문자열 (예: '350m', '1.2km')

  PlaceModel({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.regionId,
    required this.categoryIds,
    required this.searchKeywords,
    required this.isActive,
    this.thumbnailUrl = '',
    this.imageUrls = const [],
    this.ratingAverage = 0.0,
    this.stampCount = 0,
    this.stampEnabled = true,
    this.waitingNoticeEnabled = false,
    this.distanceValue = 0.0,
    this.distance = '0m',
  });

  // UI 호환성 및 연산용 게터
  double get rating => ratingAverage; // 기존 UI 연동 호환용 게터
  String get description => address;

  // 단순화된 규칙: 누적 스탬프 수 300개 이상일 경우 웨이팅 안내 노출
  bool get showWaitingNotice => stampCount >= 300;

  /// 사용자의 현재 GPS 좌표(위도, 경도)를 전달받아 실측 거리가 연산된 새로운 PlaceModel 객체를 반환합니다.
  PlaceModel copyWithCalculatedDistance(double userLat, double userLng) {
    // 가게의 위도/경도가 없거나 기본값(0.0)인 경우 계산 없이 반환
    if (lat == 0.0 && lng == 0.0) return this;

    // Geolocator 패키지를 이용한 직선 거리(m 단위) 연산
    final double distanceInMeters = Geolocator.distanceBetween(
      userLat,
      userLng,
      lat,
      lng,
    );

    // 거리 단위 포맷팅 (1000m 미만 -> m, 1000m 이상 -> km)
    final String formattedDistance = distanceInMeters < 1000
        ? '${distanceInMeters.round()}m'
        : '${(distanceInMeters / 1000).toStringAsFixed(1)}km';

    return PlaceModel(
      id: id,
      name: name,
      address: address,
      lat: lat,
      lng: lng,
      regionId: regionId,
      categoryIds: categoryIds,
      searchKeywords: searchKeywords,
      isActive: isActive,
      thumbnailUrl: thumbnailUrl,
      imageUrls: imageUrls,
      ratingAverage: ratingAverage,
      stampCount: stampCount,
      stampEnabled: stampEnabled,
      waitingNoticeEnabled: waitingNoticeEnabled,
      distanceValue: distanceInMeters,
      distance: formattedDistance,
    );
  }

  // Firestore 문서 데이터를 PlaceModel 객체로 변환
  factory PlaceModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PlaceModel(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
      regionId: data['regionId'] ?? '',
      categoryIds: List<String>.from(data['categoryIds'] ?? []),
      searchKeywords: List<String>.from(data['searchKeywords'] ?? []),
      isActive: data['isActive'] ?? true,
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      // 기존 문서에 필드가 존재하지 않을 경우(null), DB 명세서 지침대로 기본값(0.0, 0) 대입
      ratingAverage: (data['ratingAverage'] as num?)?.toDouble() ?? 0.0,
      stampCount: (data['stampCount'] as num?)?.toInt() ?? 0,
      stampEnabled: data['stampEnabled'] ?? true,
      waitingNoticeEnabled: data['waitingNoticeEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
      'regionId': regionId,
      'categoryIds': categoryIds,
      'searchKeywords': searchKeywords,
      'isActive': isActive,
      'thumbnailUrl': thumbnailUrl,
      'imageUrls': imageUrls,
      'ratingAverage': ratingAverage,
      'stampCount': stampCount,
      'stampEnabled': stampEnabled,
      'waitingNoticeEnabled': waitingNoticeEnabled,
    };
  }
}