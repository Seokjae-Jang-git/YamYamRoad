class EmoticonItem {
  const EmoticonItem({required this.itemId, required this.imageUrl});

  final String itemId;
  final String imageUrl;

  factory EmoticonItem.fromMap(Map<String, dynamic> data) {
    return EmoticonItem(
      itemId: data['itemId'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
    );
  }
}

class EmoticonProduct {
  const EmoticonProduct({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.items,
    required this.pricePoint,
    this.isPurchased = false,
  });

  final String id;
  final String name;
  final String imageUrl;
  final List<EmoticonItem> items;
  final int pricePoint;
  final bool isPurchased;

  factory EmoticonProduct.fromMap(
    String documentId,
    Map<String, dynamic> data, {
    bool isPurchased = false,
  }) {
    final rawItems = data['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map(
                (item) => EmoticonItem.fromMap(
                  item.map((key, value) => MapEntry(key.toString(), value)),
                ),
              )
              .where(
                (item) => item.itemId.isNotEmpty && item.imageUrl.isNotEmpty,
              )
              .toList(growable: false)
        : const <EmoticonItem>[];

    return EmoticonProduct(
      id: documentId,
      name: data['name'] as String? ?? '이름 없는 이모티콘',
      imageUrl: data['imageUrl'] as String? ?? '',
      items: items,
      pricePoint: _asInt(data['pricePoint']),
      isPurchased: isPurchased,
    );
  }
}

class GifticonProduct {
  const GifticonProduct({
    required this.id,
    required this.name,
    required this.requiredPoint,
    this.brandName,
    this.imageUrl,
    this.stockCount,
  });

  final String id;
  final String name;
  final int requiredPoint;
  final String? brandName;
  final String? imageUrl;
  final int? stockCount;

  bool get isSoldOut => stockCount != null && stockCount! <= 0;

  factory GifticonProduct.fromMap(
    String documentId,
    Map<String, dynamic> data,
  ) {
    return GifticonProduct(
      id: documentId,
      name: data['name'] as String? ?? '이름 없는 기프티콘',
      requiredPoint: _asInt(data['requiredPoint']),
      brandName: data['brandName'] as String?,
      imageUrl: data['imageUrl'] as String?,
      stockCount: data['stockCount'] == null
          ? null
          : _asInt(data['stockCount']),
    );
  }
}

class PointPackage {
  const PointPackage({
    required this.id,
    required this.name,
    required this.pointAmount,
    required this.priceCash,
  });

  final String id;
  final String name;
  final int pointAmount;
  final int priceCash;

  factory PointPackage.fromMap(String documentId, Map<String, dynamic> data) {
    return PointPackage(
      id: documentId,
      name: data['name'] as String? ?? '포인트 상품',
      pointAmount: _asInt(data['pointAmount']),
      priceCash: _asInt(data['priceCash']),
    );
  }
}

class PointBalance {
  const PointBalance({required this.freePoint, required this.paidPoint});

  final int freePoint;
  final int paidPoint;

  int get totalPoint => freePoint + paidPoint;

  factory PointBalance.fromMap(Map<String, dynamic>? data) {
    return PointBalance(
      freePoint: asPointInt(data?['freePointBalance']),
      paidPoint: asPointInt(data?['paidPointBalance']),
    );
  }
}

class PointPurchaseResult {
  const PointPurchaseResult({
    required this.purchaseId,
    required this.usedFreePoint,
    required this.usedPaidPoint,
    required this.remainingFreePoint,
    required this.remainingPaidPoint,
  });

  final String purchaseId;
  final int usedFreePoint;
  final int usedPaidPoint;
  final int remainingFreePoint;
  final int remainingPaidPoint;
}

class PointPurchaseException implements Exception {
  const PointPurchaseException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

int asPointInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int _asInt(dynamic value) => asPointInt(value);
