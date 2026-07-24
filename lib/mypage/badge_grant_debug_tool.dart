import 'package:flutter/material.dart';
import '../../services/badge_service.dart'; // 프로젝트 경로에 맞게 조정해주세요

/// 🌟 1회용 디버그 유틸: 실제 뱃지 발급 로직(BadgeService.checkAndGrantBadges)을
/// 지정한 유저들에게 그대로 실행합니다.
///
/// 인위적으로 뱃지를 밀어넣는 게 아니라, 각 유저의 실제 stamp/road 데이터를
/// 조건 검사해서 "진짜 자격이 되는 뱃지만" 발급합니다.
/// (즉, 이 UID들의 stamp 컬렉션에 실제 스탬프 데이터가 없다면 뱃지도 0개로 남습니다 —
///  그게 정상 동작입니다. 뱃지를 보고 싶다면 먼저 해당 계정으로 실제 스탬프를 찍어야 해요.)
///
/// mypage_main_screen.dart 등에서 임시로 버튼 하나 붙여 실행한 뒤,
/// 확인되면 이 파일과 버튼은 지워도 됩니다.
class BadgeRealCheckDebugTool {
  static Future<void> runRealBadgeCheck(
      BuildContext context, {
        required List<String> targetUids,
      }) async {
    for (final uid in targetUids) {
      debugPrint('🔍 [BadgeRealCheck] uid=$uid 실제 뱃지 조건 검사 시작...');
      await BadgeService.checkAndGrantBadges(context, uid);
      debugPrint('✅ [BadgeRealCheck] uid=$uid 검사 완료');
    }
  }
}

/// 🌟 화면에 임시로 붙여서 쓰는 버튼 위젯.
/// 마이페이지 build() 안에 <BadgeRealCheckDebugButton() 한 줄만 넣으면 됩니다.
class BadgeRealCheckDebugButton extends StatefulWidget {
  const BadgeRealCheckDebugButton({Key? key}) : super(key: key);

  @override
  State<BadgeRealCheckDebugButton> createState() => _BadgeRealCheckDebugButtonState();
}

class _BadgeRealCheckDebugButtonState extends State<BadgeRealCheckDebugButton> {
  bool _isRunning = false;

  Future<void> _run() async {
    setState(() => _isRunning = true);
    try {
      await BadgeRealCheckDebugTool.runRealBadgeCheck(
        context,
        targetUids: [
          'Hk1jkJ6p8VgY08nRjGmzbonw6fF2', // 필우청
          'bYfwKMFjxZfd0JkEsJNPMOHqOwP2', // patato
        ],
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('실제 뱃지 조건 검사 완료! (자격 되는 뱃지만 발급됨)')),
        );
      }
    } catch (e) {
      debugPrint('🔴 [BadgeRealCheck] 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('뱃지 검사 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        onPressed: _isRunning ? null : _run,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
        child: _isRunning
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        )
            : const Text('🧪 실제 뱃지 조건 재검사 (진짜 자격만 발급)', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
