import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../ad/models/point_model.dart';

/// 💰 유저 포인트 조회 및 광고 시청 보상 정산 비즈니스 로직 클래스
class PointService {
  final FirebaseFirestore _firestore;

  PointService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 1. 유저 포인트 및 시청 기록 실시간 스트림 구독
  Stream<PointModel> getPointStream(String uid) {
    if (uid.isEmpty) {
      return Stream.value(PointModel.initial());
    }

    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return PointModel.initial();
      }
      return PointModel.fromMap(snapshot.data());
    });
  }

  /// 2. 단발성 유저 포인트 정보 조회
  Future<PointModel> getPointData(String uid) async {
    if (uid.isEmpty) return PointModel.initial();

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        return PointModel.initial();
      }
      return PointModel.fromMap(doc.data());
    } catch (e) {
      debugPrint('❌ PointData 조회 오류: $e');
      return PointModel.initial();
    }
  }

  /// 3. 오늘 특정 광고(adId)를 이미 시청했는지 판별
  Future<bool> hasWatchedAdToday(String uid, String adId) async {
    final pointData = await getPointData(uid);
    return pointData.hasWatchedToday(adId);
  }

  /// 4. 광고 시청 완료 후 포인트 안전 적립 (Firestore 트랜잭션 적용)
  /// - 성공 시 true, 실패 또는 오늘 이미 수령했으면 false 반환
  Future<bool> claimAdReward({
    required String uid,
    required String adId,
    required int rewardAmount,
    required String adTitle,
  }) async {
    if (uid.isEmpty) {
      debugPrint('❌ 포인트 적립 실패: UID가 비어있습니다.');
      return false;
    }

    final userDocRef = _firestore.collection('users').doc(uid);

    try {
      final bool isSuccess = await _firestore.runTransaction<bool>((transaction) async {
        final snapshot = await transaction.get(userDocRef);

        Map<String, dynamic> userData = {};
        if (snapshot.exists && snapshot.data() != null) {
          userData = Map<String, dynamic>.from(snapshot.data()!);
        }

        final pointModel = PointModel.fromMap(userData);

        // 1일 1회 중복 지급 방지 검증 (트랜잭션 격리 단계에서 다시 한번 체크)
        if (pointModel.hasWatchedToday(adId)) {
          debugPrint('⚠️ 이미 오늘 시청 보상을 받은 광고입니다: $adId');
          return false;
        }

        // 포인트 증가 및 시청 시각 기록 업데이트
        final now = DateTime.now();
        final currentPoints = pointModel.points;
        final updatedPoints = currentPoints + rewardAmount;

        final updatedWatchHistory = Map<String, DateTime>.from(pointModel.adWatchHistory);
        updatedWatchHistory[adId] = now;

        final updatedModel = pointModel.copyWith(
          points: updatedPoints,
          adWatchHistory: updatedWatchHistory,
        );

        // Firestore 유저 문서 업데이트
        transaction.set(userDocRef, updatedModel.toMap(), SetOptions(merge: true));

        // 포인트 적립 세부 내역 로그 생성
        final historyDocRef = userDocRef.collection('point_history').doc();
        transaction.set(historyDocRef, {
          'type': 'AD_REWARD',
          'adId': adId,
          'adTitle': adTitle,
          'amount': rewardAmount,
          'createdAt': FieldValue.serverTimestamp(),
        });

        return true;
      });

      if (isSuccess) {
        debugPrint('✅ 포인트 적립 성공: +${rewardAmount}P ($adTitle)');
      }

      return isSuccess;
    } catch (e) {
      debugPrint('❌ 포인트 적립 트랜잭션 오류: $e');
      return false;
    }
  }
}