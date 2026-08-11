import 'package:flutter/material.dart';

import 'phone_login_screen.dart';
import 'login_controller.dart';
import 'widgets/login_widgets.dart';

import '../yamyam_home/main_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  static const Color _bgTop = Color(0xFFFEFDFB);
  static const Color _bgBottom = Color(0xFFFBF4EC);
  static const Color _textDark = Color(0xFF3E2723);
  static const Color _kakaoColor = Color(0xFFFEE500);
  static const Color _naverColor = Color(0xFF03C75A);
  static const Color _pinColor = Color(0xFFE8845A);

  bool _isLoading = false;
  late final LoginController _controller;
  late final AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _controller = LoginController();
    _controller.initGoogleSignIn();

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  void _setLoading(bool value) {
    if (mounted) setState(() => _isLoading = value);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handlePhoneLogin() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const PhoneLoginScreen()),
    );
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0),
                      child: Column(
                        children: [
                          const Spacer(flex: 3),
                          _buildLogoWithRipple(),
                          const SizedBox(height: 22),
                          const Text(
                            '얌얌로드',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: _textDark,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '전국 디저트순례, 얌얌로드와 함께',
                            style: TextStyle(fontSize: 14, color: _textDark.withOpacity(0.55)),
                          ),
                          const SizedBox(height: 80),
                          _buildButtons(),
                          const SizedBox(height: 22),
                          Text(
                            '계속 진행 시 얌얌의 이용약관과\n개인정보처리방침에 동의하게 됩니다.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: _textDark.withOpacity(0.4), height: 1.5),
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLogoWithRipple() {
    return SizedBox(
      width: 160,
      height: 160,
      child: AnimatedBuilder(
        animation: _rippleController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              _ripple(delay: 0.0),
              _ripple(delay: 0.33),
              _ripple(delay: 0.66),
              child!,
            ],
          );
        },
        child: Container(
          width: 100,
          height: 100,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: _pinColor.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(48),
            child: Image.asset(
              'assets/temp_images/yamyam_logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  Widget _ripple({required double delay}) {
    final t = (_rippleController.value + delay) % 1.0;
    final scale = 0.6 + t * 1.0;
    final opacity = (1.0 - t).clamp(0.0, 1.0) * 0.3;
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _pinColor, width: 1.5),
          ),
        ),
      ),
    );
  }

  // 🌟 로그인 성공 시 호출될 라우팅 함수 추가
  void _onLoginSuccess() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainHomeScreen()),
          (route) => false,
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        SocialButton(
          label: '카카오로 시작하기',
          backgroundColor: _kakaoColor,
          textColor: const Color(0xFF3C1E1E),
          customIcon: const KakaoIcon(size: 20),
          loading: _isLoading,
          onPressed: () => _controller.handleKakaoLogin(
            setLoading: _setLoading,
            onError: _showError,
            onSuccess: _onLoginSuccess,
          ),
        ),
        const SizedBox(height: 12),
        SocialButton(
          label: '네이버로 시작하기',
          backgroundColor: _naverColor,
          textColor: Colors.white,
          customIcon: const NaverIcon(size: 20),
          loading: _isLoading,
          onPressed: () => _controller.handleNaverLogin(
            setLoading: _setLoading,
            onError: _showError,
            onSuccess: _onLoginSuccess,
          ),
        ),
        const SizedBox(height: 12),
        SocialButton(
          label: '구글로 시작하기',
          backgroundColor: Colors.white,
          textColor: _textDark,
          borderColor: _textDark.withOpacity(0.12),
          customIcon: const GoogleIcon(size: 20),
          loading: _isLoading,
          onPressed: () => _controller.handleGoogleLogin(
            setLoading: _setLoading,
            onError: _showError,
            onSuccess: _onLoginSuccess,
          ),
        ),
        const SizedBox(height: 22),
        SocialButton(
          label: '휴대폰 번호로 시작하기',
          backgroundColor: Colors.white,
          textColor: _textDark,
          borderColor: _textDark.withOpacity(0.12),
          icon: Icons.phone_iphone_rounded,
          loading: false,
          onPressed: _handlePhoneLogin,
        ),
      ],
    );
  }
}