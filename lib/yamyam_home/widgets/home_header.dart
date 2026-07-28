import 'package:flutter/material.dart';
import '../../common/user_data.dart';
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
  // 새로운 알림 유무 상태 (기본값: true / 탭 시 해제 예시)
  bool _hasUnreadNotification = true;

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        const PopupMenuItem<String>(
          value: 'mypage',
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 18, color: Colors.black87),
              SizedBox(width: 10),
              Text('마이페이지'),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18, color: Colors.redAccent),
              SizedBox(width: 10),
              Text('로그아웃', style: TextStyle(color: Colors.redAccent)),
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
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _handleLogout();
            },
            child: const Text('로그아웃', style: TextStyle(color: Colors.red)),
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
                  color: Color(0xFF504D46),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          // 우측 상단 버튼 영역 (알림 종 아이콘, 프로필 아바타)
          Row(
            children: [
              // 디자인 고도화된 원형 알림 버튼 (38x38 규격)
              _NotificationIconButton(
                hasNotification: _hasUnreadNotification,
                onTap: () {
                  setState(() {
                    _hasUnreadNotification = false; // 알림 클릭 시 레드닷 해제
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('새로운 알림이 없습니다.')),
                  );
                },
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
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFF5F5F5),
                    child: UserData.isDefaultProfileImage || UserData.profileImagePath == null
                        ? const Icon(Icons.person_outline, size: 22, color: Color(0xFF504D46))
                        : ClipOval(
                      child: Image.network(
                        UserData.profileImagePath!,
                        width: 38,
                        height: 38,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.person_outline, size: 22, color: Color(0xFF504D46));
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
  final bool hasNotification;
  final VoidCallback onTap;

  const _NotificationIconButton({
    required this.hasNotification,
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
          color: const Color(0xFFFAF6F0), // 따뜻한 베이지 배경
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              size: 20,
              color: Color(0xFF504D46),
            ),
            // 안 읽은 알림이 있을 경우 우측 상단 붉은색 인디케이터 표시
            if (hasNotification)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5252), // 포인트 레드
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}