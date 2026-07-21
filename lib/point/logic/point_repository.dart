import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/point_models.dart';

abstract interface class PointShopRepository {
  Stream<List<EmoticonProduct>> watchEmoticons();

  Stream<List<GifticonProduct>> watchGifticons();

  Stream<List<PointPackage>> watchPointPackages();
}

class FirestorePointShopRepository implements PointShopRepository {
  FirestorePointShopRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<EmoticonProduct>> watchEmoticons() {
    return _firestore
        .collection('emoticon')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((document) => document.data()['isActive'] != false)
              .map(
                (document) =>
                    EmoticonProduct.fromMap(document.id, document.data()),
              )
              .toList(growable: false),
        );
  }

  @override
  Stream<List<GifticonProduct>> watchGifticons() {
    return _firestore
        .collection('gifticon')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((document) => document.data()['isActive'] != false)
              .map(
                (document) =>
                    GifticonProduct.fromMap(document.id, document.data()),
              )
              .toList(growable: false),
        );
  }

  @override
  Stream<List<PointPackage>> watchPointPackages() {
    return _firestore.collection('point_package').snapshots().map((snapshot) {
      final packages = snapshot.docs
          .where((document) => document.data()['isActive'] != false)
          .map((document) => PointPackage.fromMap(document.id, document.data()))
          .toList();

      packages.sort((left, right) => left.priceCash.compareTo(right.priceCash));
      return List<PointPackage>.unmodifiable(packages);
    });
  }
}

class MockPointShopRepository implements PointShopRepository {
  const MockPointShopRepository();

  @override
  Stream<List<EmoticonProduct>> watchEmoticons() {
    return Stream.value(const [
      EmoticonProduct(
        id: 'emo_01',
        name: '냠냠 행복',
        imageUrl: '',
        pricePoint: 500,
        items: [
          EmoticonItem(itemId: 'item_01', imageUrl: ''),
          EmoticonItem(itemId: 'item_02', imageUrl: ''),
          EmoticonItem(itemId: 'item_03', imageUrl: ''),
          EmoticonItem(itemId: 'item_04', imageUrl: ''),
          EmoticonItem(itemId: 'item_05', imageUrl: ''),
          EmoticonItem(itemId: 'item_06', imageUrl: ''),
        ],
      ),
      EmoticonProduct(
        id: 'emo_02',
        name: '오늘도 카페',
        imageUrl: '',
        pricePoint: 700,
        items: [
          EmoticonItem(itemId: 'item_01', imageUrl: ''),
          EmoticonItem(itemId: 'item_02', imageUrl: ''),
          EmoticonItem(itemId: 'item_03', imageUrl: ''),
          EmoticonItem(itemId: 'item_04', imageUrl: ''),
        ],
      ),
      EmoticonProduct(
        id: 'emo_03',
        name: '빵순이 하루',
        imageUrl: '',
        pricePoint: 900,
        items: [
          EmoticonItem(itemId: 'item_01', imageUrl: ''),
          EmoticonItem(itemId: 'item_02', imageUrl: ''),
          EmoticonItem(itemId: 'item_03', imageUrl: ''),
        ],
      ),
      EmoticonProduct(
        id: 'emo_04',
        name: '디저트 원정대',
        imageUrl: '',
        pricePoint: 900,
        items: [
          EmoticonItem(itemId: 'item_01', imageUrl: ''),
          EmoticonItem(itemId: 'item_02', imageUrl: ''),
          EmoticonItem(itemId: 'item_03', imageUrl: ''),
        ],
      ),
      EmoticonProduct(
        id: 'emo_05',
        name: '커피 한 잔',
        imageUrl: '',
        pricePoint: 1000,
        items: [
          EmoticonItem(itemId: 'item_01', imageUrl: ''),
          EmoticonItem(itemId: 'item_02', imageUrl: ''),
          EmoticonItem(itemId: 'item_03', imageUrl: ''),
        ],
      ),
      EmoticonProduct(
        id: 'emo_06',
        name: '얌얌 리액션',
        imageUrl: '',
        pricePoint: 1200,
        items: [
          EmoticonItem(itemId: 'item_01', imageUrl: ''),
          EmoticonItem(itemId: 'item_02', imageUrl: ''),
          EmoticonItem(itemId: 'item_03', imageUrl: ''),
        ],
      ),
    ]);
  }

  @override
  Stream<List<GifticonProduct>> watchGifticons() {
    return Stream.value(const [
      GifticonProduct(
        id: 'gift_01',
        name: '아메리카노',
        brandName: '카페 브랜드 A',
        requiredPoint: 4500,
      ),
      GifticonProduct(
        id: 'gift_02',
        name: '조각 케이크',
        brandName: '디저트 브랜드 B',
        requiredPoint: 6500,
      ),
      GifticonProduct(
        id: 'gift_03',
        name: '도넛 세트',
        brandName: '도넛 브랜드 C',
        requiredPoint: 8000,
      ),
      GifticonProduct(
        id: 'gift_04',
        name: '샌드위치 세트',
        brandName: '카페 브랜드 D',
        requiredPoint: 9500,
      ),
    ]);
  }

  @override
  Stream<List<PointPackage>> watchPointPackages() {
    return Stream.value(const [
      PointPackage(
        id: 'point_01',
        name: '100 포인트',
        pointAmount: 100,
        priceCash: 1000,
      ),
      PointPackage(
        id: 'point_02',
        name: '300 포인트',
        pointAmount: 300,
        priceCash: 3000,
      ),
      PointPackage(
        id: 'point_03',
        name: '500 포인트',
        pointAmount: 500,
        priceCash: 4900,
      ),
      PointPackage(
        id: 'point_04',
        name: '1,000 포인트',
        pointAmount: 1000,
        priceCash: 9900,
      ),
      PointPackage(
        id: 'point_05',
        name: '2,000 포인트',
        pointAmount: 2000,
        priceCash: 19800,
      ),
      PointPackage(
        id: 'point_06',
        name: '3,000 포인트',
        pointAmount: 3000,
        priceCash: 29800,
      ),
      PointPackage(
        id: 'point_07',
        name: '5,000 포인트',
        pointAmount: 5000,
        priceCash: 49800,
      ),
      PointPackage(
        id: 'point_08',
        name: '10,000 포인트',
        pointAmount: 10000,
        priceCash: 99800,
      ),
    ]);
  }
}
