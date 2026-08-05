import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/point_models.dart';

abstract interface class PointShopRepository {
  Stream<PointBalance> watchPointBalance(String userId);

  Stream<List<EmoticonProduct>> watchEmoticons(String userId);

  Stream<List<GifticonProduct>> watchGifticons();

  Stream<List<PointPackage>> watchPointPackages();
}

class FirestorePointShopRepository implements PointShopRepository {
  FirestorePointShopRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<PointBalance> watchPointBalance(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) => PointBalance.fromMap(snapshot.data()));
  }

  @override
  Stream<List<EmoticonProduct>> watchEmoticons(String userId) {
    late final StreamController<List<EmoticonProduct>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    productSubscription;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    purchaseSubscription;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    ownershipSubscription;
    QuerySnapshot<Map<String, dynamic>>? productSnapshot;
    Set<String>? purchasedIds;
    Set<String>? ownedIds;

    void emitAvailableProducts() {
      final snapshot = productSnapshot;
      final purchased = purchasedIds;
      final owned = ownedIds;
      if (snapshot == null ||
          purchased == null ||
          owned == null ||
          controller.isClosed) {
        return;
      }
      final unavailableIds = {...purchased, ...owned};
      controller.add(
        snapshot.docs
            .where(
              (document) =>
                  document.data()['isActive'] != false &&
                  !unavailableIds.contains(document.id),
            )
            .map(
              (document) =>
                  EmoticonProduct.fromMap(document.id, document.data()),
            )
            .toList(growable: false),
      );
    }

    controller = StreamController<List<EmoticonProduct>>(
      onListen: () {
        productSubscription = _firestore
            .collection('emoticon')
            .snapshots()
            .listen((snapshot) {
              productSnapshot = snapshot;
              emitAvailableProducts();
            }, onError: controller.addError);
        purchaseSubscription = _firestore
            .collection('users')
            .doc(userId)
            .collection('users_purchase')
            .where('purchaseType', isEqualTo: 'emoticon')
            .snapshots()
            .listen((snapshot) {
              purchasedIds = snapshot.docs
                  .where((document) {
                    final status = document.data()['status'];
                    return status != 'cancelled' && status != 'refunded';
                  })
                  .map(
                    (document) => document.data()['itemId']?.toString() ?? '',
                  )
                  .where((id) => id.isNotEmpty)
                  .toSet();
              emitAvailableProducts();
            }, onError: controller.addError);
        ownershipSubscription = _firestore
            .collection('users')
            .doc(userId)
            .collection('users_emoticon')
            .snapshots()
            .listen((snapshot) {
              ownedIds = snapshot.docs.map((document) => document.id).toSet();
              emitAvailableProducts();
            }, onError: controller.addError);
      },
      onCancel: () async {
        await productSubscription?.cancel();
        await purchaseSubscription?.cancel();
        await ownershipSubscription?.cancel();
      },
    );
    return controller.stream;
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
  Stream<PointBalance> watchPointBalance(String userId) {
    return Stream.value(const PointBalance(freePoint: 0, paidPoint: 0));
  }

  @override
  Stream<List<EmoticonProduct>> watchEmoticons(String userId) {
    const characterFiles = [
      '01_smile.svg',
      '02_bigsmile.svg',
      '03_sad.svg',
      '04_crying.svg',
      '05_angry.svg',
      '06_surprised.svg',
      '07_love.svg',
      '08_wink.svg',
      '09_shy.svg',
      '10_sleepy.svg',
      '11_dizzy.svg',
      '12_cool.svg',
      '13_worried.svg',
      '14_blank.svg',
      '15_clap.svg',
      '16_victory.svg',
      '17_thanks.svg',
      '18_fighting.svg',
      '19_hurt.svg',
      '20_curious.svg',
    ];

    return Stream.value([
      EmoticonProduct(
        id: 'emo_test_character',
        name: '이모티콘 테스트팩 (캐릭터형)',
        imageUrl: 'assets/emoticons/character/01_smile.svg',
        pricePoint: 500,
        items: characterFiles
            .map(
              (f) => EmoticonItem(
                itemId: f,
                imageUrl: 'assets/emoticons/character/$f',
              ),
            )
            .toList(),
      ),
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
