import 'package:cloud_firestore/cloud_firestore.dart';
import '../../point/models/point_models.dart';

/// emoticon 컬렉션에서 상품 정보를 읽고 캐싱합니다.
/// 여러 글/댓글이 같은 상품을 참조할 때 매번 Firestore를 다시 읽지 않도록
/// 앱 전역에서 공유하는 static 캐시를 씁니다.
class EmoticonProductRepository {
  EmoticonProductRepository._();

  static final _db = FirebaseFirestore.instance;
  static final Map<String, EmoticonProduct> _cache = {};
  static final Map<String, Future<EmoticonProduct?>> _inFlight = {};

  static Future<Map<String, EmoticonProduct>> fetchProducts(
      Iterable<String> productIds,
      ) async {
    final ids = productIds.toSet();
    await Future.wait(ids.map(_fetchOne));
    return {
      for (final id in ids)
        if (_cache.containsKey(id)) id: _cache[id]!,
    };
  }

  static Future<EmoticonProduct?> _fetchOne(String productId) {
    if (_cache.containsKey(productId)) return Future.value(_cache[productId]);
    return _inFlight.putIfAbsent(productId, () async {
      final doc = await _db.collection('emoticon').doc(productId).get();
      if (!doc.exists) return null;
      final product = EmoticonProduct.fromMap(doc.id, doc.data()!);
      _cache[productId] = product;
      return product;
    });
  }
}