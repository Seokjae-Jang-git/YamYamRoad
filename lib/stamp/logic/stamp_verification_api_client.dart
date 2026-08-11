import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import 'receipt_ocr_checker.dart';
import 'stamp_receipt_verification_service.dart';
import '../models/stamp_verification_models.dart';

class StampVerificationApiClient {
  StampVerificationApiClient({
    FirebaseAuth? firebaseAuth,
    String baseUrl = defaultBaseUrl,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _baseUrl = _normalizeBaseUrl(baseUrl);

  static const String defaultBaseUrl = String.fromEnvironment(
    'YAMYAM_API_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const Duration _requestTimeout = Duration(seconds: 90);

  final FirebaseAuth _firebaseAuth;
  final String _baseUrl;

  Future<String> issueDevStamp({
    required String placeId,
    int rating = 5,
    String? oneLineNote,
  }) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw const StampApprovalException('로그인 후 스탬프를 발행해 주세요.');
    }

    final idToken = await currentUser.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const StampApprovalException('로그인 정보를 확인하지 못했습니다.');
    }

    final queryParameters = <String, String>{
      'placeId': placeId,
      'rating': rating.toString(),
      if (oneLineNote?.trim().isNotEmpty == true)
        'oneLineNote': oneLineNote!.trim(),
    };
    final uri = Uri.parse(
      '$_baseUrl/dev/stamps/issue',
    ).replace(queryParameters: queryParameters);
    final httpClient = HttpClient();

    try {
      final request = await httpClient.postUrl(uri).timeout(_requestTimeout);
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $idToken',
      );

      final response = await request.close().timeout(_requestTimeout);
      final responseBody = await utf8.decoder.bind(response).join();
      final responseData = _decodeJson(responseBody);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StampApprovalException(_readErrorMessage(responseData));
      }

      final stampId = responseData['stampId']?.toString().trim() ?? '';
      if (stampId.isEmpty) {
        throw const StampApprovalException('발행된 스탬프 ID를 확인하지 못했습니다.');
      }
      return stampId;
    } on StampApprovalException {
      rethrow;
    } on SocketException {
      throw const StampApprovalException(
        '스탬프 인증 서버에 연결할 수 없습니다. FastAPI 서버를 확인해 주세요.',
      );
    } on TimeoutException {
      throw const StampApprovalException('스탬프 발행 요청 시간이 초과되었습니다.');
    } on HandshakeException {
      throw const StampApprovalException('스탬프 인증 서버 보안 연결에 실패했습니다.');
    } catch (_) {
      throw const StampApprovalException('개발용 스탬프를 발행하지 못했습니다.');
    } finally {
      httpClient.close(force: true);
    }
  }

  Future<int> issueStamp({
    required StampVerificationRequest verificationRequest,
    required ReceiptOcrValidationResult ocrResult,
    required double userLat,
    required double userLng,
    bool isRooted = false,
    bool isMockLocation = false,
    bool devSkipGps = false,
    String? roadId,
  }) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw const StampApprovalException('로그인 후 스탬프를 인증해 주세요.');
    }

    final purchasedAt = ocrResult.purchasedAt;
    final ocrStoreName = ocrResult.storeName?.trim() ?? '';
    if (purchasedAt == null || ocrStoreName.isEmpty) {
      throw const StampApprovalException('영수증 OCR 결과가 올바르지 않습니다.');
    }

    final receiptFile = File(verificationRequest.receiptImagePath);
    if (!await receiptFile.exists()) {
      throw const StampApprovalException('촬영한 영수증 이미지를 찾지 못했습니다.');
    }

    final idToken = await currentUser.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw const StampApprovalException('로그인 정보를 확인하지 못했습니다.');
    }

    final boundary =
        '----yamyam-stamp-${DateTime.now().microsecondsSinceEpoch}';
    final httpClient = HttpClient();

    try {
      final httpRequest = await httpClient
          .postUrl(Uri.parse('$_baseUrl/stamp-verifications'))
          .timeout(_requestTimeout);
      httpRequest.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $idToken',
      );
      httpRequest.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/form-data; boundary=$boundary',
      );

      _writeField(
        httpRequest,
        boundary: boundary,
        name: 'placeId',
        value: verificationRequest.placeId,
      );
      _writeField(
        httpRequest,
        boundary: boundary,
        name: 'ocrStoreName',
        value: ocrStoreName,
      );
      _writeField(
        httpRequest,
        boundary: boundary,
        name: 'ocrPurchasedAt',
        value: purchasedAt.toIso8601String(),
      );
      if (ocrResult.amount != null) {
        _writeField(
          httpRequest,
          boundary: boundary,
          name: 'ocrAmount',
          value: ocrResult.amount.toString(),
        );
      }
      if (ocrResult.transactionId?.isNotEmpty == true) {
        _writeField(
          httpRequest,
          boundary: boundary,
          name: 'ocrTransactionId',
          value: ocrResult.transactionId!,
        );
      }
      _writeField(
        httpRequest,
        boundary: boundary,
        name: 'userLat',
        value: userLat.toString(),
      );
      _writeField(
        httpRequest,
        boundary: boundary,
        name: 'userLng',
        value: userLng.toString(),
      );
      _writeField(
        httpRequest,
        boundary: boundary,
        name: 'rating',
        value: verificationRequest.rating.toString(),
      );
      if (verificationRequest.note?.isNotEmpty == true) {
        _writeField(
          httpRequest,
          boundary: boundary,
          name: 'oneLineNote',
          value: verificationRequest.note!,
        );
      }
      if (roadId?.isNotEmpty == true) {
        _writeField(
          httpRequest,
          boundary: boundary,
          name: 'roadId',
          value: roadId!,
        );
      }
      _writeField(
        httpRequest,
        boundary: boundary,
        name: 'isRooted',
        value: isRooted.toString(),
      );
      _writeField(
        httpRequest,
        boundary: boundary,
        name: 'isMockLocation',
        value: isMockLocation.toString(),
      );
      _writeField(
        httpRequest,
        boundary: boundary,
        name: 'devSkipGps',
        value: devSkipGps.toString(),
      );

      await _writeFile(httpRequest, boundary: boundary, file: receiptFile);
      httpRequest.add(utf8.encode('\r\n--$boundary--\r\n'));

      final response = await httpRequest.close().timeout(_requestTimeout);
      final responseBody = await utf8.decoder.bind(response).join();
      final responseData = _decodeJson(responseBody);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StampApprovalException(_readErrorMessage(responseData));
      }

      final awardedPoints = responseData['awardedPoints'];
      return awardedPoints is num ? awardedPoints.toInt() : 0;
    } on StampApprovalException {
      rethrow;
    } on SocketException {
      throw const StampApprovalException(
        '스탬프 인증 서버에 연결할 수 없습니다. FastAPI 서버를 확인해 주세요.',
      );
    } on TimeoutException {
      throw const StampApprovalException('스탬프 인증 요청 시간이 초과되었습니다.');
    } on HandshakeException {
      throw const StampApprovalException('스탬프 인증 서버 보안 연결에 실패했습니다.');
    } catch (_) {
      throw const StampApprovalException('스탬프 인증 요청을 처리하지 못했습니다.');
    } finally {
      httpClient.close(force: true);
    }
  }

  void _writeField(
    HttpClientRequest request, {
    required String boundary,
    required String name,
    required String value,
  }) {
    request.add(
      utf8.encode(
        '--$boundary\r\n'
        'Content-Disposition: form-data; name="$name"\r\n\r\n'
        '$value\r\n',
      ),
    );
  }

  Future<void> _writeFile(
    HttpClientRequest request, {
    required String boundary,
    required File file,
  }) async {
    final filename = file.uri.pathSegments.last.replaceAll('"', '');
    final contentType = _contentTypeFor(filename);
    request.add(
      utf8.encode(
        '--$boundary\r\n'
        'Content-Disposition: form-data; name="receiptImage"; '
        'filename="$filename"\r\n'
        'Content-Type: $contentType\r\n\r\n',
      ),
    );
    await request.addStream(file.openRead());
  }

  Map<String, dynamic> _decodeJson(String body) {
    if (body.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } on FormatException {
      return const {};
    }
  }

  String _readErrorMessage(Map<String, dynamic> responseData) {
    final detail = responseData['detail'];
    if (detail is Map) {
      final message = detail['message']?.toString().trim();
      if (message?.isNotEmpty == true) return message!;
    }
    if (detail is String && detail.trim().isNotEmpty) return detail;
    return '스탬프 인증이 거부되었습니다.';
  }

  String _contentTypeFor(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  static String _normalizeBaseUrl(String baseUrl) {
    final trimmed = baseUrl.trim();
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }
}
