import 'package:safe_device/safe_device.dart';

import 'stamp_integrity_checker.dart';

typedef RiskyBackgroundAppDetector = Future<bool> Function();

/// 기기 루팅 여부는 safe_device로, 백그라운드 앱 위험 여부는 외부의
/// Play Integrity/서버 판정 함수로 확인한다.
///
/// [detectRiskyBackgroundApp]을 필수로 받아서 미구현 상태를 정상으로
/// 오인하지 않도록 한다. 콜백 오류는 [StampIntegrityChecker]에서
/// fail-closed 처리된다.
class SafeDeviceIntegrityProbe implements StampIntegrityProbe {
  final RiskyBackgroundAppDetector detectRiskyBackgroundApp;

  const SafeDeviceIntegrityProbe({required this.detectRiskyBackgroundApp});

  @override
  Future<bool> isDeviceRooted() => SafeDevice.isJailBroken;

  @override
  Future<bool> hasRiskyBackgroundApp() => detectRiskyBackgroundApp();
}
