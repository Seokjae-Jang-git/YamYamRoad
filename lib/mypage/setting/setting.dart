import 'package:flutter/material.dart';
import 'package:yamyam_road/mypage/setting/location_info.dart';
import 'package:yamyam_road/mypage/setting/privacy.dart';
import '../../common/bottom_circle_tab_bar.dart';
import 'agreement.dart';
import 'myinfo.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '설정',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black), // 뒤로가기 화살표 색상
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 계정 섹션
              _buildSectionTitle('계정'),
              _buildListItem(context, '내 정보 수정'),
              _buildListItem(context, '계정 삭제'),

              const SizedBox(height: 40), // 섹션 간 간격

              // 2. 기타 섹션
              _buildSectionTitle('기타'),
              _buildListItem(context, '이용약관'),
              _buildListItem(context, '개인정보 처리방침'),
              _buildListItem(context, '위치기반서비스 이용약관'),
            ],
          ),
        ),
      ),
      // 🌟 하단 네비게이션 바 유지
      bottomNavigationBar: BottomCircleTabBar(
        currentIndex: 4, // 마이페이지(설정) 영역이므로 4 유지
        onTap: (index) {
          if (index != 4) {
            // 다른 탭을 누르면 현재 쌓여있는 화면들(설정, 마이페이지)을 모두 닫고 홈으로 돌아갑니다.
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
      ),
    );
  }

  // 섹션 타이틀 (예: 계정, 기타) 렌더링 위젯
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  // 리스트 아이템 (예: 내 정보 수정 >) 렌더링 위젯
  Widget _buildListItem(BuildContext context, String title) {
    return InkWell(
      onTap: () {
        // 🌟 수정된 부분: title이 '이용약관'일 경우 화면 이동
        if (title == '내 정보 수정') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyInfoScreen()),
          );
        } else if (title == '이용약관') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AgreementScreen()),
          );
        } else if(title == '개인정보 처리방침') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PrivacyScreen()),
          );
        } else if(title == '위치기반서비스 이용약관') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LocationInfoScreen()),
          );
        } else {
          // 다른 메뉴는 기존처럼 스낵바 띄우기
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title 페이지 준비중'), duration: const Duration(seconds: 1)),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 15)),
            const Icon(Icons.chevron_right, color: Colors.black87),
          ],
        ),
      ),
    );
  }
}