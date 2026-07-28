import 'package:geolocator/geolocator.dart';

import 'stamp_receipt_verification_service.dart';

class StampLocationEvidence {
  final double latitude;
  final double longitude;
  final bool isMockLocation;

  const StampLocationEvidence({
    required this.latitude,
    required this.longitude,
    required this.isMockLocation,
  });
}

class StampLocationEvidenceCollector {
  const StampLocationEvidenceCollector();

  Future<StampLocationEvidence> collect() async {
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      throw const StampApprovalException('스탬프 인증을 위해 위치 서비스를 켜 주세요.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const StampApprovalException('스탬프 인증을 위해 위치 권한이 필요합니다.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const StampApprovalException('설정에서 위치 권한을 허용한 후 다시 시도해 주세요.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    return StampLocationEvidence(
      latitude: position.latitude,
      longitude: position.longitude,
      isMockLocation: position.isMocked,
    );
  }
}
