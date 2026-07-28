import 'package:safe_device/safe_device.dart';

import 'stamp_integrity_checker.dart';

/// 기기 루팅 및 위치 조작 여부를 safe_device로 확인한다.
/// 플러그인 오류는 [StampIntegrityChecker]에서 fail-closed 처리된다.
class SafeDeviceIntegrityProbe implements StampIntegrityProbe {
  const SafeDeviceIntegrityProbe();

  @override
  Future<bool> isDeviceRooted() => SafeDevice.isJailBroken;

  @override
  Future<bool> isMockLocation() => SafeDevice.isMockLocation;
}
