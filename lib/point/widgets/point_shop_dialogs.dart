import 'package:flutter/material.dart';

import '../logic/point_usage_calculator.dart';
import '../models/point_models.dart';
import 'point_balance_widgets.dart';
import 'point_shop_common.dart';

/// 포인트 상점 전용 다이얼로그 및 알림 UI 헬퍼
abstract class PointShopDialogs {
  /// 포인트 구매 확인 팝업
  static Future<bool> confirmPurchase({
    required BuildContext context,
    required String itemName,
    required PointBalance balance,
    required PointUsageCalculation usage,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          '구매 확인',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: PointBalanceColors.deepChocolate,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                itemName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PointBalanceColors.deepChocolate,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '무료 포인트부터 사용됩니다.',
                style: TextStyle(
                  color: PointBalanceColors.subBrown,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              PointBalancePanel(
                title: '현재 보유',
                freePoint: balance.freePoint,
                paidPoint: balance.paidPoint,
              ),
              const SizedBox(height: 12),
              PointUsagePanel(usage: usage),
              const SizedBox(height: 12),
              PointBalancePanel(
                title: '구매 후 잔액',
                freePoint: usage.remainingFreePoint,
                paidPoint: usage.remainingPaidPoint,
                highlighted: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              '취소',
              style: TextStyle(color: PointBalanceColors.subBrown),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: PointBalanceColors.pointCoralRed,
            ),
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
    required String itemName,
    required PointPurchaseResult result,
  }) async {
    final usage = PointUsageCalculation(
      usedFreePoint: result.usedFreePoint,
      usedPaidPoint: result.usedPaidPoint,
      remainingFreePoint: result.remainingFreePoint,
      remainingPaidPoint: result.remainingPaidPoint,
    );

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: PointBalanceColors.success),
            SizedBox(width: 8),
            Text(
              '구매 완료',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: PointBalanceColors.deepChocolate,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                itemName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PointBalanceColors.deepChocolate,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '구매가 완료되었습니다.',
                style: TextStyle(
                  color: PointBalanceColors.subBrown,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              PointUsagePanel(usage: usage),
              const SizedBox(height: 12),
              PointBalancePanel(
                title: '현재 잔액',
                freePoint: result.remainingFreePoint,
                paidPoint: result.remainingPaidPoint,
                highlighted: true,
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: PointBalanceColors.pointCoralRed,
            ),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  static Future<bool> confirmPointCharge({
    required BuildContext context,
    required PointPackage pointPackage,
    required PointBalance balance,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          '포인트 충전 확인',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: PointBalanceColors.deepChocolate,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PointAmountRow(
                label: '충전 포인트',
                value: '+ ${formatPointNumber(pointPackage.pointAmount)} P',
                valueColor: PointBalanceColors.pointCoralRed,
                emphasized: true,
              ),
              const SizedBox(height: 8),
              PointAmountRow(
                label: '결제 금액',
                value: '${formatPointNumber(pointPackage.priceCash)}원',
              ),
              const SizedBox(height: 12),
              PointBalancePanel(
                title: '현재 보유',
                freePoint: balance.freePoint,
                paidPoint: balance.paidPoint,
              ),
              const SizedBox(height: 12),
              PointBalancePanel(
                title: '충전 후 예상 잔액',
                freePoint: balance.freePoint,
                paidPoint: balance.paidPoint + pointPackage.pointAmount,
                highlighted: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              '취소',
              style: TextStyle(color: PointBalanceColors.subBrown),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: PointBalanceColors.pointCoralRed,
            ),
            child: const Text('결제하기'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<void> showPointChargeSuccessDialog({
    required BuildContext context,
    required int pointAmount,
    required PointPurchaseResult result,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: PointBalanceColors.success),
            SizedBox(width: 8),
            Text(
              '충전 완료',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: PointBalanceColors.deepChocolate,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PointAmountRow(
                label: '충전 포인트',
                value: '+ ${formatPointNumber(pointAmount)} P',
                valueColor: PointBalanceColors.pointCoralRed,
                emphasized: true,
              ),
              const SizedBox(height: 12),
              PointBalancePanel(
                title: '현재 잔액',
                freePoint: result.remainingFreePoint,
                paidPoint: result.remainingPaidPoint,
                highlighted: true,
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: PointBalanceColors.pointCoralRed,
            ),
            child: const Text('확인'),
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
        backgroundColor: PointBalanceColors.deepChocolate,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
