import 'package:flutter/foundation.dart';
import '../services/location_service.dart';

class UserLocationProvider with ChangeNotifier {
  double? _userLat;
  double? _userLng;
  String _currentAddress = '위치 정보를 가져오는 중...';
  bool _isLoading = false;

  // Getter
  double get userLat => _userLat ?? LocationService.defaultLat;
  double get userLng => _userLng ?? LocationService.defaultLng;
  String get currentAddress => _currentAddress;
  bool get isLoading => _isLoading;
  bool get hasLocation => _userLat != null && _userLng != null;

  /// 앱 시작 시 위치 초기화 (3단계 Fallback 메커니즘 적용)
  Future<void> initializeLocation() async {
    if (_userLat != null && _userLng != null) return;
    await refreshLocation();
  }

  /// 위치 정보 수동/자동 새로고침
  Future<void> refreshLocation() async {
    _isLoading = true;
    notifyListeners();

    try {
      // LocationService의 3단계 Fallback 적용 메서드 호출
      final result = await LocationService.getCurrentLocationWithFallback();

      _userLat = result.latitude;
      _userLng = result.longitude;
      _currentAddress = result.address;
    } catch (e) {
      debugPrint('❌ [UserLocationProvider] 위치 수신 최종 실패: $e');
      _userLat = LocationService.defaultLat;
      _userLng = LocationService.defaultLng;
      _currentAddress = LocationService.defaultAddress;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 좌표를 기반으로 주소 텍스트만 업데이트
  Future<void> updateAddressFromCoordinates(double lat, double lng) async {
    _userLat = lat;
    _userLng = lng;
    notifyListeners();

    try {
      final address = await LocationService.getAddressFromCoordinates(lat, lng);
      _currentAddress = address;
    } catch (e) {
      debugPrint('❌ [UserLocationProvider] 주소 변환 실패: $e');
      _currentAddress = '위치 정보 수신 완료';
    } finally {
      notifyListeners();
    }
  }
}