// lib/login/withdrawal_recovery.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const int kRecoveryLimitDays = 30;

// =============================================================
// 1) 회원 탈퇴 신청 처리
//    - status: 'paused', pausedAt: 서버 타임스탬프로 저장
//    - (마이페이지 > 탈퇴하기 버튼에서 호출)
// =============================================================
Future<void> requestWithdrawal({required String uid}) async {
  debugPrint('🔎 [탈퇴처리] 진입. uid=$uid');

  await FirebaseFirestore.instance.collection('users').doc(uid).update({
    'status': 'paused',
    'pausedAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  debugPrint('🔎 [탈퇴처리] Firestore 업데이트 완료. status=paused, pausedAt=now');
}

// =============================================================
// 2) 로그인 시 상태 체크 후 복구 로직 진입 여부 판단
//    - 로그인 성공 직후(각 소셜/휴대폰 로그인 콜백) 이 함수를 호출
//    - status가 'paused'가 아니면 그냥 통과(true)
//    - status가 'banned' 등 다른 차단 상태는 별도 처리 필요(여기선 다루지 않음)
// =============================================================
Future<bool> checkUserStatusAndHandleLogin({
  required BuildContext context,
  required String uid,
}) async {
  final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
  final snapshot = await docRef.get();

  if (!snapshot.exists) {
    debugPrint('🔎 [상태체크] 유저 문서 없음. uid=$uid');
    return true; // 신규 유저 등 별도 플로우에서 처리
  }

  final data = snapshot.data();
  final String? status = data?['status'] as String?;
  debugPrint('🔎 [상태체크] uid=$uid, status=$status');

  if (status == 'paused') {
    final Timestamp? pausedAtTs = data?['pausedAt'] as Timestamp?;
    final DateTime? pausedAt = pausedAtTs?.toDate();

    if (!context.mounted) {
      debugPrint('🔎 [상태체크] context unmounted, 복구 로직 진입 불가');
      return false;
    }

    return handleWithdrawnRecovery(
      context: context,
      uid: uid,
      pausedAt: pausedAt,
    );
  }

  // status == 'active' 이거나 다른 값이면 그대로 통과
  return true;
}

// =============================================================
// 3) status가 'paused'(탈퇴 신청) 상태인 유저에게 복구 여부를 묻고,
//    복구를 선택하면 Firestore를 되돌립니다.
//
//    반환값:
//    - true  : 로그인 진행 가능 (복구 완료)
//    - false : 로그인 중단 (취소했거나 복구 기간이 지남)
// =============================================================
Future<bool> handleWithdrawnRecovery({
  required BuildContext context,
  required String uid,
  required DateTime? pausedAt,
}) async {
  debugPrint('🔎 [복구로직] 진입. uid=$uid, pausedAt=$pausedAt');

  if (pausedAt == null) {
    debugPrint('🔎 [복구로직] pausedAt이 null이라 차단 (return false)');
    return false;
  }

  final int elapsedDays = DateTime.now().difference(pausedAt).inDays;
  debugPrint('🔎 [복구로직] 경과일=$elapsedDays, 제한일=$kRecoveryLimitDays');

  if (elapsedDays >= kRecoveryLimitDays) {
    debugPrint('🔎 [복구로직] 복구기간 만료. context.mounted=${context.mounted}');
    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('복구 기간 만료'),
          content: const Text('탈퇴 후 30일이 지나 계정을 복구할 수 없습니다.\n새로운 계정으로 가입해주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
    debugPrint('🔎 [복구로직] 만료 다이얼로그 닫힘 (return false)');
    return false;
  }

  final int remainingDays = kRecoveryLimitDays - elapsedDays;
  debugPrint('🔎 [복구로직] 복구 다이얼로그 표시 시도. context.mounted=${context.mounted}, 남은일=$remainingDays');

  if (!context.mounted) {
    debugPrint('🔎 [복구로직] context가 unmounted 상태라 다이얼로그 못 띄우고 종료 (return false)');
    return false;
  }

  final bool? shouldRestore = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('탈퇴 신청된 계정입니다'),
      content: Text('다시 복구하시겠습니까?\n(남은 기간: $remainingDays일)'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('복구하기'),
        ),
      ],
    ),
  );

  debugPrint('🔎 [복구로직] 다이얼로그 결과 shouldRestore=$shouldRestore');

  if (shouldRestore != true) {
    debugPrint('🔎 [복구로직] 복구 취소됨 (return false)');
    return false;
  }

  debugPrint('🔎 [복구로직] Firestore 업데이트 시작 (uid=$uid)');
  await FirebaseFirestore.instance.collection('users').doc(uid).update({
    'status': 'active',
    'pausedAt': null,
    'updatedAt': FieldValue.serverTimestamp(),
  });
  debugPrint('🔎 [복구로직] Firestore 업데이트 완료 (return true)');

  return true;
}