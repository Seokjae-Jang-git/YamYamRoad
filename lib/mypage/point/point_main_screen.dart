import 'package:flutter/material.dart';
// 각 탭 화면 파일 import
import 'emoticon/emoticon_tab.dart';
import 'giftcon/gifticon_tab.dart';
import 'point_history/point_history_tab.dart';

class PointMainScreen extends StatelessWidget {
  const PointMainScreen({Key? key}) : super(key: key);

  // 🌟 얌얌로드 공식 컬러 팔레트
  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color creamyIvory = Color(0xFFFFFDF9);
  static const Color subTextColor = Color(0xFF7A6B63);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // 탭 개수
      child: Scaffold(
        backgroundColor: creamyIvory, // 🌟 전체 배경색 적용
        appBar: AppBar(
          backgroundColor: creamyIvory,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: deepChocolate, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            '포인트',
            style: TextStyle(
              color: deepChocolate,
              fontSize: 22, // 🌟 다른 메인 화면들과 폰트 크기 통일
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false, // 🌟 다른 페이지들과 동일하게 좌측 정렬
          bottom: TabBar(
            labelColor: pointCoralRed, // 🌟 활성화된 탭 글자색
            unselectedLabelColor: subTextColor, // 🌟 비활성화된 탭 글자색
            indicatorColor: pointCoralRed, // 🌟 활성화 인디케이터 색상
            indicatorWeight: 3.0,
            indicatorSize: TabBarIndicatorSize.tab, // 탭 전체 너비만큼 인디케이터 표시
            dividerColor: deepChocolate.withOpacity(0.12), // 🌟 탭바 하단 연한 가로선
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            tabs: const [
              Tab(text: '포인트'),
              Tab(text: '이모티콘'),
              Tab(text: '기프티콘'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // 1. 포인트 내역 조회 탭
            PointHistoryTab(),

            // 2. 이모티콘 탭
            EmoticonTab(),

            // 3. 기프티콘 탭
            GifticonTab()
          ],
        ),
      ),
    );
  }
}