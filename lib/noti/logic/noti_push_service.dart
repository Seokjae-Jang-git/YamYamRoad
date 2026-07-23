import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/noti_push_message.dart';

class NotiPushService {
  NotiPushService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  Stream<NotiPushMessage> get foregroundMessages {
    return FirebaseMessaging.onMessage.map(NotiPushMessage.fromRemoteMessage);
  }

  Stream<NotiPushMessage> get openedMessages {
    return FirebaseMessaging.onMessageOpenedApp.map(
      NotiPushMessage.fromRemoteMessage,
    );
  }

  Future<NotiPushMessage?> getInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : NotiPushMessage.fromRemoteMessage(message);
  }
}
