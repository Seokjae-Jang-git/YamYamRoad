import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class EmoticonService {
  static final _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _purchaseCol(String uid) =>
      _db.collection('users').doc(uid).collection('users_purchase');

  /// FirestorePointPurchaseService.purchaseEmoticon()이 쓰는
  /// users/{uid}/users_purchase 문서를 기준으로 구매한 상품 id를 구독합니다.
  static Stream<List<String>> watchPurchasedProductIds(String uid) {
    return _purchaseCol(uid)
        .where('purchaseType', isEqualTo: 'emoticon')
        .where('status', isEqualTo: 'paid')
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => d.data()['itemId'] as String?)
        .whereType<String>()
        .toSet()
        .toList());
  }

  /// 포인트 구매 화면(이모티콘 구매 버튼)에서 호출
  static Future<bool> purchasePack({
    required String uid,
    required String packId,
    required int price,
  }) {
    final userRef = _db.collection('users').doc(uid);
    final purchaseRef = _purchaseCol(uid).doc(); // 자동 id

    return _db.runTransaction<bool>((tx) async {
      // 이미 보유중이면 그대로 성공 처리
      final existing = await _purchaseCol(uid)
          .where('purchaseType', isEqualTo: 'emoticon')
          .where('status', isEqualTo: 'paid')
          .where('itemId', isEqualTo: packId)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) return true;

      final userSnap = await tx.get(userRef);
      final data = userSnap.data() ?? {};
      final freePoint = (data['freePointBalance'] as num?)?.toInt() ?? 0;
      final paidPoint = (data['paidPointBalance'] as num?)?.toInt() ?? 0;

      if (freePoint + paidPoint < price) return false; // 포인트 부족

      // 무료 포인트부터 우선 차감, 부족분은 유료 포인트에서 차감
      final usedFree = price <= freePoint ? price : freePoint;
      final usedPaid = price - usedFree;

      tx.update(userRef, {
        'freePointBalance': freePoint - usedFree,
        'paidPointBalance': paidPoint - usedPaid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.set(purchaseRef, {
        'createdAt': FieldValue.serverTimestamp(),
        'itemId': packId,
        'purchaseType': 'emoticon',
        'paymentMethod': 'point',
        'paidAmount': 0,
        'status': 'paid',
        'usedAt': null,
        'usedFreePoint': usedFree,
        'usedPaidPoint': usedPaid,
      });

      return true;
    });
  }
}