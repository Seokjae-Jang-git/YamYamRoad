import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

enum NotiCommunityEvent {
  postLike('post_like'),
  postScrap('post_scrap'),
  postComment('post_comment'),
  commentLike('comment_like');

  const NotiCommunityEvent(this.value);

  final String value;
}

class NotiCommunityApiClient {
  NotiCommunityApiClient({
    FirebaseAuth? firebaseAuth,
    String baseUrl = defaultBaseUrl,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _baseUrl = _normalizeBaseUrl(baseUrl);

  static const String defaultBaseUrl = String.fromEnvironment(
    'YAMYAM_API_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
  static const Duration _requestTimeout = Duration(seconds: 5);

  final FirebaseAuth _firebaseAuth;
  final String _baseUrl;

  Future<void> send({
    required NotiCommunityEvent event,
    required String postId,
    String? commentId,
  }) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw StateError('로그인 정보가 없습니다.');
    }
    final idToken = await currentUser.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw StateError('로그인 인증 정보를 가져오지 못했습니다.');
    }

    final client = HttpClient();
    try {
      final request = await client
          .postUrl(Uri.parse('$_baseUrl/notifications/community'))
          .timeout(_requestTimeout);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
      request.headers.contentType = ContentType.json;
      final payload = <String, String>{
        'eventType': event.value,
        'postId': postId,
      };
      if (commentId != null) payload['commentId'] = commentId;
      request.write(jsonEncode(payload));

      final response = await request.close().timeout(_requestTimeout);
      await response.drain<void>().timeout(_requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('커뮤니티 알림 요청 실패: ${response.statusCode}');
      }
    } finally {
      client.close(force: true);
    }
  }

  static String _normalizeBaseUrl(String baseUrl) {
    final normalized = baseUrl.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(baseUrl, 'baseUrl', 'API 주소가 비어 있습니다.');
    }
    return normalized.endsWith('/')
        ? normalized.substring(0, normalized.length - 1)
        : normalized;
  }
}
