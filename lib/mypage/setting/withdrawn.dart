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
  // 공통 색상 팔레트
  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color creamyIvory = Color(0xFFFFFDF9);
  static const Color subTextColor = Color(0xFF7A6B63);

  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _socialController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nicknameController.text = UserData.nickname ?? '로딩중...';
    _nameController.text = UserData.name ?? '로딩중...';
    _phoneController.text = UserData.phone ?? '로딩중...';
    _socialController.text = 'Google';
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _socialController.dispose();
    super.dispose();
  }

  // 실제 DB(Firestore) 탈퇴 처리 (Soft Delete)
  Future<void> _processWithdrawal() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(UserData.uid).update({
        'status': 'paused',
        'pausedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        _showCompletionDialog();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // debugPrint("탈퇴 처리 에러: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('탈퇴 처리 중 오류가 발생했습니다.')),
      );
    }
  }

  // 완료 팝업 및 로그인 화면 이동
  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: creamyIvory,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.only(top: 32, bottom: 24, left: 24, right: 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, color: pointCoralRed, size: 48),
              const SizedBox(height: 16),
              const Text('삭제 처리 되었습니다.', style: TextStyle(fontSize: 16, color: deepChocolate, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('로그인 화면으로 이동합니다.', style: TextStyle(fontSize: 14, color: subTextColor)),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.only(bottom: 24),
          actions: [
            ElevatedButton(
              onPressed: () {
                UserData.nickname = '';
                UserData.name = '';
                UserData.phone = '';
                UserData.profileImagePath = null;

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: deepChocolate,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(120, 48),
                elevation: 0,
              ),
              child: const Text('확인', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamyIvory,
      appBar: AppBar(
        title: const Text(
          '계정 삭제',
          style: TextStyle(color: deepChocolate, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: creamyIvory,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: deepChocolate, size: 28),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: pointCoralRed))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 정보 확인 카드 영역
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: deepChocolate.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: deepChocolate.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 40, color: pointCoralRed),
                  const SizedBox(height: 16),
                  const Text('삭제할 계정 정보를 확인해주세요.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: deepChocolate)),
                  const SizedBox(height: 24),
                  _buildReadOnlyField('닉네임', _nicknameController),
                  const SizedBox(height: 16),
                  _buildReadOnlyField('이름', _nameController),
                  const SizedBox(height: 16),
                  _buildReadOnlyField('휴대폰번호', _phoneController),
                  const SizedBox(height: 16),
                  _buildReadOnlyField('소셜로그인', _socialController),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // 경고 텍스트 영역
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: pointCoralRed.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: pointCoralRed.withOpacity(0.2)),
              ),
              child: const Text(
                '삭제 후 30일 이내 계정 복구가 가능하며,\n30일 이후 해당 계정 및 데이터가 모두 영구 삭제됩니다.\n\n정말로 이 계정을 삭제하시겠습니까?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.6, color: pointCoralRed, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 40),

            // 버튼 영역
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.white,
                      side: BorderSide(color: deepChocolate.withOpacity(0.15)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('취소', style: TextStyle(color: subTextColor, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _processWithdrawal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pointCoralRed,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('삭제', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // 읽기 전용 폼 레이아웃 (위-아래 구조로 통일)
  Widget _buildReadOnlyField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: subTextColor)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: true,
          style: const TextStyle(color: subTextColor, fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: deepChocolate.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: deepChocolate.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: deepChocolate.withOpacity(0.04),
          ),
        ),
      ],
    );
  }
}