import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotiDeviceService {
  NotiDeviceService({
    FirebaseFirestore? firestore,
    FirebaseMessaging? messaging,
    this.usersCollection = 'users',
    this.deviceCollection = 'users_device',
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;
  final String usersCollection;
  final String deviceCollection;

  StreamSubscription<String>? _tokenRefreshSubscription;

  Future<NotificationSettings> requestPermission() {
    return _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<String?> registerCurrentDevice(String userId) async {
    final normalizedUserId = _normalizeUserId(userId);
    final token = await _messaging.getToken();
    if (token == null || token.trim().isEmpty) return null;

    await _saveToken(normalizedUserId, token.trim());
    return token;
  }

  Future<void> startTokenRefreshListener(String userId) async {
    final normalizedUserId = _normalizeUserId(userId);
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(
      (token) => _saveToken(normalizedUserId, token),
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('FCM 토큰 갱신 실패: $error');
      },
    );
  }

  Future<void> unregisterCurrentDevice(String userId) async {
    final normalizedUserId = _normalizeUserId(userId);
    final token = await _messaging.getToken();
    if (token != null && token.trim().isNotEmpty) {
      await _deviceDocument(normalizedUserId, token.trim()).delete();
    }
    await _messaging.deleteToken();
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }

  Future<void> _saveToken(String userId, String token) {
    return _deviceDocument(userId, token).set({
      'fcmToken': token,
      'platform': defaultTargetPlatform.name,
      'lastActiveAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  DocumentReference<Map<String, dynamic>> _deviceDocument(
    String userId,
    String token,
  ) {
    return _firestore
        .collection(usersCollection)
        .doc(userId)
        .collection(deviceCollection)
        .doc(Uri.encodeComponent(token));
  }

  String _normalizeUserId(String userId) {
    final normalized = userId.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(userId, 'userId', '사용자 ID가 비어 있습니다.');
    }
    return normalized;
  }
}
