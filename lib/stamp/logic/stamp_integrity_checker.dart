import '../models/stamp_verification_models.dart';

abstract interface class StampIntegrityProbe {
  Future<bool> isDeviceRooted();

  Future<bool> hasRiskyBackgroundApp();
}

class StampIntegrityChecker {
  final StampIntegrityProbe probe;

  const StampIntegrityChecker({required this.probe});

  Future<StampEntryCheckResult> call() async {
    try {
      final isRooted = await probe.isDeviceRooted();
      if (isRooted) {
        return const StampEntryCheckResult.blocked(
          reason: StampEntryBlockReason.rootedDevice,
          message: '기기 보안 상태로 인해 스탬프 인증을 진행할 수 없습니다.',
        );
      }

      final hasRiskyApp = await probe.hasRiskyBackgroundApp();
      if (hasRiskyApp) {
        return const StampEntryCheckResult.blocked(
          reason: StampEntryBlockReason.riskyBackgroundApp,
          message: '인증을 방해할 수 있는 앱을 종료한 후 다시 시도해 주세요.',
        );
      }

      return const StampEntryCheckResult.allowed();
    } catch (_) {
      return const StampEntryCheckResult.blocked(
        reason: StampEntryBlockReason.integrityCheckFailed,
        message: '보안 상태를 확인하지 못했습니다. 잠시 후 다시 시도해 주세요.',
      );
    }
  }
}
