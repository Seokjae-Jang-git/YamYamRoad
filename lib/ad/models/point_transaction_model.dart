import 'package:cloud_firestore/cloud_firestore.dart';

/// 💳 DB 설계서 규격 100% 일치 포인트 거래 내역 모델
class PointTransactionModel {
  final String id; // 트랜잭션 문서 ID
  final String type; // 거래 유형 (earn: 적립, use: 사용, purchase: 구매, refund: 환불)
  final String source; // 발생 출처 (ad, stamp, purchase, etc.)
  final int amount; // 증감 포인트 수량
  final String pointType; // 포인트 타입 (free: 무료, paid: 유료)
  final String? refType; // 참조 유형 (ad, stamp, payment, etc.)
  final String? refId; // 참조 대상 ID (광고 ID, 스탬프 ID 등)
  final int usedFreePoint; // 차감/사용한 무료 포인트
  final int usedPaidPoint; // 차감/사용한 유료 포인트
  final int freePointBalanceAfter; // 거래 후 남은 무료 포인트 잔액
  final int paidPointBalanceAfter; // 거래 후 남은 유료 포인트 잔액
  final DateTime? createdAt; // 생성 일시

  PointTransactionModel({
    required this.id,
    required this.type,
    required this.source,
    required this.amount,
    this.pointType = 'free',
    this.refType,
    this.refId,
    this.usedFreePoint = 0,
    this.usedPaidPoint = 0,
    required this.freePointBalanceAfter,
    this.paidPointBalanceAfter = 0,
    this.createdAt,
  });

  /// Firestore DocumentSnapshot -> PointTransactionModel 변환
  factory PointTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PointTransactionModel(
      id: doc.id,
      type: data['type'] ?? 'earn',
      source: data['source'] ?? 'ad',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      pointType: data['pointType'] ?? 'free',
      refType: data['refType'],
      refId: data['refId'],
      usedFreePoint: (data['usedFreePoint'] as num?)?.toInt() ?? 0,
      usedPaidPoint: (data['usedPaidPoint'] as num?)?.toInt() ?? 0,
      freePointBalanceAfter: (data['freePointBalanceAfter'] as num?)?.toInt() ?? 0,
      paidPointBalanceAfter: (data['paidPointBalanceAfter'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Map<String, dynamic> -> PointTransactionModel 변환
  factory PointTransactionModel.fromMap(String id, Map<String, dynamic> map) {
    return PointTransactionModel(
      id: id,
      type: map['type'] ?? 'earn',
      source: map['source'] ?? 'ad',
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      pointType: map['pointType'] ?? 'free',
      refType: map['refType'],
      refId: map['refId'],
      usedFreePoint: (map['usedFreePoint'] as num?)?.toInt() ?? 0,
      usedPaidPoint: (map['usedPaidPoint'] as num?)?.toInt() ?? 0,
      freePointBalanceAfter: (map['freePointBalanceAfter'] as num?)?.toInt() ?? 0,
      paidPointBalanceAfter: (map['paidPointBalanceAfter'] as num?)?.toInt() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Firestore 저장용 Map 변환
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'source': source,
      'amount': amount,
      'pointType': pointType,
      'refType': refType,
      'refId': refId,
      'usedFreePoint': usedFreePoint,
      'usedPaidPoint': usedPaidPoint,
      'freePointBalanceAfter': freePointBalanceAfter,
      'paidPointBalanceAfter': paidPointBalanceAfter,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}