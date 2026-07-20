import 'dart:io';

import 'point_models.dart';
import 'point_usage_calculator.dart';

void main() {
  const calculator = PointUsageCalculator();

  _expectCalculation(
    name: '무료 포인트만으로 구매',
    actual: calculator.calculate(
      freePointBalance: 1000,
      paidPointBalance: 500,
      pricePoint: 700,
    ),
    usedFreePoint: 700,
    usedPaidPoint: 0,
    remainingFreePoint: 300,
    remainingPaidPoint: 500,
  );

  _expectCalculation(
    name: '무료 포인트 우선 사용 후 유료 포인트 차감',
    actual: calculator.calculate(
      freePointBalance: 300,
      paidPointBalance: 1000,
      pricePoint: 800,
    ),
    usedFreePoint: 300,
    usedPaidPoint: 500,
    remainingFreePoint: 0,
    remainingPaidPoint: 500,
  );

  _expectCalculation(
    name: '무료 포인트가 없으면 유료 포인트만 사용',
    actual: calculator.calculate(
      freePointBalance: 0,
      paidPointBalance: 1000,
      pricePoint: 400,
    ),
    usedFreePoint: 0,
    usedPaidPoint: 400,
    remainingFreePoint: 0,
    remainingPaidPoint: 600,
  );

  _expectCalculation(
    name: '잔액과 가격이 같으면 잔액이 0',
    actual: calculator.calculate(
      freePointBalance: 200,
      paidPointBalance: 300,
      pricePoint: 500,
    ),
    usedFreePoint: 200,
    usedPaidPoint: 300,
    remainingFreePoint: 0,
    remainingPaidPoint: 0,
  );

  _expectCalculation(
    name: '큰 금액 계산',
    actual: calculator.calculate(
      freePointBalance: 1000000000,
      paidPointBalance: 2000000000,
      pricePoint: 2500000000,
    ),
    usedFreePoint: 1000000000,
    usedPaidPoint: 1500000000,
    remainingFreePoint: 0,
    remainingPaidPoint: 500000000,
  );

  _expectException(
    name: '보유 포인트 부족',
    expectedCode: 'insufficient_point',
    action: () => calculator.calculate(
      freePointBalance: 100,
      paidPointBalance: 200,
      pricePoint: 301,
    ),
  );
  _expectException(
    name: '0 포인트 상품 가격 거절',
    expectedCode: 'invalid_price',
    action: () => calculator.calculate(
      freePointBalance: 100,
      paidPointBalance: 100,
      pricePoint: 0,
    ),
  );
  _expectException(
    name: '음수 상품 가격 거절',
    expectedCode: 'invalid_price',
    action: () => calculator.calculate(
      freePointBalance: 100,
      paidPointBalance: 100,
      pricePoint: -1,
    ),
  );
  _expectException(
    name: '음수 잔액 거절',
    expectedCode: 'invalid_balance',
    action: () => calculator.calculate(
      freePointBalance: -1,
      paidPointBalance: 100,
      pricePoint: 50,
    ),
  );

  stdout.writeln('포인트 계산 검증 9개 통과');
}

void _expectCalculation({
  required String name,
  required PointUsageCalculation actual,
  required int usedFreePoint,
  required int usedPaidPoint,
  required int remainingFreePoint,
  required int remainingPaidPoint,
}) {
  _expectEqual(name, 'usedFreePoint', actual.usedFreePoint, usedFreePoint);
  _expectEqual(name, 'usedPaidPoint', actual.usedPaidPoint, usedPaidPoint);
  _expectEqual(
    name,
    'remainingFreePoint',
    actual.remainingFreePoint,
    remainingFreePoint,
  );
  _expectEqual(
    name,
    'remainingPaidPoint',
    actual.remainingPaidPoint,
    remainingPaidPoint,
  );
}

void _expectException({
  required String name,
  required String expectedCode,
  required void Function() action,
}) {
  try {
    action();
  } on PointPurchaseException catch (error) {
    if (error.code == expectedCode) return;
    throw StateError('$name: ${error.code} 발생, $expectedCode 예상');
  }
  throw StateError('$name: 예외가 발생하지 않음');
}

void _expectEqual(String name, String field, int actual, int expected) {
  if (actual != expected) {
    throw StateError('$name: $field=$actual, $expected 예상');
  }
}
