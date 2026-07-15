import 'package:flutter/material.dart';
import '../common/bottom_circle_tab_bar.dart';
import '../road/road_main_screen.dart';
import '../mypage/mypage_main.dart'; // 🆕 바텀바가 버린 마이페이지 라우팅 책임을 부모가 인수 완료!
import 'widgets/home_content_view.dart'; // 🆕 홈 화면의 순수 UI 콘텐츠 격리 뷰 임포트

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentTabIndex = 0;

  // 🆕 탭 인덱스에 따라 분리된 도메인 위젯만을 반환하여 강한 응집력을 확보합니다.
  Widget _buildBody() {
    switch (_currentTabIndex) {
      case 0:
        return const HomeContentView(); // 0번: 격리 완료한 순수 홈 뷰
      case 1:
        return const Center(
          child: Text(
            '얌얌북 화면 준비 중',
            style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        );
      case 2:
        return const RoadMainScreen(); // 2번: 얌얌로드 메인 뷰
      case 3:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.payment, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                '포인트 내역',
                style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '화면 준비중',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        );
      default:
        return const HomeContentView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _buildBody(),
      ),
      bottomNavigationBar: BottomCircleTabBar(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          // 🆕 마이페이지(4번 탭) 요청 시 탭 인덱스를 바꾸지 않고 상단 스택에 오버레이
          if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MyPageMainScreen(),
              ),
            );
          } else {
            // 그 외 일반 탭은 인덱스 전환 상태 반영
            setState(() {
              _currentTabIndex = index;
            });
          }
        },
      ),
    );
  }
}