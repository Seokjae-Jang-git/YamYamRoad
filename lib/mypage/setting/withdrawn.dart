import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../common/user_data.dart';
import '../../login/login_screen.dart';

class WithdrawnScreen extends StatefulWidget {
  const WithdrawnScreen({Key? key}) : super(key: key);

  @override
  State<WithdrawnScreen> createState() => _WithdrawnScreenState();
}

class _WithdrawnScreenState extends State<WithdrawnScreen> {
  // 화면에 띄울 정보들을 담을 컨트롤러 (읽기 전용)
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _socialController = TextEditingController();

  bool _isLoading = false; // 탈퇴 처리 중 로딩 상태

  @override
  void initState() {
    super.initState();
    // 🌟 로컬 전역 변수(UserData)에 있는 현재 유저 정보를 컨트롤러에 세팅합니다.
    _nicknameController.text = UserData.nickname ?? '로딩중...';
    _nameController.text = UserData.name ?? '로딩중...';
    _phoneController.text = UserData.phone ?? '로딩중...';
    _socialController.text = 'Google'; // 소셜 로그인 제공자는 임시로 고정
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _socialController.dispose();
    super.dispose();
  }

  // 🌟 실제 DB(Firestore) 탈퇴 처리 (Soft Delete 로직)
  Future<void> _processWithdrawal() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Hard Delete(문서 삭제)가 아닌 Soft Delete(상태 변경 및 시간 기록)를 수행
      await FirebaseFirestore.instance.collection('users').doc(UserData.uid).update({
        'status': 'withdrawn', // 상태를 '탈퇴'로 변경
        'withdrawnAt': FieldValue.serverTimestamp(), // 서버의 현재 시간을 탈퇴 시간으로 기록
      });

      setState(() {
        _isLoading = false;
      });

      // 완료 팝업 띄우기
      if (mounted) {
        _showCompletionDialog();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("탈퇴 처리 에러: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('탈퇴 처리 중 오류가 발생했습니다.')),
      );
    }
  }

  // 🌟 완료 팝업 및 로그인 화면 이동 로직
  // 🌟 완료 팝업 및 로그인 화면 이동 로직
  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // 팝업 바깥을 눌러서 닫히지 않게 고정
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)), // 기획서의 플랫 디자인
          contentPadding: const EdgeInsets.only(top: 32, bottom: 16, left: 24, right: 24),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('삭제 처리 되었습니다.', style: TextStyle(fontSize: 15)),
              SizedBox(height: 8),
              Text('로그인 화면으로 이동합니다.', style: TextStyle(fontSize: 15)),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            OutlinedButton(
              onPressed: () {
                // 1. 임시로 내부에 저장된 UserData 초기화
                UserData.nickname = '';
                UserData.name = '';
                UserData.phone = '';
                UserData.profileImagePath = null;

                // 2. 🌟 앱에 켜져있던 모든 화면 기록(스택)을 지우고, 실제 로그인 화면으로 이동!
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()), // 🌟 실제 LoginScreen 장착!
                      (route) => false,
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                minimumSize: const Size(100, 40),
              ),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '계정 삭제',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      // 바텀바 없음! 온전히 화면만 덮습니다.
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildReadOnlyField('닉네임', _nicknameController),
            const SizedBox(height: 16),
            _buildReadOnlyField('이름', _nameController),
            const SizedBox(height: 16),
            _buildReadOnlyField('휴대폰번호', _phoneController),
            const SizedBox(height: 16),
            _buildReadOnlyField('소셜로그인', _socialController),

            const SizedBox(height: 48),

            // 경고 텍스트 영역
            const Text(
              '삭제 후 30일 이내 계정 복구가 가능하며,\n30일 이후 해당 계정 및 데이터가 모두 삭제됩니다.\n상기 계정을 삭제하겠습니까?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
            ),

            const SizedBox(height: 32),

            // 버튼 2개 영역 (삭제 / 취소)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100,
                  child: OutlinedButton(
                    onPressed: _processWithdrawal, // 삭제 로직 실행
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                    ),
                    child: const Text('삭제'),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 100,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context); // 취소 시 이전 화면으로 돌아감
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                    ),
                    child: const Text('취소'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // 🌟 읽기 전용 입력 필드 공통 위젯 (회색 배경, 수정 불가)
  Widget _buildReadOnlyField(String label, TextEditingController controller) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            readOnly: true, // 수정 불가 처리
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black87, fontSize: 14),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.zero,
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.zero,
              ),
              filled: true,
              fillColor: Colors.grey.shade100, // 입력 불가 느낌을 주는 옅은 회색 배경
            ),
          ),
        ),
      ],
    );
  }
}