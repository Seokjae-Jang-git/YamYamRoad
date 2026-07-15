import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MapLauncher {
  // 1. 네이버 지도 앱 길안내 실행 (원시 타입 매개변수로 완벽 고립)
  static Future<void> launchNaverMap({
    required double latitude,
    required double longitude,
    required String name,
  }) async {
    final String schemeUrl =
        'nmap://route/walk?dlat=$latitude&dlon=$longitude&dname=${Uri.encodeComponent(name)}&appname=com.example.yamyam';

    final String webUrl =
        'https://m.map.naver.com/route/walk.nhn?dlat=$latitude&dlon=$longitude&dname=${Uri.encodeComponent(name)}';

    final Uri schemeUri = Uri.parse(schemeUrl);
    final Uri webUri = Uri.parse(webUrl);

    if (await canLaunchUrl(schemeUri)) {
      await launchUrl(schemeUri);
    } else {
      // 네이버 지도 앱이 깔려있지 않은 경우 -> 기본 웹 브라우저로 백업 실행
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    }
  }

  // 2. 카카오맵 앱 길안내 실행 (원시 타입 매개변수로 완벽 고립)
  static Future<void> launchKakaoMap({
    required double latitude,
    required double longitude,
    required String name,
  }) async {
    final String schemeUrl =
        'kakaomap://route?ep=$latitude,$longitude&by=FOOT';

    final String webUrl =
        'https://map.kakao.com/link/to/${Uri.encodeComponent(name)},$latitude,$longitude';

    final Uri schemeUri = Uri.parse(schemeUrl);
    final Uri webUri = Uri.parse(webUrl);

    if (await canLaunchUrl(schemeUri)) {
      await launchUrl(schemeUri);
    } else {
      // 카카오맵 앱이 깔려있지 않은 경우 -> 기본 웹 브라우저로 백업 실행
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    }
  }

  // 3. 포트폴리오용 고품격 길찾기 브랜드 선택 바텀 시트 (구조 분리 버전)
  static void showMapSelectionBottomSheet({
    required BuildContext context,
    required double latitude,
    required double longitude,
    required String name,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 드래그 핸들 데코레이션
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  '$name 길안내',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 0.5),

              // 네이버 지도 탭
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Text('N', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                title: const Text(
                  '네이버 지도로 길찾기',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  launchNaverMap(
                    latitude: latitude,
                    longitude: longitude,
                    name: name,
                  );
                },
              ),
              const Divider(height: 1, thickness: 0.5),

              // 카카오맵 탭
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: const Text('K', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                title: const Text(
                  '카카오맵으로 길찾기',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  launchKakaoMap(
                    latitude: latitude,
                    longitude: longitude,
                    name: name,
                  );
                },
              ),
              const Divider(height: 1, thickness: 0.5),

              // 취소 버튼
              ListTile(
                leading: const Icon(Icons.close, color: Colors.grey, size: 20),
                title: const Text(
                  '취소',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.grey),
                ),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }
}