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
      final Set<String> earnedBadgeIds = earnedBadgeSnap.docs.map((doc) => doc.data()['badgeId'] as String).toSet();

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

        // 이미 있는 뱃지면 패스
        if (earnedBadgeIds.contains(badgeId)) continue;

        // 🌟 [핵심] conditionType에 따라 알맞은 검사 로직으로 분기 (Switch)
        bool isConditionMet = false;
        final String conditionType = badgeData['conditionType'] ?? '';

        switch (conditionType) {
          case 'stamp_count':
            isConditionMet = await _checkStampCount(firestore, userId, badgeData);
            break;
          case 'road_complete':
            isConditionMet = await _checkRoadComplete(firestore, userId, badgeData);
            break;
          case 'weekly_stamp':
            isConditionMet = await _checkWeeklyStamp(firestore, userId, badgeData);
            break;
          default:
            debugPrint('알 수 없는 뱃지 조건 타입: $conditionType');
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
      debugPrint('🔴 뱃지 검사 중 에러: $e');
    }
  }

  // =========================================================================
  // 🔍 개별 조건 검사 헬퍼 함수들 (새로운 조건이 생기면 여기에 추가만 하면 됩니다!)
  // =========================================================================

  /// 조건 1: 총 스탬프 누적 개수 확인
  static Future<bool> _checkStampCount(
      FirebaseFirestore firestore, String userId, Map<String, dynamic> badgeData) async {
    final requiredCount = badgeData['requiredStampCount'] ?? 9999;

    final stampSnap = await firestore
        .collection('users')
        .doc(userId)
        .collection('stamp')
        .count()
        .get();

    return (stampSnap.count ?? 0) >= requiredCount;
  }

  /// 조건 2: 특정 로드 마스터(완주) 확인
  static Future<bool> _checkRoadComplete(
      FirebaseFirestore firestore, String userId, Map<String, dynamic> badgeData) async {
    final targetRoadId = badgeData['targetRoadId'];
    if (targetRoadId == null) return false;

    // 해당 targetRoadId에 속한 매장들의 스탬프를 모두 모았는지 검사하는 로직 작성
    // (예: 유저의 stamp 컬렉션에서 roadId == targetRoadId 인 항목 개수가 해당 로드의 총 매장 수와 같은지 비교)

    return false; // 임시 리턴 (실제 DB 구조에 맞게 쿼리 구현 필요)
  }

  /// 조건 3: 주간 스탬프 목표 확인
  static Future<bool> _checkWeeklyStamp(
      FirebaseFirestore firestore, String userId, Map<String, dynamic> badgeData) async {
    // 이번 주 월요일부터 일요일까지 획득한 스탬프 개수를 쿼리하여 비교하는 로직
    return false;
  }

  // =========================================================================

  /// 🎉 뱃지 획득 축하 팝업 위젯 (기존과 동일)
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
              const Text('🎉 새로운 뱃지 획득! 🎉', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
              const SizedBox(height: 20),
              Image.network(imageUrl, width: 120, height: 120, fit: BoxFit.contain),
              const SizedBox(height: 20),
              Text('[$badgeName]', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('마이페이지에서 획득한 뱃지를 확인해보세요!', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('확인', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
    );
  }
}