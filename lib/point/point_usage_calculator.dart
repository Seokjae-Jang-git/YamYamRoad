import 'point_models.dart';

class PointUsageCalculation {
  const PointUsageCalculation({
    required this.usedFreePoint,
    required this.usedPaidPoint,
    required this.remainingFreePoint,
    required this.remainingPaidPoint,
  });

  final int usedFreePoint;
  final int usedPaidPoint;
  final int remainingFreePoint;
  final int remainingPaidPoint;
}

class PointUsageCalculator {
  const PointUsageCalculator();

  PointUsageCalculation calculate({
    required int freePointBalance,
    required int paidPointBalance,
    required int pricePoint,
  }) {
    if (freePointBalance < 0 || paidPointBalance < 0) {
      throw const PointPurchaseException(
        'invalid_balance',
        '보유 포인트 정보가 올바르지 않습니다.',
      );
    }
    if (pricePoint <= 0) {
      throw const PointPurchaseException(
        'invalid_price',
        '상품 가격 정보가 올바르지 않습니다.',
      );
    }
    if (freePointBalance + paidPointBalance < pricePoint) {
      throw const PointPurchaseException(
        'insufficient_point',
        '보유 포인트가 부족합니다.',
      );
    }

    final usedFreePoint = freePointBalance >= pricePoint
        ? pricePoint
        : freePointBalance;
    final usedPaidPoint = pricePoint - usedFreePoint;

    return PointUsageCalculation(
      usedFreePoint: usedFreePoint,
      usedPaidPoint: usedPaidPoint,
      remainingFreePoint: freePointBalance - usedFreePoint,
      remainingPaidPoint: paidPointBalance - usedPaidPoint,
    );
  }
}
