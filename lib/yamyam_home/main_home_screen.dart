import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/bottom_circle_tab_bar.dart';
import '../community/community_detail.dart';
import '../community/community_main.dart';
import '../noti/models/noti_model.dart';
import '../noti/models/noti_reference.dart';
import '../noti/widgets/noti_session_listener.dart';
import '../mypage/badge/badge_main_screen.dart';
import '../mypage/stamp/stamp_main_screen.dart';
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

  // 🌟 커뮤니티 탭을 다시 눌렀을 때 최상단으로 스크롤시키기 위한 키
  final GlobalKey<CommunityMainScreenState> _communityKey =
  GlobalKey<CommunityMainScreenState>();

  // 🌟 얌얌로드 탭을 다시 눌렀을 때 최상단으로 스크롤시키기 위한 키
  final GlobalKey<RoadMainScreenState> _roadKey =
  GlobalKey<RoadMainScreenState>();

  // 브랜드 컬러 상수 정의
  static const Color creamyIvory = Color(0xFFFFFDF9);
  static const Color coralRed = Color(0xFFFF6B57);

  @override
  void initState() {
    super.initState();
    _checkWithdrawnStatus();
  }

  // 🌟 로그인 직후 탭과 무관하게 딱 한 번, 탈퇴(paused) 상태인지 확인합니다.
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
    debugPrint('🔎 [탈퇴체크] Firestore status=${data?['status']}, pausedAt=${data?['pausedAt']}');

    if (data != null && data['status'] == 'paused') {
      final ts = data['pausedAt'] as Timestamp?;
      debugPrint('🔎 [탈퇴체크] paused 확인, 복구 다이얼로그 호출 시도. mounted=$mounted');
      if (!mounted) return;

      final canProceed = await handleWithdrawnRecovery(
        context: context,
        uid: uid,
        pausedAt: ts?.toDate(),
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

  // 🌟 하단 탭 탭 이벤트 처리
  //    - 활성화된 탭(커뮤니티: index 1, 얌얌로드: index 2)을 다시 누르면
  //      화면 전환 없이 리스트만 최상단으로 스크롤
  //    - 그 외에는 기존처럼 탭 전환
  void _handleTabTap(int index) {
    if (index == _currentTabIndex) {
      if (index == 1) {
        _communityKey.currentState?.scrollToTop();
        return;
      } else if (index == 2) {
        _roadKey.currentState?.scrollToTop();
        return;
      }
    }
    setState(() {
      _currentTabIndex = index;
    });
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
        return CommunityMainScreen(key: _communityKey);
      case 2:
        return RoadMainScreen(key: _roadKey);
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

  void _handleNotificationTap(NotiItem item) {
    final referenceType = item.referenceType;
    final referenceId = item.refId;
    if (referenceType == null || referenceId == null) return;

    switch (referenceType) {
      case NotiReferenceType.post:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CommunityDetailScreen(postId: referenceId),
          ),
        );
      case NotiReferenceType.stamp:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const StampMainScreen()),
        );
      case NotiReferenceType.badge:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BadgeMainScreen()),
        );
      case NotiReferenceType.pointTransaction:
      case NotiReferenceType.point:
        Navigator.of(context).pop();
        setState(() => _currentTabIndex = 3);
      case NotiReferenceType.purchase:
        return;
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

    return NotiSessionListener(
      userId: AuthService.currentUser!.uid,
      onNotificationTap: _handleNotificationTap,
      child: Scaffold(
        backgroundColor: creamyIvory,
        body: SafeArea(
          child: _buildBody(),
        ),
        bottomNavigationBar: BottomCircleTabBar(
          currentIndex: _currentTabIndex,
          onTap: _handleTabTap,
        ),
      ),
    );
  }
}