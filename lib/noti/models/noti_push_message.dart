import 'package:firebase_messaging/firebase_messaging.dart';

class NotiPushMessage {
  const NotiPushMessage({
    required this.notificationId,
    required this.type,
    required this.title,
    required this.body,
    this.refType,
    this.refId,
  });

  final String notificationId;
  final String type;
  final String title;
  final String body;
  final String? refType;
  final String? refId;

  factory NotiPushMessage.fromRemoteMessage(RemoteMessage message) {
    final data = message.data;
    return NotiPushMessage(
      notificationId: data['notificationId'] ?? message.messageId ?? '',
      type: data['type'] ?? 'unknown',
      title: message.notification?.title ?? data['title'] ?? '',
      body: message.notification?.body ?? data['body'] ?? '',
      refType: _nullableValue(data['refType']),
      refId: _nullableValue(data['refId']),
    );
  }
}

String? _nullableValue(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
