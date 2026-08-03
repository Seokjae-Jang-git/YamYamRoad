import 'package:flutter/material.dart';
import '../../common/user_data.dart';
import '../../community/community_detail.dart';
import '../../mypage/badge/badge_main_screen.dart';
import '../../mypage/stamp/stamp_main_screen.dart';
import '../../noti/models/noti_model.dart';
import '../../noti/models/noti_reference.dart';
import '../../noti/widgets/noti_list_screen.dart';
import '../../noti/widgets/noti_unread_badge.dart';
import '../../services/auth_service.dart';

/// 홈 화면 최상단 헤더 (로고, 알림 버튼, 프로필 아바타 및 계정 메뉴)
class HomeHeader extends StatefulWidget {
  final ValueChanged<int> onTabChanged;

  const HomeHeader({
    super.key,
    required this.onTabChanged,
  });

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  // 브랜드 컬러 상수 정의
  static const Color coralRed = Color(0xFFFF6B57);
  static const Color strawberryPink = Color(0xFFFFA09B);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color creamyIvory = Color(0xFFFFFDF9);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // AuthService를 통해 프로필 로드 후 화면 갱신
  Future<void> _loadProfile() async {
    await AuthService.loadUserProfileToUserData();
    if (mounted) {
      setState(() {});
    }
  }

  // 프로필 아이콘 탭 시 "마이페이지" / "로그아웃" 팝업 메뉴 표시
  void _showProfileMenu(BuildContext context, TapDownDetails details) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(details.globalPosition, details.globalPosition),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      color: creamyIvory,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE8E2D9), width: 1),
      ),
      items: [
        const PopupMenuItem<String>(
          value: 'mypage',
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 18, color: deepChocolate),
              SizedBox(width: 10),
              Text(
                '마이페이지',
                style: TextStyle(
                  color: deepChocolate,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18, color: coralRed),
              SizedBox(width: 10),
              Text(
                '로그아웃',
                style: TextStyle(
                  color: coralRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((selected) {
      if (selected == 'mypage') {
        widget.onTabChanged(4);
      } else if (selected == 'logout') {
        _confirmLogout(context);
      }
    });
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: creamyIvory,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '로그아웃',
          style: TextStyle(
            color: deepChocolate,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          '정말 로그아웃하시겠습니까?',
          style: TextStyle(color: deepChocolate),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              '취소',
              style: TextStyle(color: deepChocolate),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _handleLogout();
            },
            child: const Text(
              '로그아웃',
              style: TextStyle(
                color: coralRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      await AuthService.logout();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그아웃 중 오류가 발생했습니다: $e')),
      );
    }
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotiListScreen(
          userId: AuthService.currentUser!.uid,
          onNotificationTap: _handleNotificationTap,
        ),
      ),
    );
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
        widget.onTabChanged(3);
      case NotiReferenceType.purchase:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 브랜드 로고 및 앱 타이틀
          Row(
            children: [
              Image.asset(
                'assets/temp_images/yamyam_logo.png',
                height: 36,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Text(
                    '🍒',
                    style: TextStyle(fontSize: 22),
                  );
                },
              ),
              const SizedBox(width: 8),
              const Text(
                'YamYam Road',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: deepChocolate,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          // 우측 상단 버튼 영역 (알림 종 아이콘, 프로필 아바타)
          Row(
            children: [
              // 디자인 고도화된 원형 알림 버튼 (38x38 규격)
              NotiUnreadBadgeStream(
                userId: AuthService.currentUser!.uid,
                offset: const Offset(2, -2),
                child: _NotificationIconButton(
                  onTap: _openNotifications,
                ),
              ),
              const SizedBox(width: 10),
              // 프로필 메뉴 버튼
              GestureDetector(
                onTapDown: (details) => _showProfileMenu(context, details),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE8E2D9), width: 1),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: strawberryPink,
                    child: UserData.isDefaultProfileImage || UserData.profileImagePath == null
                        ? const Icon(Icons.person_outline, size: 22, color: deepChocolate)
                        : ClipOval(
                      child: Image.network(
                        UserData.profileImagePath!,
                        width: 38,
                        height: 38,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.person_outline, size: 22, color: deepChocolate);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 고도화된 상단 원형 알림 버튼 위젯
class _NotificationIconButton extends StatelessWidget {
  final VoidCallback onTap;

  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color creamyIvory = Color(0xFFFFFDF9);

  const _NotificationIconButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: creamyIvory, // 따뜻한 크림 아이보리 배경
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE8E2D9), width: 1),
        ),
        child: const Icon(
          Icons.notifications_none_rounded,
          size: 20,
          color: deepChocolate,
        ),
      ),
    );
  }
}
