import 'package:cloud_firestore/cloud_firestore.dart';

/// 💰 유저 포인트 잔액 및 광고 시청 기록을 관리하는 모델 클래스
class PointModel {
  final int points;
  final Map<String, DateTime> adWatchHistory; // [adId : 마지막 시청 시각]

  PointModel({
    required this.points,
    required this.adWatchHistory,
  });

  /// 기본 초기값 생성자
  factory PointModel.initial() {
    return PointModel(
      points: 0,
      adWatchHistory: {},
    );
  }

  /// Firestore Map 객체로부터 PointModel 변환
  factory PointModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return PointModel.initial();

    final rawHistory = map['adWatchHistory'] as Map<String, dynamic>? ?? {};
    final Map<String, DateTime> convertedHistory = {};

    rawHistory.forEach((key, value) {
      if (value is Timestamp) {
        convertedHistory[key] = value.toDate();
      } else if (value is String) {
        final parsedDate = DateTime.tryParse(value);
        if (parsedDate != null) {
          convertedHistory[key] = parsedDate;
        }
      }
    });

    return PointModel(
      points: (map['points'] as num?)?.toInt() ?? 0,
      adWatchHistory: convertedHistory,
    );
  }

  /// Firestore 저장용 Map 변환
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> convertedHistory = {};
    adWatchHistory.forEach((key, value) {
      convertedHistory[key] = Timestamp.fromDate(value);
    });

    return {
      'points': points,
      'adWatchHistory': convertedHistory,
    };
  }

  /// 🗓️ 특정 광고(adId)를 '오늘(YYYY-MM-DD)' 이미 시청했는지 판별하는 메서드
  bool hasWatchedToday(String adId) {
    if (!adWatchHistory.containsKey(adId)) return false;
    final lastWatched = adWatchHistory[adId];
    if (lastWatched == null) return false;

    final now = DateTime.now();
    return lastWatched.year == now.year &&
        lastWatched.month == now.month &&
        lastWatched.day == now.day;
  }

  /// 불변 객체 복사 (copyWith)
  PointModel copyWith({
    int? points,
    Map<String, DateTime>? adWatchHistory,
  }) {
    return PointModel(
      points: points ?? this.points,
      adWatchHistory: adWatchHistory ?? this.adWatchHistory,
    );
  }
}