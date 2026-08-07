import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import '../models/point_models.dart';

class PortonePaymentPreparation {
  const PortonePaymentPreparation({
    required this.paymentId,
    required this.pointPackageId,
    required this.orderName,
    required this.pointAmount,
    required this.totalAmount,
    required this.storeId,
    required this.channelKey,
  });

  final String paymentId;
  final String pointPackageId;
  final String orderName;
  final int pointAmount;
  final int totalAmount;
  final String storeId;
  final String channelKey;

  factory PortonePaymentPreparation.fromMap(Map<String, dynamic> data) {
    return PortonePaymentPreparation(
      paymentId: data['paymentId'] as String? ?? '',
      pointPackageId: data['pointPackageId'] as String? ?? '',
      orderName: data['orderName'] as String? ?? '얌얌 포인트 충전',
      pointAmount: asPointInt(data['pointAmount']),
      totalAmount: asPointInt(data['totalAmount']),
      storeId: data['storeId'] as String? ?? '',
      channelKey: data['channelKey'] as String? ?? '',
    );
  }

  void validate() {
    if (paymentId.isEmpty ||
        pointPackageId.isEmpty ||
        pointAmount <= 0 ||
        totalAmount <= 0 ||
        storeId.isEmpty ||
        channelKey.isEmpty) {
      throw const PointPurchaseException(
        'invalid_payment_preparation',
        '결제 준비 정보를 확인할 수 없습니다.',
      );
    }
  }
}

class PortonePointPaymentApiClient {
  PortonePointPaymentApiClient({
    FirebaseAuth? firebaseAuth,
    String baseUrl = defaultBaseUrl,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _baseUrl = _normalizeBaseUrl(baseUrl);

  static const String defaultBaseUrl = String.fromEnvironment(
    'YAMYAM_API_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const Duration _requestTimeout = Duration(seconds: 65);

  final FirebaseAuth _firebaseAuth;
  final String _baseUrl;

  Future<PortonePaymentPreparation> preparePayment({
    required String userId,
    required String pointPackageId,
  }) async {
    if (userId.isEmpty || pointPackageId.isEmpty) {
      throw const PointPurchaseException(
        'invalid_argument',
        '결제 상품 정보가 올바르지 않습니다.',
      );
    }

    final response = await _post(
      userId: userId,
      path: '/point-payments/${Uri.encodeComponent(pointPackageId)}/prepare',
    );
    final preparation = PortonePaymentPreparation.fromMap(response);
    preparation.validate();
    return preparation;
  }

  Future<PointPurchaseResult> completePayment({
    required String userId,
    required String paymentId,
  }) async {
    if (userId.isEmpty || paymentId.isEmpty) {
      throw const PointPurchaseException(
        'invalid_argument',
        '결제 확인 정보가 올바르지 않습니다.',
      );
    }

    final response = await _post(
      userId: userId,
      path: '/point-payments/${Uri.encodeComponent(paymentId)}/complete',
    );
    return PointPurchaseResult(
      purchaseId: response['purchaseId'] as String? ?? paymentId,
      usedFreePoint: 0,
      usedPaidPoint: 0,
      remainingFreePoint: asPointInt(response['remainingFreePoint']),
      remainingPaidPoint: asPointInt(response['remainingPaidPoint']),
    );
  }

  Future<Map<String, dynamic>> _post({
    required String userId,
    required String path,
  }) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw const PointPurchaseException(
        'unauthenticated',
        '로그인 후 다시 시도해 주세요.',
      );
    }
    if (currentUser.uid != userId) {
      throw const PointPurchaseException(
        'user_mismatch',
        '현재 로그인한 사용자 정보가 일치하지 않습니다.',
      );
    }

    final idToken = await currentUser.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const PointPurchaseException(
        'token_not_found',
        '로그인 인증 정보를 가져오지 못했습니다.',
      );
    }

    final client = HttpClient();
    try {
      final request = await client
          .postUrl(Uri.parse('$_baseUrl$path'))
          .timeout(_requestTimeout);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final response = await request.close().timeout(_requestTimeout);
      final body = await utf8.decoder
          .bind(response)
          .join()
          .timeout(_requestTimeout);
      final data = _decodeResponse(body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _toPurchaseException(response.statusCode, data);
      }
      return data;
    } on PointPurchaseException {
      rethrow;
    } on TimeoutException {
      throw const PointPurchaseException(
        'request_timeout',
        '결제 서버 응답이 지연되고 있습니다. 잠시 후 다시 시도해 주세요.',
      );
    } on SocketException {
      throw const PointPurchaseException(
        'server_unreachable',
        '결제 서버에 연결할 수 없습니다. FastAPI 서버 실행 상태를 확인해 주세요.',
      );
    } on FormatException {
      throw const PointPurchaseException(
        'invalid_response',
        '결제 서버 응답을 확인할 수 없습니다.',
      );
    } finally {
      client.close(force: true);
    }
  }

  static Map<String, dynamic> _decodeResponse(String body) {
    if (body.isEmpty) return const {};
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const FormatException('Response is not a JSON object.');
    }
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }

  static PointPurchaseException _toPurchaseException(
    int statusCode,
    Map<String, dynamic> responseData,
  ) {
    final detail = responseData['detail'];
    if (detail is Map) {
      return PointPurchaseException(
        detail['code']?.toString() ?? 'payment_failed',
        detail['message']?.toString() ?? '포인트 결제에 실패했습니다.',
      );
    }
    if (detail is String && detail.isNotEmpty) {
      return PointPurchaseException('payment_failed', detail);
    }
    if (statusCode == HttpStatus.unauthorized) {
      return const PointPurchaseException(
        'unauthenticated',
        '로그인 정보가 만료되었습니다. 다시 로그인해 주세요.',
      );
    }
    return const PointPurchaseException('payment_failed', '포인트 결제에 실패했습니다.');
  }

  static String _normalizeBaseUrl(String baseUrl) {
    final trimmed = baseUrl.trim();
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }
}
