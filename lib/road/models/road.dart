import 'package:cloud_firestore/cloud_firestore.dart';

class Road {
  final String id;
  final String title;
  final String description;
  final String region;
  final List<String> categoryIds;
  final List<String> placeIds;
  final String imageUrl;
  final String badgeName;
  final int rewardPoints;
  final int estimatedTimeMinutes;
  final double totalDistanceKm;
  final DateTime createdAt;

  Road({
    required this.id,
    required this.title,
    required this.description,
    required this.region,
    required this.categoryIds,
    required this.placeIds,
    required this.imageUrl,
    required this.badgeName,
    required this.rewardPoints,
    required this.estimatedTimeMinutes,
    required this.totalDistanceKm,
    required this.createdAt,
  });

  /// Firestore DocumentSnapshot을 Road 객체로 변환
  factory Road.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return Road(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      region: data['region'] as String? ?? '',
      categoryIds: List<String>.from(data['categoryIds'] ?? []),
      placeIds: List<String>.from(data['placeIds'] ?? []),
      imageUrl: data['imageUrl'] as String? ?? '',
      badgeName: data['badgeName'] as String? ?? '',
      rewardPoints: (data['rewardPoints'] as num?)?.toInt() ?? 0,
      estimatedTimeMinutes: (data['estimatedTimeMinutes'] as num?)?.toInt() ?? 0,
      totalDistanceKm: (data['totalDistanceKm'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Road 객체를 Firestore에 저장 가능한 Map 구조로 변환
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'region': region,
      'categoryIds': categoryIds,
      'placeIds': placeIds,
      'imageUrl': imageUrl,
      'badgeName': badgeName,
      'rewardPoints': rewardPoints,
      'estimatedTimeMinutes': estimatedTimeMinutes,
      'totalDistanceKm': totalDistanceKm,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}