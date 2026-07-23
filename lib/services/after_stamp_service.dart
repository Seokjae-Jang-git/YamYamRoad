import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// 🌟 제공해주신 임포트 경로 반영!
import 'badge_service.dart';
import '../common/user_data.dart';

class AfterStampService {

  /// 🌟 [실전용] 팀원이 스탬프를 발급한 직후 호출되는 후속 처리 함수
  /// 1) users_diary_entry 표준 규격 저장 ➔ 2) BadgeService 뱃지 검사
  static Future<void> recordDiaryAndCheckBadge({
    required BuildContext context,
    required String uid,
    required String stampId,
    required String placeId,
    required String roadId,
    required String note,
    Timestamp? stampIssuedAt,
  }) async {
    final firestore = FirebaseFirestore.instance;

    try {
      // 1. 중복 기록 방지 (users_diary_entry)
      final diaryQuery = await firestore
          .collection('users')
          .doc(uid)
          .collection('users_diary_entry')
          .where('stampId', isEqualTo: stampId)
          .get();

      if (diaryQuery.docs.isEmpty) {
        // 2. 날짜 포맷팅 (DB 표준 규격: 예 "2026.7.12 13:00")
        final DateTime targetDate = stampIssuedAt?.toDate() ?? DateTime.now();
        final String formattedDate = DateFormat('yyyy.M.d HH:mm').format(targetDate);

        // 3. 업체 이름(storeName) 가져오기
        String storeName = '가게';
        final placeDoc = await firestore.collection('place').doc(placeId).get();
        if (placeDoc.exists && placeDoc.data() != null) {
          storeName = placeDoc.data()!['name'] ?? placeDoc.data()!['storeName'] ?? '가게';
        }

        // 4. 기존 DB 스키마 필드 규격 그대로 생성
        final Timestamp nowTimestamp = stampIssuedAt ?? Timestamp.now();

        await firestore
            .collection('users')
            .doc(uid)
            .collection('users_diary_entry')
            .add({
          'createdAt': nowTimestamp,      // Timestamp
          'date': formattedDate,          // "2026.7.12 13:00"
          'placeId': placeId,            // 장소 ID
          'roadId': roadId,              // 로드 ID
          'stampId': stampId,            // 스탬프 ID
          'type': 'visit',               // "visit"
          'updatedAt': null,             // null
          'storeName': storeName,        // UI 편의용 매장명
          'note': note,                  // 한줄 메모
        });
        debugPrint('✅ [AfterStampService] 표준 규격 다이어리 생성 완료 ($storeName)');
      }

      // 5. 뱃지 발급 검사 실행
      if (context.mounted) {
        await BadgeService.checkAndGrantBadges(context, uid);
        debugPrint('✅ [AfterStampService] 뱃지 조건 검사 완료');
      }

    } catch (e) {
      debugPrint('🔴 [AfterStampService] 처리 중 에러 발생: $e');
    }
  }

  /// 🌟 [일회용 복구/동기화용] 기존 스탬프들을 싹 긁어와서 규격에 맞게 다이어리로 복구
  static Future<void> syncMissingDiaries(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? UserData.uid;
    if (uid == null || uid.isEmpty) {
      debugPrint('🔴 [AfterStampService] UID를 찾을 수 없습니다.');
      return;
    }

    final firestore = FirebaseFirestore.instance;

    try {
      final stampSnap = await firestore
          .collection('stamp')
          .where('userId', isEqualTo: uid)
          .get();

      for (var doc in stampSnap.docs) {
        final data = doc.data();
        final stampId = doc.id;
        final placeId = data['placeId'] ?? '';
        final roadId = data['roadId'] ?? '';
        final note = data['oneLineNote'] ?? '한줄 기록이 없습니다.';
        final issuedAt = data['issuedAt'] as Timestamp?;

        if (placeId.isNotEmpty) {
          await recordDiaryAndCheckBadge(
            context: context,
            uid: uid,
            stampId: stampId,
            placeId: placeId,
            roadId: roadId,
            note: note,
            stampIssuedAt: issuedAt,
          );
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('표준 규격 다이어리 동기화가 완료되었습니다!')),
        );
      }
    } catch (e) {
      debugPrint('🔴 [AfterStampService] 동기화 에러: $e');
    }
  }
}