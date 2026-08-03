import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  String? _verificationId;
  int _resendSeconds = 0;
  int? _resendToken;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String get _formattedPhone {
    final digits = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0')) {
      return '+82${digits.substring(1)}';
    }
    return '+82$digits';
  }

  // 🌟 Firebase Phone Auth가 주는 E.164 형식(+821012345678)을
  // 국내에서 익숙한 하이픈 형식(010-1234-5678)으로 변환해서 저장.
  // 표준 010 휴대폰 번호(11자리)와, 혹시 모를 10자리 번호도 함께 처리.
  String _toLocalPhoneFormat(String? e164) {
    if (e164 == null || e164.isEmpty) return '';
    String digits = e164.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('82')) {
      digits = '0${digits.substring(2)}';
    } else if (!digits.startsWith('0')) {
      digits = '0$digits';
    }

    if (digits.length == 11) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
    } else if (digits.length == 10) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
    }
    return digits;
  }

  // ---------------- 1단계: 인증번호 발송 ----------------
  Future<void> _sendCode() async {
    if (_phoneController.text.trim().length < 9) {
      _showError('휴대폰 번호를 정확히 입력해주세요.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _formattedPhone,
        forceResendingToken: _resendToken,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          _showError('인증번호 발송에 실패했습니다: ${e.message ?? e.code}');
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _codeSent = true;
            _isLoading = false;
          });
          _startResendTimer();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('인증번호 발송 중 오류가 발생했습니다: $e');
    }
  }

  void _startResendTimer() {
    setState(() => _resendSeconds = 180);
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
    if (_verificationId == null) {
      _showError('인증 세션이 만료되었습니다. 인증번호를 다시 받아주세요.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _codeController.text.trim(),
      );
      await _signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      _showError('인증번호가 올바르지 않습니다: ${e.message ?? e.code}');
    } catch (e) {
      _showError('인증 중 오류가 발생했습니다: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------- 공통: 자격 증명으로 Firebase 로그인 ----------------
  //
  // 🌟 탈퇴 체크는 이제 여기서 하지 않습니다.
  //    로그인 성공 → authStateChanges 발동 → main.dart가 MainHomeScreen으로 전환
  //    → MainHomeScreen.initState()에서 탈퇴 여부를 확인하고 복구 팝업을 띄웁니다.
  //    여기서 context를 써서 다이얼로그를 띄우면, 화면 전환 타이밍과 겹쳐
  //    context가 이미 unmount된 상태일 수 있어 실패했었습니다.
  //
  // 🌟 다만 밴(banned) 상태는 여기서 바로 막습니다. 기존 회원 문서가 이미
  //    banned 상태라면 로그인 자체를 취소시켜서 다음 화면으로 못 넘어가게 합니다.
  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        _showError('로그인에 실패했습니다.');
        return;
      }

      final docRef =
      FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid);
      final snapshot = await docRef.get();
      final localPhone = _toLocalPhoneFormat(firebaseUser.phoneNumber);

      if (!snapshot.exists) {
        await docRef.set({
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'freePointBalance': 0,
          'paidPointBalance': 0,
          'lastLocation': null,
          'name': null,
          'nickname': '휴대폰 회원',
          'phone': localPhone,
          'profileImageUrl': null,
          'provider': 'phone',
          'selectedBadgeIds': null,
          'status': 'active',
          'withdrawnAt': null,
        });
      } else {
        final existingStatus = snapshot.data()?['status'] as String?;
        if (existingStatus == 'banned') {
          await FirebaseAuth.instance.signOut();
          _showError('이용이 제한된 계정입니다. 고객센터로 문의해주세요.');
          return;
        }

        await docRef.update({
          'updatedAt': FieldValue.serverTimestamp(),
          'phone': localPhone,
        });
      }

      debugPrint('🟢 휴대폰 로그인 완료: uid=${firebaseUser.uid}');

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showError('로그인 처리 중 오류가 발생했습니다: $e');
    }
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
                  onPressed: _resendSeconds == 0 && !_isLoading ? _sendCode : null,
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
