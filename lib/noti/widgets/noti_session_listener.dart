import 'dart:async';

import 'package:flutter/material.dart';

import '../logic/noti_device_service.dart';
import '../logic/noti_push_service.dart';
import '../models/noti_push_message.dart';
import 'noti_list_screen.dart';

class NotiSessionListener extends StatefulWidget {
  const NotiSessionListener({
    super.key,
    required this.userId,
    required this.onNotificationTap,
    required this.child,
  });

  final String userId;
  final NotiItemTapCallback onNotificationTap;
  final Widget child;

  @override
  State<NotiSessionListener> createState() => _NotiSessionListenerState();
}

class _NotiSessionListenerState extends State<NotiSessionListener> {
  final NotiDeviceService _deviceService = NotiDeviceService();
  final NotiPushService _pushService = NotiPushService();

  StreamSubscription<NotiPushMessage>? _openedSubscription;

  @override
  void initState() {
    super.initState();
    _openedSubscription = _pushService.openedMessages.listen(
      (_) => _openNotificationList(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    if (!mounted) return;
    try {
      await _deviceService.requestPermission();
      await _deviceService.registerCurrentDevice(widget.userId);
      await _deviceService.startTokenRefreshListener(widget.userId);
    } catch (error) {
      debugPrint('FCM 기기 등록 실패: $error');
    }

    try {
      final initialMessage = await _pushService.getInitialMessage();
      if (initialMessage != null && mounted) {
        _openNotificationList();
      }
    } catch (error) {
      debugPrint('초기 푸시 확인 실패: $error');
    }
  }

  void _openNotificationList() {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotiListScreen(
          userId: widget.userId,
          onNotificationTap: widget.onNotificationTap,
        ),
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_openedSubscription?.cancel());
    unawaited(_deviceService.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
