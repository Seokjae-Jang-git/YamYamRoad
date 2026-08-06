import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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

  /// 앱 시작 또는 화면 진입 시 위치 초기화
  Future<void> initializeLocation({BuildContext? context}) async {
    if (_userLat != null && _userLng != null && !_isLoading) return;
    await refreshLocation(context: context, forceRefresh: true);
  }

  /// 위치 정보 수동/자동 새로고침 (BuildContext 전달 시 팝업 안내)
  Future<void> refreshLocation({
    BuildContext? context,
    bool forceRefresh = false,
  }) async {
    if (_isLoading && !forceRefresh) return;

    _isLoading = true;
    _currentAddress = '위치 정보를 가져오는 중...';
    notifyListeners();

    try {
      // 1️⃣ 기기 GPS(위치 서비스) 활성화 검사
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (context != null && context.mounted) {
          debugPrint('⚠️ [UserLocationProvider] 사용자에 의한 새로고침: GPS 꺼짐 안내 팝업 출력을 시도합니다.');

          // 🎨 YamYam Road 브랜드 스타일 다이얼로그 출력
          final bool? shouldOpenSettings = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              backgroundColor: const Color(0xFFFFFDF9), // creamyIvory
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                side: const BorderSide(color: Color(0xFFE8E2D9), width: 1.0),
              ),
              title: const Row(
                children: [
                  Icon(Icons.location_off, color: Color(0xFFFF6B57)), // coralRed
                  SizedBox(width: 8),
                  Text(
                    '위치(GPS) 꺼짐',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A3225), // deepChocolate
                    ),
                  ),
                ],
              ),
              content: const Text(
                '📍 기기의 위치 서비스(GPS)가 꺼져 있습니다.\n현재 위치를 확인하려면 GPS를 켜주시겠습니까?',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4A3225),
                  height: 1.4,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text(
                    '취소',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B57),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text(
                    '설정으로 이동',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );

          // 사용자가 [설정으로 이동]을 눌렀을 때만 설정 화면으로 이동
          if (shouldOpenSettings == true) {
            await Geolocator.openLocationSettings();
          }
        } else {
          debugPrint('ℹ️ [UserLocationProvider] 앱 첫 진입(Silent Mode): GPS 꺼짐 상태이므로 설정창 이동 없이 Fallback 주소를 채웁니다.');
        }
      }

      // 2️⃣ 위치 권한 상태 확인 (앱 튕김 방지를 위해 권한 확인만 수행)
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied && context != null) {
        debugPrint('⚠️ [UserLocationProvider] 수동 요청 시 위치 권한 팝업을 호출합니다.');
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ [UserLocationProvider] 위치 권한이 영구 거부되어 있습니다.');
      }

      // 3️⃣ LocationService의 통합 위치 수신 (4단계 Fallback 메커니즘 실행)
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

  /// 수동 시스템 GPS 설정 화면 열기
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// 수동 시스템 앱 설정 화면 열기
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
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