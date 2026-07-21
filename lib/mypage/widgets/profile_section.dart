import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🌟 로그아웃을 위한 Firebase Auth 추가
import '../../common/user_data.dart';
import '../../login/login_screen.dart';
import '../setting/myinfo.dart';

class ProfileSection extends StatelessWidget {
  final VoidCallback onRefresh;

  const ProfileSection({Key? key, required this.onRefresh}) : super(key: key);

  // 🌟 로그아웃 다이얼로그 함수
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('로그아웃', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: const Text('정말 로그아웃 하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext), // 취소
              child: const Text('취소', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // 다이얼로그 닫기

                // 파이어베이스 로그아웃 처리
                await FirebaseAuth.instance.signOut();

                // 🌟 LoginScreen() 위젯을 직접 호출하여 이동 (이전 화면 스택 모두 삭제)
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                  );
                }
              },
              child: const Text('로그아웃', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // 1. 프로필 이미지
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFFF5F5F5),
              child: UserData.isDefaultProfileImage || UserData.profileImagePath == null
                  ? const Icon(Icons.person_outline, size: 35, color: Colors.grey)
                  : ClipOval(
                child: Image.network(
                  UserData.profileImagePath!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.person_outline, size: 35, color: Colors.grey);
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),

            // 2. 닉네임
            Expanded(
              child: Text(
                UserData.nickname ?? '로딩중...',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),

            // 3. 🌟 수정 & 로그아웃 버튼 (Column으로 세로 배치)
            Column(
              mainAxisSize: MainAxisSize.min, // 최소한의 세로 공간만 차지
              children: [
                // 수정 버튼
                SizedBox(
                  height: 32,
                  width: 68, // 두 버튼의 너비 통일
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MyInfoScreen()),
                      ).then((_) => onRefresh());
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.zero, // 텍스트 짤림 방지
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text('수정', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 6), // 간격

                // 로그아웃 버튼
                SizedBox(
                  height: 32,
                  width: 68,
                  child: OutlinedButton(
                    onPressed: () => _showLogoutDialog(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      padding: EdgeInsets.zero,
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text('로그아웃', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.only(left: 76.0),
          child: Text('좋아요 0   스크랩 0', style: TextStyle(color: Colors.black87)),
        ),
      ],
    );
  }
}