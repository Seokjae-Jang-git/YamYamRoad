import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  @override
  void initState() {
    super.initState();
    _loadProfileIfNeeded();
  }

  // UserData 프로필 정보 로드
  Future<void> _loadProfileIfNeeded() async {
    final String? currentUid = AuthService.currentUser?.uid;
    if (currentUid == null) return;

    if (UserData.uid == currentUid && UserData.nickname != null) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUid).get();
      if (!mounted) return;
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          UserData.uid = currentUid;
          UserData.nickname = data['nickname'] ?? '이름없음';
          UserData.name = data['name'] ?? '';
          UserData.phone = data['phone'] ?? '';
          UserData.profileImagePath = data['profileImageUrl'];
          UserData.isDefaultProfileImage =
          (data['profileImageUrl'] == null || data['profileImageUrl'].toString().isEmpty);
        });
      }
    } catch (e) {
      debugPrint('🔴 홈 헤더 프로필 로드 실패: $e');
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

      UserData.uid = null;
      UserData.nickname = null;
      UserData.name = null;
      UserData.phone = null;
      UserData.profileImagePath = null;
      UserData.isDefaultProfileImage = true;
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
          // 우측 상단 버튼 (알림, 프로필)
          Row(
            children: [
              _TopCircleButton(
                text: '알림',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('새로운 알림이 없습니다.')),
                  );
                },
              ),
              const SizedBox(width: 8),
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
                        ? const Icon(Icons.person_outline, size: 24, color: Colors.grey)
                        : ClipOval(
                      child: Image.network(
                        UserData.profileImagePath!,
                        width: 38,
                        height: 38,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.person_outline, size: 24, color: Colors.grey);
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

/// 흡수 통합된 상단 원형 버튼 위젯 (기존 top_circle_button.dart 대체)
class _TopCircleButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const _TopCircleButton({
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, height: 1.2),
        ),
      ),
    );
  }
}