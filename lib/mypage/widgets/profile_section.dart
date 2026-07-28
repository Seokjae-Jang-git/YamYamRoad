import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../common/user_data.dart';
import '../../login/login_screen.dart';
import '../setting/myinfo.dart';

class ProfileSection extends StatelessWidget {
  final VoidCallback onRefresh;

  // YamYamRoad 브랜드 공식 컬러 상수 정의
  static const Color coralRed = Color(0xFFFF6B57);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color subTextColor = Color(0xFF7A6B63);
  static const Color buttonBorderColor = Color(0xFFD0C4B8);

  const ProfileSection({Key? key, required this.onRefresh}) : super(key: key);

  // 🌟 로그아웃 다이얼로그 함수
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFFBF8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            '로그아웃',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: deepChocolate,
            ),
          ),
          content: const Text(
            '정말 로그아웃 하시겠습니까?',
            style: TextStyle(color: subTextColor, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext), // 취소
              child: const Text('취소', style: TextStyle(color: subTextColor)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // 다이얼로그 닫기

                // 파이어베이스 로그아웃 처리
                await FirebaseAuth.instance.signOut();

                // LoginScreen() 위젯을 직접 호출하여 이동 (이전 화면 스택 모두 삭제)
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                  );
                }
              },
              child: const Text(
                '로그아웃',
                style: TextStyle(color: coralRed, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. 프로필 이미지 (브랜드 포인트 컬러 테두리)
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: coralRed.withOpacity(0.35), width: 2),
          ),
          padding: const EdgeInsets.all(2),
          child: CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFFFF4F2),
            child: UserData.isDefaultProfileImage || UserData.profileImagePath == null
                ? const Icon(Icons.person_outline, size: 34, color: subTextColor)
                : ClipOval(
              child: Image.network(
                UserData.profileImagePath!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.person_outline, size: 34, color: subTextColor);
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // 2. 닉네임 + 좋아요/스크랩 영역 (세로 배치)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                UserData.nickname ?? '로딩중...',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: deepChocolate,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4), // 닉네임과 좋아요 사이 간격
              const Text(
                '좋아요 0   스크랩 0',
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // 3. 수정 & 로그아웃 버튼 (Column으로 세로 배치)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 수정 버튼
            SizedBox(
              height: 32,
              width: 72,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyInfoScreen()),
                  ).then((_) => onRefresh());
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: deepChocolate,
                  padding: EdgeInsets.zero,
                  side: const BorderSide(color: buttonBorderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  backgroundColor: Colors.white,
                ),
                child: const Text(
                  '수정',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: deepChocolate,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // 로그아웃 버튼
            SizedBox(
              height: 32,
              width: 72,
              child: OutlinedButton(
                onPressed: () => _showLogoutDialog(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: subTextColor,
                  padding: EdgeInsets.zero,
                  side: BorderSide(color: buttonBorderColor.withOpacity(0.6)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  backgroundColor: const Color(0xFFFAF7F5),
                ),
                child: const Text(
                  '로그아웃',
                  style: TextStyle(
                    fontSize: 11,
                    color: subTextColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}