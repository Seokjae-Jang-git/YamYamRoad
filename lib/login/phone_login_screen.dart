import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  // ── 로그인 화면과 통일한 브랜드 컬러 토큰 ─────────────
  static const Color _bgTop = Color(0xFFFEFDFB);
  static const Color _bgBottom = Color(0xFFFBF4EC);
  static const Color primaryColor = Color(0xFFE8845A);
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      _buildIcon(),
                      const SizedBox(height: 20),
                      const Text(
                        '휴대폰 번호로 시작하기',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textDark),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '본인 명의의 휴대폰 번호를 입력해주세요',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: textDark.withOpacity(0.5)),
                      ),
                      const SizedBox(height: 36),

                      _buildFieldLabel('휴대폰 번호'),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              enabled: !_codeSent,
                              hint: '010 1234 5678',
                              icon: Icons.phone_iphone_rounded,
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: (_isLoading || _codeSent) ? null : _sendCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: primaryColor.withOpacity(0.4),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text(
                                _codeSent ? '전송됨' : '인증번호 받기',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),

                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _codeSent
                            ? Padding(
                          key: const ValueKey('code-section'),
                          padding: const EdgeInsets.only(top: 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildFieldLabel('인증번호'),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _codeController,
                                      keyboardType: TextInputType.number,
                                      maxLength: 6,
                                      hint: '6자리 숫자 입력',
                                      icon: Icons.lock_outline_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      _formatTimer(_resendSeconds),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: primaryColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _resendSeconds == 0 && !_isLoading ? _sendCode : null,
                                  style: TextButton.styleFrom(foregroundColor: primaryColor),
                                  child: const Text('인증번호 재전송', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        )
                            : const SizedBox(key: ValueKey('empty'), height: 0),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : (_codeSent ? _verifyCode : null),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            disabledBackgroundColor: primaryColor.withOpacity(0.35),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                              : const Text('확인', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: textDark),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return Center(
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(Icons.sms_rounded, color: primaryColor, size: 34),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textDark.withOpacity(0.6)));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required TextInputType keyboardType,
    required String hint,
    required IconData icon,
    bool enabled = true,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      maxLength: maxLength,
      style: const TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        counterText: '',
        prefixIcon: Icon(icon, size: 18, color: textDark.withOpacity(0.35)),
        hintText: hint,
        hintStyle: TextStyle(color: textDark.withOpacity(0.3), fontWeight: FontWeight.w400),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.white.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }

  String _formatTimer(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
