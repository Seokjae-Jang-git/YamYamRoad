import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import '../models/recommendation_models.dart';

class RecommendationApiClient {
  RecommendationApiClient({
    FirebaseAuth? firebaseAuth,
    String baseUrl = defaultBaseUrl,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _baseUrl = _normalizeBaseUrl(baseUrl);

  static const String defaultBaseUrl = String.fromEnvironment(
    'YAMYAM_API_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const Duration _requestTimeout = Duration(seconds: 15);

  final FirebaseAuth _firebaseAuth;
  final String _baseUrl;

  Future<RecommendationResult> fetchRecommendations({
    required String userId,
    String? currentRegionId,
    double? userLat,
    double? userLng,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      throw const RecommendationException(
        'invalid_argument',
        '사용자 정보가 올바르지 않습니다.',
      );
    }
    if ((userLat == null) != (userLng == null)) {
      throw const RecommendationException(
        'invalid_location',
        '위도와 경도를 함께 전달해 주세요.',
      );
    }
    if (userLat != null &&
        (userLat < -90 || userLat > 90 || userLng! < -180 || userLng > 180)) {
      throw const RecommendationException(
        'invalid_location',
        '현재 위치 정보가 올바르지 않습니다.',
      );
    }

    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw const RecommendationException(
        'unauthenticated',
        '로그인 후 추천을 요청해 주세요.',
      );
    }
    if (currentUser.uid != normalizedUserId) {
      throw const RecommendationException(
        'user_mismatch',
        '현재 로그인한 사용자 정보가 일치하지 않습니다.',
      );
    }

    final idToken = await currentUser.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const RecommendationException(
        'token_not_found',
        '로그인 인증 정보를 가져오지 못했습니다.',
      );
    }

    final queryParameters = <String, String>{
      'userId': normalizedUserId,
      if (currentRegionId?.trim().isNotEmpty == true)
        'currentRegionId': currentRegionId!.trim(),
      if (userLat != null) 'userLat': userLat.toString(),
      if (userLng != null) 'userLng': userLng.toString(),
    };
    final uri = Uri.parse(
      '$_baseUrl/recommend',
    ).replace(queryParameters: queryParameters);
    final client = HttpClient();

    try {
      final request = await client.getUrl(uri).timeout(_requestTimeout);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final response = await request.close().timeout(_requestTimeout);
      final responseBody = await utf8.decoder
          .bind(response)
          .join()
          .timeout(_requestTimeout);
      final responseData = _decodeResponse(responseBody);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _toRecommendationException(response.statusCode, responseData);
      }

      final result = RecommendationResult.fromMap(responseData);
      if (result.userId != normalizedUserId) {
        throw const RecommendationException(
          'invalid_response',
          '추천 서버의 사용자 정보가 일치하지 않습니다.',
        );
      }
      return result;
    } on RecommendationException {
      rethrow;
    } on TimeoutException {
      throw const RecommendationException(
        'request_timeout',
        '추천 서버 응답이 지연되고 있습니다. 잠시 후 다시 시도해 주세요.',
      );
    } on SocketException {
      throw const RecommendationException(
        'server_unreachable',
        '추천 서버에 연결할 수 없습니다.',
      );
    } on FormatException {
      throw const RecommendationException(
        'invalid_response',
        '추천 서버 응답을 확인할 수 없습니다.',
      );
    } finally {
      client.close(force: true);
    }
  }

  static Map<String, dynamic> _decodeResponse(String responseBody) {
    if (responseBody.trim().isEmpty) {
      throw const FormatException('Response body is empty.');
    }
    final decoded = jsonDecode(responseBody);
    if (decoded is! Map) {
      throw const FormatException('Response is not a JSON object.');
    }
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }

  static RecommendationException _toRecommendationException(
    int statusCode,
    Map<String, dynamic> responseData,
  ) {
    final detail = responseData['detail'];
    if (detail is Map) {
      final code = detail['code']?.toString() ?? 'recommendation_failed';
      final message = detail['message']?.toString() ?? '추천을 불러오지 못했습니다.';
      return RecommendationException(code, message);
    }
    if (detail is String && detail.trim().isNotEmpty) {
      return RecommendationException('recommendation_failed', detail.trim());
    }
    if (statusCode == HttpStatus.unauthorized) {
      return const RecommendationException(
        'unauthenticated',
        '로그인 정보가 만료되었습니다. 다시 로그인해 주세요.',
      );
    }
    return const RecommendationException(
      'recommendation_failed',
      '추천을 불러오지 못했습니다.',
    );
  }

  static String _normalizeBaseUrl(String baseUrl) {
    final trimmed = baseUrl.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(baseUrl, 'baseUrl', 'API 주소가 비어 있습니다.');
    }
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }
}
