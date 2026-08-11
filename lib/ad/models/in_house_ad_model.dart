import 'package:cloud_firestore/cloud_firestore.dart';

class InHouseAdModel {
  final String id;
  final String title;
  final String type;
  final String? imageUrl;
  final String? targetUrl;
  final String placement;
  final int rewardPoint;
  final DateTime? startAt;
  final DateTime? endAt;
  final bool isActive;
  final String? videoUrl;
  final int videoDuration;

  InHouseAdModel({
    required this.id,
    required this.title,
    this.type = 'reward',
    this.imageUrl,
    this.targetUrl,
    this.placement = 'inhouse_tab',
    required this.rewardPoint,
    this.startAt,
    this.endAt,
    this.isActive = true,
    this.videoUrl,
    required this.videoDuration,
  });

  /// Firestore DocumentSnapshot -> InHouseAdModel 변환
  factory InHouseAdModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return InHouseAdModel(
      id: doc.id,
      title: data['title'] ?? '',
      type: data['type'] ?? 'reward',
      imageUrl: data['imageUrl'],
      targetUrl: data['targetUrl'],
      placement: data['placement'] ?? 'inhouse_tab',
      rewardPoint: (data['rewardPoint'] as num?)?.toInt() ?? 0,
      startAt: (data['startAt'] as Timestamp?)?.toDate(),
      endAt: (data['endAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
      videoUrl: data['videoUrl'],
      videoDuration: (data['videoDuration'] as num?)?.toInt() ?? 0,
    );
  }

  /// InHouseAdModel -> Map<String, dynamic> 변환 (Firestore 저장용)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type,
      'imageUrl': imageUrl,
      'targetUrl': targetUrl,
      'placement': placement,
      'rewardPoint': rewardPoint,
      'startAt': startAt != null ? Timestamp.fromDate(startAt!) : null,
      'endAt': endAt != null ? Timestamp.fromDate(endAt!) : null,
      'isActive': isActive,
      'videoUrl': videoUrl,
      'videoDuration': videoDuration,
    };
  }
}