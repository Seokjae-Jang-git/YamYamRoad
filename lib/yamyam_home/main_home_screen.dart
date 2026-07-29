import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/bottom_circle_tab_bar.dart';
import '../community/community_main.dart';
import '../road/road_main_screen.dart';
import '../mypage/mypage_main.dart';
import 'widgets/home_content_view.dart';
import '../point/point_main_screen.dart';
import '../services/auth_service.dart';
import '../login/withdrawal_recovery.dart';
import '../login/login_screen.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentTabIndex = 0;
  bool _checkingWithdrawal = true;

  // 브랜드 컬러 상수 정의
  static const Color creamyIvory = Color(0xFFFFFDF9);
  static const Color coralRed = Color(0xFFFF6B57);

  @override
  void initState() {
    super.initState();
    _checkWithdrawnStatus();
  }

  // 🌟 로그인 직후 탭과 무관하게 딱 한 번, 탈퇴 상태인지 확인합니다.
  Future<void> _checkWithdrawnStatus() async {
    debugPrint('🔎 [탈퇴체크] 시작');
    final uid = AuthService.currentUser?.uid;
    debugPrint('🔎 [탈퇴체크] uid=$uid');
    if (uid == null) {
      if (mounted) setState(() => _checkingWithdrawal = false);
      return;
    }

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    debugPrint('🔎 [탈퇴체크] Firestore status=${data?['status']}, withdrawnAt=${data?['withdrawnAt']}');

    if (data != null && data['status'] == 'withdrawn') {
      final ts = data['withdrawnAt'] as Timestamp?;
      debugPrint('🔎 [탈퇴체크] withdrawn 확인, 복구 다이얼로그 호출 시도. mounted=$mounted');
      if (!mounted) return;

      final canProceed = await handleWithdrawnRecovery(
        context: context,
        uid: uid,
        withdrawnAt: ts?.toDate(),
      );
      debugPrint('🔎 [탈퇴체크] 다이얼로그 결과 canProceed=$canProceed');

      if (!canProceed) {
        debugPrint('🔎 [탈퇴체크] 로그아웃 처리 시작');
        await AuthService.logout();
        debugPrint('🔎 [탈퇴체크] 로그아웃 완료. mounted=$mounted');
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
        return;
      }
    }

    debugPrint('🔎 [탈퇴체크] 최종 완료, 홈 화면 표시. mounted=$mounted');
    if (!mounted) return;
    setState(() => _checkingWithdrawal = false);
  }

  Widget _buildBody() {
    switch (_currentTabIndex) {
      case 0:
        return HomeContentView(
          onTabChanged: (index) {
            setState(() {
              _currentTabIndex = index;
            });
          },
        );
      case 1:
        return const CommunityMainScreen();
      case 2:
        return const RoadMainScreen();
      case 3:
        return PointMainScreen(
          userId: AuthService.currentUser?.uid ?? 'test_user_01',
        );
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
    // 🌟 탈퇴 체크가 끝나기 전까지는 로딩 화면만 보여줍니다. (Creamy Ivory 배경 & Coral Red 로딩)
    if (_checkingWithdrawal) {
      return const Scaffold(
        backgroundColor: creamyIvory,
        body: Center(
          child: CircularProgressIndicator(color: coralRed),
        ),
      );
    }

    return Scaffold(
      backgroundColor: creamyIvory,
      body: SafeArea(
        child: _buildBody(),
      ),
      bottomNavigationBar: BottomCircleTabBar(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
      ),
    );
  }
}