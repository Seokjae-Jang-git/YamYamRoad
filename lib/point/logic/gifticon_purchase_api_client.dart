import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import '../models/point_models.dart';

class GifticonPurchaseApiClient {
  GifticonPurchaseApiClient({
    FirebaseAuth? firebaseAuth,
    String baseUrl = defaultBaseUrl,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _baseUrl = _normalizeBaseUrl(baseUrl);

  static const String defaultBaseUrl = String.fromEnvironment(
    'YAMYAM_API_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const Duration _requestTimeout = Duration(seconds: 15);

  final FirebaseAuth _firebaseAuth;
  final String _baseUrl;

  Future<PointPurchaseResult> purchaseGifticon({
    required String userId,
    required String gifticonId,
  }) async {
    if (userId.isEmpty || gifticonId.isEmpty) {
      throw const PointPurchaseException(
        'invalid_argument',
        '구매 정보가 올바르지 않습니다.',
      );
    }

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

    final uri = Uri.parse(
      '$_baseUrl/gifticons/${Uri.encodeComponent(gifticonId)}/purchase',
    );
    final client = HttpClient();

    try {
      final request = await client.postUrl(uri).timeout(_requestTimeout);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final response = await request.close().timeout(_requestTimeout);
      final responseBody = await utf8.decoder
          .bind(response)
          .join()
          .timeout(_requestTimeout);

      final responseData = _decodeResponse(responseBody);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _toPurchaseException(response.statusCode, responseData);
      }

      return PointPurchaseResult(
        purchaseId: responseData['purchaseId'] as String? ?? '',
        usedFreePoint: asPointInt(responseData['usedFreePoint']),
        usedPaidPoint: asPointInt(responseData['usedPaidPoint']),
        remainingFreePoint: asPointInt(responseData['remainingFreePoint']),
        remainingPaidPoint: asPointInt(responseData['remainingPaidPoint']),
      );
    } on PointPurchaseException {
      rethrow;
    } on TimeoutException {
      throw const PointPurchaseException(
        'request_timeout',
        '구매 서버 응답이 지연되고 있습니다. 잠시 후 다시 시도해 주세요.',
      );
    } on SocketException {
      throw const PointPurchaseException(
        'server_unreachable',
        '구매 서버에 연결할 수 없습니다. FastAPI 서버 실행 상태를 확인해 주세요.',
      );
    } on FormatException {
      throw const PointPurchaseException(
        'invalid_response',
        '구매 서버 응답을 확인할 수 없습니다.',
      );
    } finally {
      client.close(force: true);
    }
  }

  static Map<String, dynamic> _decodeResponse(String responseBody) {
    if (responseBody.isEmpty) return const {};

    final decoded = jsonDecode(responseBody);
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
      final code = detail['code']?.toString() ?? 'purchase_failed';
      final message = detail['message']?.toString() ?? '기프티콘 구매에 실패했습니다.';
      return PointPurchaseException(code, message);
    }
    if (detail is String && detail.isNotEmpty) {
      return PointPurchaseException('purchase_failed', detail);
    }
    if (statusCode == HttpStatus.unauthorized) {
      return const PointPurchaseException(
        'unauthenticated',
        '로그인 정보가 만료되었습니다. 다시 로그인해 주세요.',
      );
    }

    return const PointPurchaseException('purchase_failed', '기프티콘 구매에 실패했습니다.');
  }

  static String _normalizeBaseUrl(String baseUrl) {
    final trimmed = baseUrl.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}
