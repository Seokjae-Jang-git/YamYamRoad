import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BadgeService {
  /// 🌟 스탬프 획득 등 이벤트 발생 시 호출하는 '단일 진입점(Main Entry)'
  static Future<void> checkAndGrantBadges(BuildContext context, String userId) async {
    final firestore = FirebaseFirestore.instance;

    try {
      // 1. 유저가 이미 획득한 뱃지 ID 목록 가져오기
      final earnedBadgeSnap = await firestore
          .collection('users')
          .doc(userId)
          .collection('users_badge')
          .get();
      final Set<String> earnedBadgeIds =
      earnedBadgeSnap.docs.map((doc) => doc.data()['badgeId'] as String).toSet();

      // 2. 전체 활성화된(isActive: true) 마스터 뱃지 가져오기
      final badgeMasterSnap = await firestore
          .collection('badge')
          .where('isActive', isEqualTo: true)
          .get();

      final batch = firestore.batch();
      final userBadgeRef = firestore.collection('users').doc(userId).collection('users_badge');
      List<Map<String, dynamic>> newlyEarnedBadges = [];

      // 3. 미획득 뱃지들을 하나씩 순회하며 조건 검사
      for (var doc in badgeMasterSnap.docs) {
        final badgeId = doc.id;
        final badgeData = doc.data();

        // 이미 가지고 있는 뱃지면 패스
        if (earnedBadgeIds.contains(badgeId)) continue;

        bool isConditionMet = false;
        final String conditionType = badgeData['conditionType'] ?? '';

        // 🌟 [수정/확장된 스위치 분기]
        switch (conditionType) {
          case 'stamp_count': // 총 누적 스탬프 개수 조건 (예: 스타터)
            isConditionMet = await _checkStampCount(firestore, userId, badgeData);
            break;
          case 'road_progress': // 로드 진행율(%) 조건 (초보자, 탐험가, 마스터 통합)
            isConditionMet = await _checkRoadProgress(firestore, userId, badgeData);
            break;
          case 'weekly_stamp': // 주간 목표 조건
            isConditionMet = await _checkPeriodStamp(firestore, userId, badgeData, _PeriodType.weekly);
            break;
          case 'monthly_stamp': // 월간 목표 조건
            isConditionMet = await _checkPeriodStamp(firestore, userId, badgeData, _PeriodType.monthly);
            break;
          case 'yearly_stamp': // 연간 목표 조건
            isConditionMet = await _checkPeriodStamp(firestore, userId, badgeData, _PeriodType.yearly);
            break;
          default:
            debugPrint('⚠️ 알 수 없거나 미구현된 뱃지 조건 타입: $conditionType');
        }

        // 4. 조건을 만족했다면 발급 대기열(Batch)에 추가
        if (isConditionMet) {
          final newDocRef = userBadgeRef.doc();
          batch.set(newDocRef, {
            'badgeId': badgeId,
            'earnedAt': FieldValue.serverTimestamp(),
            'isSelected': false,
          });
          newlyEarnedBadges.add(badgeData);
        }
      }

      // 5. 발급할 뱃지가 모였다면 DB에 저장하고 팝업 띄우기
      if (newlyEarnedBadges.isNotEmpty) {
        await batch.commit();
        if (context.mounted) {
          for (var badge in newlyEarnedBadges) {
            _showCelebrationDialog(context, badge['name'], badge['imageUrl']);
          }
        }
      }
    } catch (e) {
      debugPrint('🔴 뱃지 검사 중 에러 발생: $e');
    }
  }

  // =========================================================================
  // 🔍 개별 조건 검사 헬퍼 함수들
  // =========================================================================

  /// 조건 1: 총 스탬프 누적 개수 확인
  static Future<bool> _checkStampCount(
      FirebaseFirestore firestore, String userId, Map<String, dynamic> badgeData) async {
    final requiredCount = badgeData['requiredStampCount'] ?? 9999;

    // [수정됨] 최상위 stamp 컬렉션에서 내 userId 필드로 검색
    final stampSnap = await firestore
        .collection('stamp')
        .where('userId', isEqualTo: userId)
        .count()
        .get();

    return (stampSnap.count ?? 0) >= requiredCount;
  }

  /// 조건 2: 특정 로드 진행도(%) 확인 (초보자 1개 이상 / 50% 이상 / 100% 마스터)
  static Future<bool> _checkRoadProgress(
      FirebaseFirestore firestore, String userId, Map<String, dynamic> badgeData) async {
    final targetRoadId = badgeData['targetRoadId'];
    final num requiredPercent = badgeData['requiredPercent'] ?? 100;

    if (targetRoadId == null) return false;

    try {
      final roadDoc = await firestore.collection('road').doc(targetRoadId).get();
      if (!roadDoc.exists) return false;

      final List<dynamic> placeIds = roadDoc.data()?['placeIds'] ?? [];
      final int totalStampCount = placeIds.isNotEmpty
          ? placeIds.length
          : (roadDoc.data()?['totalStampCount'] ?? 0);

      if (totalStampCount == 0) return false;

      // [수정됨] 최상위 stamp 컬렉션에서 userId와 roadId 두 조건으로 검색
      final myStampSnap = await firestore
          .collection('stamp')
          .where('userId', isEqualTo: userId)
          .where('roadId', isEqualTo: targetRoadId)
          .count()
          .get();

      final int myStampCount = myStampSnap.count ?? 0;

      final double currentPercent = (myStampCount / totalStampCount) * 100;
      return currentPercent >= requiredPercent;
    } catch (e) {
      debugPrint('🔴 로드 진행도 계산 중 에러: $e');
      return false;
    }
  }

  /// 조건 3: 기간별(주간/월간/연간) 스탬프 수량 확인
  static Future<bool> _checkPeriodStamp(
      FirebaseFirestore firestore,
      String userId,
      Map<String, dynamic> badgeData,
      _PeriodType periodType,
      ) async {
    final requiredCount = badgeData['requiredStampCount'] ?? 9999;
    final now = DateTime.now();
    late DateTime startTime;

    switch (periodType) {
      case _PeriodType.weekly:
      // 이번 주 월요일 00:00:00
        startTime = DateTime(now.year, now.month, now.day - (now.weekday - 1));
        break;
      case _PeriodType.monthly:
      // 이번 달 1일 00:00:00
        startTime = DateTime(now.year, now.month, 1);
        break;
      case _PeriodType.yearly:
      // 올해 1월 1일 00:00:00
        startTime = DateTime(now.year, 1, 1);
        break;
    }

    final stampSnap = await firestore
        .collection('stamp')
        .where('userId', isEqualTo: userId)
        .where('issuedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startTime))
        .count()
        .get();

    return (stampSnap.count ?? 0) >= requiredCount;
  }

  // =========================================================================

  /// 🎉 뱃지 획득 축하 팝업 위젯
  static void _showCelebrationDialog(BuildContext context, String badgeName, String imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉 새로운 뱃지 획득! 🎉',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
              const SizedBox(height: 20),
              Image.network(
                imageUrl,
                width: 120,
                height: 120,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.workspace_premium, size: 80, color: Colors.orange),
              ),
              const SizedBox(height: 20),
              Text('[$badgeName]',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('마이페이지에서 획득한 뱃지를 확인해보세요!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('확인',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// internal enum for period filtering
enum _PeriodType { weekly, monthly, yearly }