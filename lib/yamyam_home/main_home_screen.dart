import 'package:flutter/material.dart';
import '../common/bottom_circle_tab_bar.dart';
import '../road/road_main_screen.dart';
import '../mypage/mypage_main.dart'; // 🆕 바텀바가 버린 마이페이지 라우팅 책임을 부모가 인수 완료!
import 'widgets/home_content_view.dart'; // 🆕 홈 화면의 순수 UI 콘텐츠 격리 뷰 임포트
import '../point/point_main_screen.dart';
import '../services/auth_service.dart';


class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentTabIndex = 0;

  Widget _buildBody() {
    switch (_currentTabIndex) {
      case 0:
        return HomeContentView(
          onTabChanged: (index) {
            setState(() {
              _currentTabIndex = index; // 신호를 받으면 메인 탭 번호를 변경하여 새로고침합니다.
            });
          },
        );
      case 1:
        return const Center(
          child: Text('얌얌북 화면 준비 중', style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
        );
      case 2:
        return const RoadMainScreen();
      case 3:
        return PointMainScreen(
          userId: AuthService.currentUser?.uid ?? 'test_user_01',
        );
    // 🌟 여기에 case 4를 추가해서 마이페이지를 끼워 넣습니다!
      case 4:
        return const MyPageMainScreen();
      default:
        return HomeContentView(
          onTabChanged: (index) {
            setState(() {
              _currentTabIndex = index;
            });
          },
        );
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
          // 🌟 마이페이지용 특수 처리(Navigator.push)를 싹 지우고,
          // 모든 탭이 평등하게 인덱스만 바꾸도록 통일합니다!
          setState(() {
            _currentTabIndex = index;
          });
        },
      ),
    );
  }
}