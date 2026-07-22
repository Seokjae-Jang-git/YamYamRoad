import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MapLauncher {
  // 네이버 지도 실행 (네이버 지도 모바일 웹 주소 검색 화면)
  static Future<void> launchNaverMap({
    required double latitude,
    required double longitude,
    required String name,
    required String address, // 주소 파라미터 추가
  }) async {
    // 폐업/DB누락으로 인한 흰 화면 방지를 위해 '주소'를 검색어로 사용
    // 주소가 비어있을 경우에만 차선책으로 상호명 사용
    final String searchQuery = address.isNotEmpty ? address : name;
    final String encodedQuery = Uri.encodeComponent(searchQuery);

    // m.map.naver.com 검색 결과 목록 페이지
    final Uri webUri = Uri.parse(
      'https://m.map.naver.com/search2/search.naver?query=$encodedQuery',
    );

    try {
      await launchUrl(
        webUri,
        mode: LaunchMode.inAppBrowserView,
      );
    } catch (e) {
      debugPrint('네이버 지도 웹 URL 열기 실패: $e');
    }
  }
}