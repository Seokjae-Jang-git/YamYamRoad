import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 위치 조회 결과를 담는 데이터 클래스
class LocationDataResult {
  final double latitude;
  final double longitude;
  final String address;

  LocationDataResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class LocationService {
  // 🏛️ 기본 좌표 (서울시청) - 4순위 최종 Fallback
  static const double defaultLat = 37.5665;
  static const double defaultLng = 126.9780;
  static const String defaultAddress = '서울특별시 중구 태평로1가 31';

  // 🐛 디버그/테스트 모드 전용 좌표 (서초구청)
  static const double debugLat = 37.4837;
  static const double debugLng = 127.0324;
  static const String debugAddress = '서울특별시 서초구 남부순환로 2584';

  // 🔘 런타임 개발자 가짜 위치 토글 상태 (기본값: false - 실제 위치 사용)
  static bool _useMockLocation = false;

  /// 현재 가짜 위치(Mock) 모드 활성화 여부 반환
  static bool get useMockLocation => _useMockLocation;

  /// 가짜 위치 모드 켜기/끄기 설정
  static void setMockLocation(bool enable) {
    _useMockLocation = enable;
    debugPrint('⚙️ [LocationService] 가짜 위치 모드 변경됨: $_useMockLocation');
  }

  /// Google Reverse Geocoding REST API를 호출하여 좌표를 주소 문자열로 변환
  static Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        debugPrint('⚠️ [LocationService] GOOGLE_MAPS_API_KEY가 .env 파일에 없거나 비어 있습니다.');
        return '서울특별시 중구 태평로1가';
      }

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&language=ko&key=$apiKey',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
          final formattedAddress = data['results'][0]['formatted_address'] as String;
          // "대한민국 서울특별시..." -> "서울특별시..." 형태로 국가명 접두사 정리
          return formattedAddress.replaceFirst('대한민국 ', '');
        }
      }
      debugPrint('⚠️ [LocationService] Reverse Geocoding API 응답 실패: ${response.body}');
    } catch (e) {
      debugPrint('❌ [LocationService] Reverse Geocoding 오류 발생: $e');
    }
    return '위치 정보 수신 완료';
  }

  /// 3순위: Firestore 사용자 문서에서 저장된 lastLocation 조회
  static Future<LocationDataResult?> getLastLocationFromFirestore() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;

      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('lastLocation') && data['lastLocation'] != null) {
          final lastLoc = data['lastLocation'] as Map<String, dynamic>;
          final lat = (lastLoc['latitude'] as num?)?.toDouble();
          final lng = (lastLoc['longitude'] as num?)?.toDouble();
          final address = lastLoc['address'] as String? ?? '이전 위치';

          if (lat != null && lng != null) {
            debugPrint('📍 [LocationService] Firestore에서 lastLocation 복원 성공: ($lat, $lng)');
            return LocationDataResult(latitude: lat, longitude: lng, address: address);
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [LocationService] Firestore lastLocation 읽기 실패: $e');
    }
    return null;
  }

  /// 최신 위치 성공 수신 시: Firestore에 위치 백업 저장
  static Future<void> saveLastLocationToFirestore(double lat, double lng, String address) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'lastLocation': {
          'latitude': lat,
          'longitude': lng,
          'address': address,
          'updatedAt': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));
      debugPrint('💾 [LocationService] Firestore에 최신 lastLocation 저장 완료');
    } catch (e) {
      debugPrint('❌ [LocationService] Firestore lastLocation 저장 실패: $e');
    }
  }

  /// 🌟 통합 위치 수신 (개발자 토글 + 권한 검사 + 4단계 Fallback 메커니즘)
  static Future<LocationDataResult> getCurrentLocationWithFallback() async {
    // 0️⃣ 개발자 토글 스위치가 켜진 경우: 서초구청 좌표 즉시 반환
    if (_useMockLocation) {
      debugPrint('🐛 [LocationService] 개발자 토글(Mock) 활성화: 서초구청 좌표를 반환합니다.');
      return LocationDataResult(
        latitude: debugLat,
        longitude: debugLng,
        address: debugAddress,
      );
    }

    // [1단계] 앱 위치 권한 확인 및 요청 (OS 최우선 요건)
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      debugPrint('📱 [LocationService] 위치 권한을 동적으로 요청합니다.');
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('⚠️ [LocationService] 위치 권한이 거부되었습니다. Fallback을 실행합니다.');
        return await _getFallbackLocation();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('⚠️ [LocationService] 위치 권한이 영구 거부되었습니다. Fallback을 실행합니다.');
      return await _getFallbackLocation();
    }

    // [2단계] 스마트폰 기기 GPS 서비스 활성화 여부 확인
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('⚠️ [LocationService] 기기 GPS가 꺼져 있습니다. 무한 대기하지 않고 즉시 Fallback을 실행합니다.');
      return await _getFallbackLocation();
    }

    // [1순위] 스마트폰 OS 캐시 데이터(LastKnownPosition) 수신
    try {
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        debugPrint('⚡ [LocationService] [1순위] OS 캐시 위치 수신 성공: (${lastPosition.latitude}, ${lastPosition.longitude})');
        final address = await getAddressFromCoordinates(lastPosition.latitude, lastPosition.longitude);
        await saveLastLocationToFirestore(lastPosition.latitude, lastPosition.longitude, address);
        return LocationDataResult(
          latitude: lastPosition.latitude,
          longitude: lastPosition.longitude,
          address: address,
        );
      }
    } catch (e) {
      debugPrint('⚠️ [LocationService] 1순위(OS 캐시) 조회 실패: $e');
    }

    // [2순위] 실시간 GPS 수신 시도 (Dart Native .timeout() 2초 강제 타임아웃 적용)
    try {
      debugPrint('📡 [LocationService] [2순위] 실시간 GPS 위치 수신 시도 중 (2초 제한)...');

      // forceLocationManager 제거 (안드로이드 OS 레벨의 자동 설정 튕김 방지)
      late final LocationSettings locationSettings;
      if (defaultTargetPlatform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
        );
      } else {
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.high,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      ).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          throw TimeoutException('GPS 응답 시간 2초 초과');
        },
      );

      final address = await getAddressFromCoordinates(position.latitude, position.longitude);
      await saveLastLocationToFirestore(position.latitude, position.longitude, address);

      return LocationDataResult(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      );
    } catch (e) {
      debugPrint('⏱️ [LocationService] 2순위(실시간 GPS) 수신 실패/타임아웃 ($e). Fallback 단계로 진입합니다.');
      return await _getFallbackLocation();
    }
  }

  /// Fallback 내부 처리: (3순위) DB lastLocation -> (4순위) 기본 서울시청
  static Future<LocationDataResult> _getFallbackLocation() async {
    // [3순위] Firestore DB의 lastLocation
    final lastLoc = await getLastLocationFromFirestore();
    if (lastLoc != null) {
      debugPrint('📦 [LocationService] [3순위] Firestore DB 이전 위치 복원 성공');
      return lastLoc;
    }

    // [4순위] 기본 좌표 (서울시청)
    debugPrint('🏛️ [LocationService] [4순위] 최종 안전망: 기본 위치(서울시청)를 사용합니다.');
    return LocationDataResult(
      latitude: defaultLat,
      longitude: defaultLng,
      address: defaultAddress,
    );
  }
}