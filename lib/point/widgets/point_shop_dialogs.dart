import 'package:flutter/material.dart';

import 'point_shop_common.dart';

/// 포인트 상점 전용 다이얼로그 및 알림 UI 헬퍼
abstract class PointShopDialogs {
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color subBrown = Color(0xFF7A6B63);

  /// 포인트 구매 확인 팝업
  static Future<bool> confirmPurchase({
    required BuildContext context,
    required String itemName,
    required int pricePoint,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          '구매 확인',
          style: TextStyle(fontWeight: FontWeight.bold, color: deepChocolate),
        ),
        content: Text(
          '$itemName을(를) ${formatPointNumber(pricePoint)} P로 구매할까요?',
          style: const TextStyle(color: deepChocolate),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: subBrown)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: pointCoralRed),
            child: const Text('구매'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// 포인트 구매 완료 결과 안내 팝업
  static Future<void> showSuccessDialog({
    required BuildContext context,
    required int usedFreePoint,
    required int usedPaidPoint,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          '구매 완료',
          style: TextStyle(fontWeight: FontWeight.bold, color: deepChocolate),
        ),
        content: Text(
          '무료 ${formatPointNumber(usedFreePoint)} P, '
              '유료 ${formatPointNumber(usedPaidPoint)} P를 사용했습니다.',
          style: const TextStyle(color: deepChocolate),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인', style: TextStyle(color: pointCoralRed)),
          ),
        ],
      ),
    );
  }

  /// 스낵바 메시지 안내
  static void showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: deepChocolate,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}