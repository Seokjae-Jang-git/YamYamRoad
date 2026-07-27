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

  /// 4. 제휴 광고 시청 완료 후 무료 포인트 안전 적립 + DB 명세서 로그 기록 (ad_view)
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
    final transactionDocRef = _firestore.collection('users_point_transaction').doc();
    final adViewDocRef = _firestore.collection('ad_view').doc();

    try {
      final bool isSuccess = await _firestore.runTransaction<bool>((transaction) async {
        final snapshot = await transaction.get(userDocRef);

        Map<String, dynamic> userData = {};
        if (snapshot.exists && snapshot.data() != null) {
          userData = Map<String, dynamic>.from(snapshot.data()!);
        }

        final pointModel = PointModel.fromMap(userData);

        // 1일 1회 중복 지급 방지 검증
        if (pointModel.hasWatchedToday(adId)) {
          debugPrint('⚠️ 이미 오늘 시청 보상을 받은 광고입니다: $adId');
          return false;
        }

        final now = DateTime.now();
        final updatedFreeBalance = pointModel.freePointBalance + rewardAmount;

        final updatedWatchHistory = Map<String, DateTime>.from(pointModel.adWatchHistory);
        updatedWatchHistory[adId] = now;

        final updatedModel = pointModel.copyWith(
          freePointBalance: updatedFreeBalance,
          adWatchHistory: updatedWatchHistory,
        );

        // 1) users 문서 업데이트
        transaction.set(userDocRef, updatedModel.toMap(), SetOptions(merge: true));

        // 2) users_point_transaction 원장 기록 생성
        transaction.set(transactionDocRef, {
          'uid': uid,
          'transactionType': 'AD_REWARD',
          'pointType': 'FREE',
          'amount': rewardAmount,
          'balanceAfter': updatedFreeBalance,
          'adId': adId,
          'description': '$adTitle 시청 보상',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 3) ad_view 시청 상세 로그 기록 생성
        transaction.set(adViewDocRef, {
          'userId': uid,
          'adId': adId,
          'viewedAt': FieldValue.serverTimestamp(),
          'rewarded': true,
          'pointTransactionId': transactionDocRef.id,
        });

        return true;
      });

      if (isSuccess) {
        debugPrint('✅ 무료 포인트 적립 및 ad_view 기록 완료: +${rewardAmount}P ($adTitle)');
      }

      return isSuccess;
    } catch (e) {
      debugPrint('❌ 제휴 광고 포인트 적립 트랜잭션 오류: $e');
      return false;
    }
  }

  /// 5. Google AdMob 광고 시청 완료 후 무료 포인트 적립 + admob_reward_log 기록 (1일 1회 검증 반영)
  Future<bool> earnAdMobReward({
    required String uid,
    required String adId,
    required int rewardAmount,
    String rewardType = 'FREE_POINT',
  }) async {
    if (uid.isEmpty) {
      debugPrint('❌ AdMob 포인트 적립 실패: UID가 비어있습니다.');
      return false;
    }

    final userDocRef = _firestore.collection('users').doc(uid);
    final transactionDocRef = _firestore.collection('users_point_transaction').doc();
    final admobLogDocRef = _firestore.collection('admob_reward_log').doc();

    try {
      final bool isSuccess = await _firestore.runTransaction<bool>((transaction) async {
        final snapshot = await transaction.get(userDocRef);

        Map<String, dynamic> userData = {};
        if (snapshot.exists && snapshot.data() != null) {
          userData = Map<String, dynamic>.from(snapshot.data()!);
        }

        final pointModel = PointModel.fromMap(userData);

        // 1일 1회 중복 지급 방지 검증 (AdMob 전용)
        if (pointModel.hasWatchedToday(adId)) {
          debugPrint('⚠️ 이미 오늘 시청 보상을 받은 AdMob 광고입니다: $adId');
          return false;
        }

        final now = DateTime.now();
        final updatedFreeBalance = pointModel.freePointBalance + rewardAmount;

        final updatedWatchHistory = Map<String, DateTime>.from(pointModel.adWatchHistory);
        updatedWatchHistory[adId] = now;

        final updatedModel = pointModel.copyWith(
          freePointBalance: updatedFreeBalance,
          adWatchHistory: updatedWatchHistory,
        );

        // 1) users 문서 업데이트 (시청 기록 및 포인트 변동)
        transaction.set(userDocRef, updatedModel.toMap(), SetOptions(merge: true));

        // 2) users_point_transaction 원장 기록 생성
        transaction.set(transactionDocRef, {
          'uid': uid,
          'transactionType': 'ADMOB_REWARD',
          'pointType': 'FREE',
          'amount': rewardAmount,
          'balanceAfter': updatedFreeBalance,
          'adId': adId,
          'description': '구글 애드몹 광고 시청 보상',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 3) admob_reward_log 로그 기록 생성
        transaction.set(admobLogDocRef, {
          'userId': uid,
          'adId': adId,
          'rewardType': rewardType,
          'rewardAmount': rewardAmount,
          'createdAt': FieldValue.serverTimestamp(),
          'pointTransactionId': transactionDocRef.id,
        });

        return true;
      });

      if (isSuccess) {
        debugPrint('✅ AdMob 무료 포인트 적립 및 admob_reward_log 기록 완료: +${rewardAmount}P ($adId)');
      }

      return isSuccess;
    } catch (e) {
      debugPrint('❌ AdMob 포인트 적립 트랜잭션 오류: $e');
      return false;
    }
  }
}