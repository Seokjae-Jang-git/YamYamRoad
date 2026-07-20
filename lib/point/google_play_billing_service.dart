import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

enum GooglePlayPurchaseEventType { pending, received, canceled, error }

class GooglePlayPurchaseEvent {
  const GooglePlayPurchaseEvent({
    required this.type,
    required this.productId,
    required this.message,
    this.purchaseId,
    this.purchaseToken,
  });

  final GooglePlayPurchaseEventType type;
  final String productId;
  final String message;
  final String? purchaseId;
  final String? purchaseToken;
}

class GooglePlayProductCatalog {
  const GooglePlayProductCatalog({
    required this.isAvailable,
    required this.products,
    required this.notFoundProductIds,
    this.errorMessage,
  });

  final bool isAvailable;
  final Map<String, ProductDetails> products;
  final Set<String> notFoundProductIds;
  final String? errorMessage;
}

class GooglePlayBillingService {
  GooglePlayBillingService({InAppPurchase? inAppPurchase})
    : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance {
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        _events.add(
          GooglePlayPurchaseEvent(
            type: GooglePlayPurchaseEventType.error,
            productId: '',
            message: '결제 정보를 확인하지 못했습니다: $error',
          ),
        );
      },
    );
  }

  final InAppPurchase _inAppPurchase;
  final StreamController<GooglePlayPurchaseEvent> _events =
      StreamController<GooglePlayPurchaseEvent>.broadcast();
  late final StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;
  final Map<String, ProductDetails> _products = {};

  Stream<GooglePlayPurchaseEvent> get events => _events.stream;

  Future<GooglePlayProductCatalog> loadProducts(Set<String> productIds) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const GooglePlayProductCatalog(
        isAvailable: false,
        products: {},
        notFoundProductIds: {},
        errorMessage: 'Google Play 결제는 Android 앱에서만 테스트할 수 있습니다.',
      );
    }

    final isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      return const GooglePlayProductCatalog(
        isAvailable: false,
        products: {},
        notFoundProductIds: {},
        errorMessage: '현재 기기에서 Google Play 결제를 사용할 수 없습니다.',
      );
    }

    final response = await _inAppPurchase.queryProductDetails(productIds);
    if (response.error != null) {
      return GooglePlayProductCatalog(
        isAvailable: true,
        products: const {},
        notFoundProductIds: response.notFoundIDs.toSet(),
        errorMessage: response.error!.message,
      );
    }

    _products
      ..clear()
      ..addEntries(
        response.productDetails.map((item) => MapEntry(item.id, item)),
      );

    return GooglePlayProductCatalog(
      isAvailable: true,
      products: Map.unmodifiable(_products),
      notFoundProductIds: response.notFoundIDs.toSet(),
    );
  }

  Future<void> buyConsumable(String productId) async {
    final product = _products[productId];
    if (product == null) {
      throw StateError('Google Play에 등록되지 않은 포인트 상품입니다.');
    }

    final purchaseParam = PurchaseParam(productDetails: product);
    final started = await _inAppPurchase.buyConsumable(
      purchaseParam: purchaseParam,
      autoConsume: true,
    );
    if (!started) {
      throw StateError('Google Play 결제 화면을 열지 못했습니다.');
    }
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final purchase in purchaseDetailsList) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _events.add(
            GooglePlayPurchaseEvent(
              type: GooglePlayPurchaseEventType.pending,
              productId: purchase.productID,
              message: 'Google Play 결제를 처리하고 있습니다.',
            ),
          );
          break;
        case PurchaseStatus.canceled:
          _events.add(
            GooglePlayPurchaseEvent(
              type: GooglePlayPurchaseEventType.canceled,
              productId: purchase.productID,
              message: '결제가 취소되었습니다.',
            ),
          );
          break;
        case PurchaseStatus.error:
          _events.add(
            GooglePlayPurchaseEvent(
              type: GooglePlayPurchaseEventType.error,
              productId: purchase.productID,
              message: purchase.error?.message ?? 'Google Play 결제에 실패했습니다.',
            ),
          );
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // TODO: 서버에서 purchaseToken 검증 및 중복 확인 후 포인트를 지급한다.
          // 현재 단계에서는 테스트 결제 수신만 확인하고 포인트는 지급하지 않는다.
          if (purchase.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchase);
          }
          _events.add(
            GooglePlayPurchaseEvent(
              type: GooglePlayPurchaseEventType.received,
              productId: purchase.productID,
              purchaseId: purchase.purchaseID,
              purchaseToken: purchase.verificationData.serverVerificationData,
              message: 'Google Play 테스트 결제를 확인했습니다.',
            ),
          );
          break;
      }
    }
  }

  Future<void> dispose() async {
    await _purchaseSubscription.cancel();
    await _events.close();
  }
}
