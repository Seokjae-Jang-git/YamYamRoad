import 'package:cloud_firestore/cloud_firestore.dart';

import 'gifticon_purchase_api_client.dart';
import '../models/point_models.dart';
import 'point_usage_calculator.dart';

abstract interface class PointPurchaseService {
  Future<PointPurchaseResult> purchaseEmoticon({
    required String userId,
    required String emoticonId,
  });

  Future<PointPurchaseResult> purchaseGifticon({
    required String userId,
    required String gifticonId,
  });
}

class FirestorePointPurchaseService implements PointPurchaseService {
  FirestorePointPurchaseService({
    FirebaseFirestore? firestore,
    GifticonPurchaseApiClient? gifticonPurchaseApiClient,
    this._pointUsageCalculator = const PointUsageCalculator(),
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _gifticonPurchaseApiClient =
           gifticonPurchaseApiClient ?? GifticonPurchaseApiClient(),
       super();

  final FirebaseFirestore _firestore;
  final GifticonPurchaseApiClient _gifticonPurchaseApiClient;
  final PointUsageCalculator _pointUsageCalculator;

  @override
  Future<PointPurchaseResult> purchaseEmoticon({
    required String userId,
    required String emoticonId,
  }) {
    if (userId.isEmpty || emoticonId.isEmpty) {
      throw const PointPurchaseException(
        'invalid_argument',
        '구매 정보가 올바르지 않습니다.',
      );
    }

    final userRef = _firestore.collection('users').doc(userId);
    final itemRef = _firestore.collection('emoticon').doc(emoticonId);
    final purchaseId = 'emoticon_$emoticonId';
    final purchaseRef = userRef.collection('users_purchase').doc(purchaseId);
    final ownedEmoticonRef = userRef
        .collection('users_emoticon')
        .doc(emoticonId);

    return _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      final itemSnapshot = await transaction.get(itemRef);
      final purchaseSnapshot = await transaction.get(purchaseRef);
      final ownedEmoticonSnapshot = await transaction.get(ownedEmoticonRef);

      if (purchaseSnapshot.exists || ownedEmoticonSnapshot.exists) {
        throw const PointPurchaseException('already_owned', '이미 구매한 이모티콘입니다.');
      }
      if (!itemSnapshot.exists || itemSnapshot.data()?['isActive'] == false) {
        throw const PointPurchaseException(
          'not_available',
          '현재 구매할 수 없는 이모티콘입니다.',
        );
      }

      final pricePoint = asPointInt(itemSnapshot.data()?['pricePoint']);
      final balance = _readBalance(userSnapshot);
      final usage = _pointUsageCalculator.calculate(
        freePointBalance: balance.freePoint,
        paidPointBalance: balance.paidPoint,
        pricePoint: pricePoint,
      );

      _writePurchase(
        transaction: transaction,
        userRef: userRef,
        purchaseRef: purchaseRef,
        purchaseId: purchaseId,
        purchaseType: 'emoticon',
        itemId: emoticonId,
        usage: usage,
      );
      final acquiredAt = FieldValue.serverTimestamp();
      transaction.set(ownedEmoticonRef, {
        'purchaseId': purchaseId,
        'isVisible': true,
        'displayOrder': 0,
        'acquiredAt': acquiredAt,
        'updatedAt': acquiredAt,
      });

      return _buildResult(purchaseId, usage);
    });
  }

  @override
  Future<PointPurchaseResult> purchaseGifticon({
    required String userId,
    required String gifticonId,
  }) {
    return _gifticonPurchaseApiClient.purchaseGifticon(
      userId: userId,
      gifticonId: gifticonId,
    );
  }

  _PointBalance _readBalance(
    DocumentSnapshot<Map<String, dynamic>> userSnapshot,
  ) {
    if (!userSnapshot.exists) {
      throw const PointPurchaseException(
        'user_not_found',
        '사용자 정보를 찾을 수 없습니다.',
      );
    }

    final userData = userSnapshot.data()!;
    return _PointBalance(
      freePoint: asPointInt(userData['freePointBalance']),
      paidPoint: asPointInt(userData['paidPointBalance']),
    );
  }

  void _writePurchase({
    required Transaction transaction,
    required DocumentReference<Map<String, dynamic>> userRef,
    required DocumentReference<Map<String, dynamic>> purchaseRef,
    required String purchaseId,
    required String purchaseType,
    required String itemId,
    required PointUsageCalculation usage,
  }) {
    final createdAt = FieldValue.serverTimestamp();

    transaction.update(userRef, {
      'freePointBalance': usage.remainingFreePoint,
      'paidPointBalance': usage.remainingPaidPoint,
      'updatedAt': createdAt,
    });

    transaction.set(purchaseRef, {
      'purchaseType': purchaseType,
      'itemId': itemId,
      'paymentMethod': 'point',
      'usedFreePoint': usage.usedFreePoint,
      'usedPaidPoint': usage.usedPaidPoint,
      'paidAmount': 0,
      'status': 'paid',
      'createdAt': createdAt,
      'usedAt': null,
    });

    _writePointTransaction(
      transaction: transaction,
      userRef: userRef,
      purchaseId: purchaseId,
      usage: usage,
      createdAt: createdAt,
    );
  }

  void _writePointTransaction({
    required Transaction transaction,
    required DocumentReference<Map<String, dynamic>> userRef,
    required String purchaseId,
    required PointUsageCalculation usage,
    required FieldValue createdAt,
  }) {
    final usedPoint = usage.usedFreePoint + usage.usedPaidPoint;
    if (usedPoint <= 0) {
      return;
    }

    final transactionRef = userRef.collection('users_point_transaction').doc();
    final pointType = usage.usedFreePoint > 0 && usage.usedPaidPoint > 0
        ? 'mixed'
        : usage.usedFreePoint > 0
        ? 'free'
        : 'paid';

    transaction.set(transactionRef, {
      'type': 'use',
      'source': 'purchase',
      'amount': -usedPoint,
      'pointType': pointType,
      'usedFreePoint': usage.usedFreePoint,
      'usedPaidPoint': usage.usedPaidPoint,
      'freePointBalanceAfter': usage.remainingFreePoint,
      'paidPointBalanceAfter': usage.remainingPaidPoint,
      'refType': 'purchase',
      'refId': purchaseId,
      'createdAt': createdAt,
    });
  }

  PointPurchaseResult _buildResult(
    String purchaseId,
    PointUsageCalculation usage,
  ) {
    return PointPurchaseResult(
      purchaseId: purchaseId,
      usedFreePoint: usage.usedFreePoint,
      usedPaidPoint: usage.usedPaidPoint,
      remainingFreePoint: usage.remainingFreePoint,
      remainingPaidPoint: usage.remainingPaidPoint,
    );
  }
}

class _PointBalance {
  const _PointBalance({required this.freePoint, required this.paidPoint});

  final int freePoint;
  final int paidPoint;
}
