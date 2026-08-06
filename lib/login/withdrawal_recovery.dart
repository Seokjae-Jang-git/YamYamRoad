import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const int kRecoveryLimitDays = 30;

Future<void> requestWithdrawal({required String uid}) async {

  await FirebaseFirestore.instance.collection('users').doc(uid).update({
    'status': 'paused',
    'pausedAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

}

Future<bool> checkUserStatusAndHandleLogin({
  required BuildContext context,
  required String uid,
}) async {
  final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
  final snapshot = await docRef.get();

  if (!snapshot.exists) {
    return true;
  }

  final data = snapshot.data();
  final String? status = data?['status'] as String?;

  if (status == 'paused') {
    final Timestamp? pausedAtTs = data?['pausedAt'] as Timestamp?;
    final DateTime? pausedAt = pausedAtTs?.toDate();

    if (!context.mounted) {
      return false;
    }

    return handleWithdrawnRecovery(
      context: context,
      uid: uid,
      pausedAt: pausedAt,
    );
  }
  return true;
}

Future<bool> handleWithdrawnRecovery({
  required BuildContext context,
  required String uid,
  required DateTime? pausedAt,
}) async {

  if (pausedAt == null) {
    return false;
  }

  final int elapsedDays = DateTime.now().difference(pausedAt).inDays;

  if (elapsedDays >= kRecoveryLimitDays) {
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
    return false;
  }

  final int remainingDays = kRecoveryLimitDays - elapsedDays;
  if (!context.mounted) {
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

  if (shouldRestore != true) {
    return false;
  }

  await FirebaseFirestore.instance.collection('users').doc(uid).update({
    'status': 'active',
    'pausedAt': null,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  return true;
}