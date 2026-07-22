import 'package:geolocator/geolocator.dart';

class LocationService {
  /// 사용자의 현재 GPS 위치(위도, 경도)를 가져옵니다.
  /// 권한이 없거나 GPS가 꺼져있을 경우 null을 반환합니다.
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. 기기의 GPS 서비스가 켜져 있는지 확인
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    // 2. 현재 앱의 위치 권한 상태 확인
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // 권한이 없으면 사용자에게 권한 요청 팝업 띄우기
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    // 3. 권한이 영구적으로 거부된 경우
    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    // 4. 현재 위치 측정 (10초 타임아웃 방어 로직 포함)
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      return null;
    }
  }
}