import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  // UI 호환성 및 정렬용 게터 (UI 에러 방지 및 기본값 제공)
  double get distanceValue => 0.0;
  String get distance => '0m';
  int get stampCount => 0;
  double get rating => 0.0;
  String get description => address;

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
    };
  }
}