import 'package:cloud_firestore/cloud_firestore.dart';

/// 💰 무료 포인트 잔액 및 광고 시청 기록을 관리하는 모델 클래스
class PointModel {
  final int freePointBalance; // 무료 포인트 잔액
  final Map<String, DateTime> adWatchHistory; // [adId : 마지막 시청 시각]

  PointModel({
    required this.freePointBalance,
    required this.adWatchHistory,
  });

  /// 💡 기존 UI 하위 호환용 총 포인트 게터
  int get points => freePointBalance;

  /// 기본 초기값 생성자
  factory PointModel.initial() {
    return PointModel(
      freePointBalance: 0,
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

    // 구버전 'points' 필드와의 이전 호환성 보장
    final legacyPoints = (map['points'] as num?)?.toInt();
    final freeBalance = (map['freePointBalance'] as num?)?.toInt() ?? legacyPoints ?? 0;

    return PointModel(
      freePointBalance: freeBalance,
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
      'freePointBalance': freePointBalance,
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
    int? freePointBalance,
    Map<String, DateTime>? adWatchHistory,
  }) {
    return PointModel(
      freePointBalance: freePointBalance ?? this.freePointBalance,
      adWatchHistory: adWatchHistory ?? this.adWatchHistory,
    );
  }
}