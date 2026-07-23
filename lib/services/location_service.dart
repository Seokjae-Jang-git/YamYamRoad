import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 1. Firestore에서 현재 사용자의 lastLocation(위도/경도)을 조회합니다.
  static Future<Position?> getLastLocationFromFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null || data['lastLocation'] == null) return null;

      final lastLoc = data['lastLocation'];

      // Firestore GeoPoint 타입인 경우
      if (lastLoc is GeoPoint) {
        return Position(
          longitude: lastLoc.longitude,
          latitude: lastLoc.latitude,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
      }

      // Map 형태인 경우 방어 코드 ({'latitude': double, 'longitude': double})
      if (lastLoc is Map) {
        final lat = (lastLoc['latitude'] as num?)?.toDouble();
        final lng = (lastLoc['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          return Position(
            longitude: lng,
            latitude: lat,
            timestamp: DateTime.now(),
            accuracy: 0.0,
            altitude: 0.0,
            altitudeAccuracy: 0.0,
            heading: 0.0,
            headingAccuracy: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
          );
        }
      }

      return null;
    } catch (e) {
      print('❌ [LocationService] Firestore lastLocation 조회 실패: $e');
      return null;
    }
  }

  /// 2. 사용자의 현재 GPS 위치(위도, 경도)를 실제 센서로 가져옵니다.
  /// 권한이 없거나 GPS가 꺼져있을 경우 null을 반환합니다.
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1) 기기의 GPS 서비스가 켜져 있는지 확인
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    // 2) 현재 앱의 위치 권한 상태 확인
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // 권한이 없으면 사용자에게 권한 요청 팝업 띄우기
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    // 3) 권한이 영구적으로 거부된 경우
    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    // 4) 현재 위치 측정 (10초 타임아웃 방어 로직 포함)
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      print('❌ [LocationService] GPS 위치 수신 실패: $e');
      return null;
    }
  }

  /// 3. Firestore users/{uid} 문서의 lastLocation 필드를 GeoPoint 형태로 업데이트합니다.
  static Future<void> updateLastLocationToFirestore(Position position) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).set({
        'lastLocation': GeoPoint(position.latitude, position.longitude),
      }, SetOptions(merge: true));

      print('💾 [LocationService] Firestore lastLocation 저장 완료: (${position.latitude}, ${position.longitude})');
    } catch (e) {
      print('❌ [LocationService] Firestore lastLocation 저장 실패: $e');
    }
  }
}