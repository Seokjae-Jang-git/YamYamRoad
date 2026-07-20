import 'package:flutter/material.dart';
// TODO: firebase_auth 패키지 추가 후 아래 주석 해제
import 'package:firebase_auth/firebase_auth.dart';

// ============================================
// 얌얌(YumYum) 휴대폰 번호 로그인 화면
// 1단계: 전화번호 입력 → 인증번호 발송
// 2단계: 인증번호(OTP) 입력 → 확인 → 로그인/자동가입
//
// Firebase Phone Auth 기준으로 작성했습니다.
// (SMS 발송/인증 자체 서버로 구현할 경우 로직만 교체하면 화면 구조는 동일)
// ============================================

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  static const Color primaryColor = Color(0xFFFF9F5A);
  static const Color textDark = Color(0xFF3E2723);

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  bool _codeSent = false;
  bool _isLoading = false;
  String? _verificationId; // Firebase 인증 세션 ID
  int _resendSeconds = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String get _formattedPhone {
    // 010-1234-5678 → +82 10-1234-5678 형식으로 변환 (Firebase는 E.164 형식 필요)
    final digits = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0')) {
      return '+82${digits.substring(1)}';
    }
    return '+82$digits';
  }

  // ---------------- 1단계: 인증번호 발송 ----------------
  Future<void> _sendCode() async {
    if (_phoneController.text.trim().length < 9) {
      _showError('휴대폰 번호를 정확히 입력해주세요.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Firebase Phone Auth 연동
      // await FirebaseAuth.instance.verifyPhoneNumber(
      //   phoneNumber: _formattedPhone,
      //   verificationCompleted: (PhoneAuthCredential credential) async {
      //     // 안드로이드 자동 인증 완료 시
      //     await FirebaseAuth.instance.signInWithCredential(credential);
      //     _goToHome();
      //   },
      //   verificationFailed: (FirebaseAuthException e) {
      //     _showError('인증번호 발송에 실패했습니다: ${e.message}');
      //   },
      //   codeSent: (String verificationId, int? resendToken) {
      //     setState(() {
      //       _verificationId = verificationId;
      //       _codeSent = true;
      //     });
      //     _startResendTimer();
      //   },
      //   codeAutoRetrievalTimeout: (String verificationId) {
      //     _verificationId = verificationId;
      //   },
      // );

      await Future.delayed(const Duration(seconds: 1)); // 임시 딜레이
      setState(() {
        _codeSent = true;
        _verificationId = 'mock_verification_id';
      });
      _startResendTimer();
    } catch (e) {
      _showError('인증번호 발송 중 오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startResendTimer() {
    setState(() => _resendSeconds = 180); // 3분
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_resendSeconds <= 0) return false;
      setState(() => _resendSeconds--);
      return _resendSeconds > 0;
    });
  }

  // ---------------- 2단계: 인증번호 확인 ----------------
  Future<void> _verifyCode() async {
    if (_codeController.text.trim().length != 6) {
      _showError('인증번호 6자리를 입력해주세요.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Firebase Phone Auth 인증 확인
      // final credential = PhoneAuthProvider.credential(
      //   verificationId: _verificationId!,
      //   smsCode: _codeController.text.trim(),
      // );
      // final userCredential =
      //     await FirebaseAuth.instance.signInWithCredential(credential);
      //
      // → 서버에 phoneNumber 기반 로그인/자동가입 요청
      // final result = await AuthService.socialLogin(
      //   loginType: 'PHONE',
      //   phoneNumber: _formattedPhone,
      // );

      await Future.delayed(const Duration(seconds: 1)); // 임시 딜레이
      _goToHome();
    } catch (e) {
      _showError('인증번호가 올바르지 않습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToHome() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: const Text('휴대폰 번호로 시작하기',
            style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // 전화번호 입력
              Text('휴대폰 번호', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textDark.withOpacity(0.7))),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      enabled: !_codeSent,
                      decoration: _inputDecoration('010 1234 5678'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (_isLoading || _codeSent) ? null : _sendCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(_codeSent ? '전송됨' : '인증번호 받기'),
                    ),
                  ),
                ],
              ),

              if (_codeSent) ...[
                const SizedBox(height: 24),
                Text('인증번호', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textDark.withOpacity(0.7))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: _inputDecoration('6자리 숫자 입력').copyWith(counterText: ''),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatTimer(_resendSeconds),
                      style: TextStyle(fontSize: 13, color: primaryColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _resendSeconds == 0 ? _sendCode : null,
                  child: const Text('인증번호 재전송'),
                ),
              ],

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : (_codeSent ? _verifyCode : null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: primaryColor.withOpacity(0.4),
                ),
                child: _isLoading
                    ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : const Text('확인', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimer(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: textDark.withOpacity(0.3)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: textDark.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: textDark.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
    );
  }
}