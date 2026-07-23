import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

class UserLocationProvider extends ChangeNotifier {
  // course_detail_map.dart의 기본 임시 좌표와 동일하게 맞춘 기본 좌표 (서울시청)
  static final Position _defaultPosition = Position(
    latitude: 37.5666102,
    longitude: 126.9783881,
    timestamp: DateTime.now(),
    accuracy: 0.0,
    altitude: 0.0,
    altitudeAccuracy: 0.0,
    heading: 0.0,
    headingAccuracy: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
  );

  Position? _currentPosition;
  bool _isLoading = false;
  bool _isPermissionDenied = false;

  /// 현재 위치 반환 (수신된 위치가 없을 경우 기본 좌표 반환)
  Position get currentPosition => _currentPosition ?? _defaultPosition;
  bool get isLoading => _isLoading;
  bool get isPermissionDenied => _isPermissionDenied;

  /// 앱 최초 진입 시 실행되는 위치 초기화 메서드
  Future<void> initializeLocation() async {
    _isLoading = true;
    _isPermissionDenied = false;
    notifyListeners();

    try {
      // 1. DB (Firestore lastLocation) 우선 조회
      Position? savedPosition = await LocationService.getLastLocationFromFirestore();

      if (savedPosition != null) {
        print('⚡ [UserLocationProvider] Firestore lastLocation 데이터를 사용합니다.');
        _currentPosition = savedPosition;
      } else {
        // 2. DB에 위치가 없다면 GPS 최초 수신 시도
        print('📡 [UserLocationProvider] DB 위치가 없어 GPS 최초 수신을 시도합니다.');
        Position? freshPosition = await LocationService.getCurrentLocation();

        if (freshPosition != null) {
          _currentPosition = freshPosition;
          await LocationService.updateLastLocationToFirestore(freshPosition);
        } else {
          // GPS 수신 실패 또는 권한 거부 시 기본 좌표 사용
          print('⚠️ [UserLocationProvider] GPS 수신 거부/실패 -> 기본 좌표(Fallback)를 사용합니다.');
          _isPermissionDenied = true;
          _currentPosition = _defaultPosition;
        }
      }
    } catch (e) {
      print('❌ [UserLocationProvider] 위치 초기화 중 오류 발생: $e');
      _currentPosition = _defaultPosition;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// [재설정] 버튼 클릭 시 실행되는 위치 재수신 및 권한 재요청 메서드
  Future<bool> refreshLocation() async {
    _isLoading = true;
    _isPermissionDenied = false;
    notifyListeners();

    try {
      // 1. 현재 권한 확인 및 거부 상태일 경우 재요청
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // 2. 권한이 영구적으로 거부된 경우 앱 설정 화면으로 안내
      if (permission == LocationPermission.deniedForever) {
        print('⚠️ [UserLocationProvider] 위치 권한이 영구 거부 상태입니다. 스마트폰 설정 화면으로 이동합니다.');
        await Geolocator.openAppSettings();
        _isLoading = false;
        _isPermissionDenied = true;
        notifyListeners();
        return false;
      }

      // 3. 권한 허용 확인 후 GPS 위치 수신
      Position? freshPosition = await LocationService.getCurrentLocation();

      if (freshPosition != null) {
        _currentPosition = freshPosition;
        await LocationService.updateLastLocationToFirestore(freshPosition);
        print('💾 [UserLocationProvider] 위치 재설정 및 DB 업데이트 완료!');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isPermissionDenied = true;
      }
    } catch (e) {
      print('❌ [UserLocationProvider] 위치 재설정 중 오류 발생: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}