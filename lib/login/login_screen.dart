import 'package:flutter/material.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

// 🌟 휴대폰 로그인 화면 임포트
import 'phone_login_screen.dart';

// [네이티브 설정 필요]
//   - Android: AndroidManifest.xml에 카카오/네이버 키 해시, 스킴 등록

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  // ── 브랜드 컬러 토큰 (전체화면 그라데이션 기준으로 재조정) ─────────
  static const Color _bgTop = Color(0xFFFEFDFB);
  static const Color _bgBottom = Color(0xFFFBF4EC);
  static const Color _textDark = Color(0xFF3E2723);
  static const Color _kakaoColor = Color(0xFFFEE500);
  static const Color _naverColor = Color(0xFF03C75A);
  static const Color _pinColor = Color(0xFFE8845A);

  bool _isLoading = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleSignInReady = false;

  late final AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _initGoogleSignIn();
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

  Future<void> _initGoogleSignIn() async {
    try {
      await _googleSignIn.initialize(
        serverClientId: '964766524983-2h5i53gehbvf1ti82ih7aeel99k7aln2.apps.googleusercontent.com',
      );
      _googleSignInReady = true;
      debugPrint('✅ 구글 SDK 초기화 성공');
    } catch (e) {
      debugPrint('🔴 구글 SDK 초기화 실패: $e');
    }
  }

  void _setLoading(bool value) {
    if (mounted) setState(() => _isLoading = value);
  }

  // 🌟 users/{uid} 문서의 status가 'banned'인지 확인.
  // banned면 즉시 Firebase Auth에서 sign-out 시켜서
  // main.dart의 authStateChanges StreamBuilder가 로그인 화면에 그대로 머물게 함.
  Future<bool> _blockIfBanned(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final status = doc.data()?['status'] as String?;
      if (status == 'banned') {
        await FirebaseAuth.instance.signOut();
        _showError('이용이 제한된 계정입니다. 고객센터로 문의해주세요.');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('🔴 계정 상태 확인 실패: $e');
      return false;
    }
  }

  // ---------------- 카카오 로그인 ----------------
  Future<void> _handleKakaoLogin() async {
    _setLoading(true);
    try {
      bool isInstalled = await isKakaoTalkInstalled();
      OAuthToken token = isInstalled
          ? await UserApi.instance.loginWithKakaoTalk()
          : await UserApi.instance.loginWithKakaoAccount();

      debugPrint('🟢 카카오 로그인 성공');

      final userModel = await AuthService.loginWithKakao(token.accessToken);
      debugPrint('🟢 AuthService 카카오 로그인 완료: uid=${userModel.uid}');

      if (await _blockIfBanned(userModel.uid)) return;

      // 🌟 탈퇴 체크는 MainHomeScreen.initState()에서 처리하므로
      //    여기서는 아무것도 하지 않습니다.
      // 🌟 화면 전환은 main.dart의 StreamBuilder(authStateChanges)가 자동으로 처리합니다.
    } catch (e, stackTrace) {
      debugPrint('🔴 카카오 로그인 에러: $e');
      debugPrint('🔴 스택트레이스: $stackTrace');
      _showError('카카오 로그인에 실패했습니다.');
    } finally {
      _setLoading(false);
    }
  }

  // ---------------- 네이버 로그인 ----------------
  Future<void> _handleNaverLogin() async {
    _setLoading(true);
    try {
      final result = await FlutterNaverLogin.logIn();
      debugPrint('🟢 네이버 로그인 status: ${result.status}');

      if (result.status != NaverLoginStatus.loggedIn) {
        _showError('네이버 로그인이 취소되었습니다.');
        return;
      }

      final tokenResult = await FlutterNaverLogin.getCurrentAccessToken();
      final userModel = await AuthService.loginWithNaver(tokenResult.accessToken);
      debugPrint('🟢 AuthService 네이버 로그인 완료: uid=${userModel.uid}');

      if (await _blockIfBanned(userModel.uid)) return;

      // 🌟 탈퇴 체크는 MainHomeScreen.initState()에서 처리합니다.
      // 🌟 화면 전환은 StreamBuilder가 자동으로 처리합니다.
    } catch (e, stackTrace) {
      debugPrint('🔴 네이버 로그인 에러: $e');
      debugPrint('🔴 스택트레이스: $stackTrace');
      _showError('네이버 로그인에 실패했습니다.');
    } finally {
      _setLoading(false);
    }
  }

  // ---------------- 구글 로그인 (v7 API) ----------------
  Future<void> _handleGoogleLogin() async {
    _setLoading(true);
    try {
      if (!_googleSignInReady) {
        await _initGoogleSignIn();
      }

      final GoogleSignInAccount account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;

      final userModel = await AuthService.loginWithGoogle(idToken: idToken);
      debugPrint('🟢 AuthService 구글 로그인 완료: uid=${userModel.uid}');

      if (await _blockIfBanned(userModel.uid)) return;

      // 🌟 탈퇴 체크는 MainHomeScreen.initState()에서 처리합니다.
      // 🌟 화면 전환은 StreamBuilder가 자동으로 처리합니다.
    } on GoogleSignInException catch (e) {
      debugPrint('🔴 GoogleSignInException: code=${e.code}');
      if (e.code == GoogleSignInExceptionCode.canceled) {
        _showError('구글 로그인이 취소되었습니다.');
      } else {
        _showError('구글 로그인에 실패했습니다.');
      }
    } catch (e, stackTrace) {
      debugPrint('🔴 구글 로그인 알 수 없는 에러: $e');
      debugPrint('🔴 스택트레이스: $stackTrace');
      _showError('구글 로그인에 실패했습니다.');
    } finally {
      _setLoading(false);
    }
  }

  // ---------------- 휴대폰 번호 로그인 ----------------
  Future<void> _handlePhoneLogin() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const PhoneLoginScreen()),
    );
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
                            '얌얌',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: _textDark,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '동네 빵지순례, 얌얌과 함께',
                            style: TextStyle(fontSize: 14, color: _textDark.withOpacity(0.55)),
                          ),
                          const Spacer(flex: 4),
                          _buildButtons(),
                          const SizedBox(height: 22),
                          Text(
                            '계속 진행 시 얌얌의 이용약관과\n개인정보처리방침에 동의하게 됩니다.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: _textDark.withOpacity(0.4), height: 1.5),
                          ),
                          const SizedBox(height: 24),
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

  // 🌟 기존 도넛+핀 로고를 유지하면서, 전체화면 버전의 시그니처인
  //   파동(ripple) 애니메이션을 배경에 추가
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
          width: 96,
          height: 96,
          padding: const EdgeInsets.all(12),
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
          child: CustomPaint(painter: _PinLogoPainter()),
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

  Widget _buildButtons() {
    return Column(
      children: [
        _SocialButton(
          label: '카카오로 시작하기',
          backgroundColor: _kakaoColor,
          textColor: const Color(0xFF3C1E1E),
          customIcon: const _KakaoIcon(size: 20),
          loading: _isLoading,
          onPressed: _handleKakaoLogin,
        ),
        const SizedBox(height: 12),
        _SocialButton(
          label: '네이버로 시작하기',
          backgroundColor: _naverColor,
          textColor: Colors.white,
          customIcon: const _NaverIcon(size: 20),
          loading: _isLoading,
          onPressed: _handleNaverLogin,
        ),
        const SizedBox(height: 12),
        _SocialButton(
          label: '구글로 시작하기',
          backgroundColor: Colors.white,
          textColor: _textDark,
          borderColor: _textDark.withOpacity(0.12),
          customIcon: const _GoogleIcon(size: 20),
          loading: _isLoading,
          onPressed: _handleGoogleLogin,
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(child: Divider(color: _textDark.withOpacity(0.12))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('또는', style: TextStyle(fontSize: 11, color: _textDark.withOpacity(0.4))),
            ),
            Expanded(child: Divider(color: _textDark.withOpacity(0.12))),
          ],
        ),
        const SizedBox(height: 22),
        _SocialButton(
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

// 로고 위젯 - 도넛 + 지도핀 모티프 (기존 그대로 유지)
class _PinLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint pinPaint = Paint()..color = const Color(0xFFE8845A);
    final Paint holePaint = Paint()..color = Colors.white;
    final Paint sprinkleDark = Paint()..color = const Color(0xFF3E2723);
    final Paint sprinklePink = Paint()..color = const Color(0xFFF4A6C0);

    final double w = size.width;
    final double h = size.height;

    final Path pinPath = Path()
      ..moveTo(w * 0.5, h * 0.05)
      ..cubicTo(w * 0.85, h * 0.05, w * 0.95, h * 0.35, w * 0.95, h * 0.5)
      ..cubicTo(w * 0.95, h * 0.75, w * 0.6, h * 0.95, w * 0.5, h * 1.0)
      ..cubicTo(w * 0.4, h * 0.95, w * 0.05, h * 0.75, w * 0.05, h * 0.5)
      ..cubicTo(w * 0.05, h * 0.35, w * 0.15, h * 0.05, w * 0.5, h * 0.05)
      ..close();

    canvas.drawPath(pinPath, pinPaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.42), w * 0.16, holePaint);

    canvas.drawCircle(Offset(w * 0.38, h * 0.3), w * 0.035, sprinkleDark);
    canvas.drawCircle(Offset(w * 0.62, h * 0.28), w * 0.035, sprinklePink);
    canvas.drawCircle(Offset(w * 0.68, h * 0.45), w * 0.035, sprinkleDark);
    canvas.drawCircle(Offset(w * 0.33, h * 0.5), w * 0.035, sprinklePink);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 🌟 카카오 말풍선 아이콘 - 꼬리가 달린 비대칭 말풍선 모양을 직접 그림
class _KakaoIcon extends StatelessWidget {
  final double size;
  const _KakaoIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _KakaoBubblePainter()),
    );
  }
}

class _KakaoBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF3C1E1E);
    final w = size.width;
    final h = size.height;

    final bubble = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h * 0.78),
      Radius.circular(h * 0.4),
    );
    canvas.drawRRect(bubble, paint);

    // 말풍선 꼬리
    final tail = Path()
      ..moveTo(w * 0.22, h * 0.72)
      ..lineTo(w * 0.12, h * 0.98)
      ..lineTo(w * 0.38, h * 0.74)
      ..close();
    canvas.drawPath(tail, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 🌟 네이버 아이콘 - 초록 배경 위 흰색 볼드 "N"
class _NaverIcon extends StatelessWidget {
  final double size;
  const _NaverIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          'N',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.78,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

// 🌟 구글 아이콘 - 파랑/빨강/노랑/초록 4색 "G" 로고를 직접 그림
class _GoogleIcon extends StatelessWidget {
  final double size;
  const _GoogleIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;
    final strokeWidth = w * 0.22;

    final paintBase = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // 4개의 호를 겹치지 않게 나눠서 각 브랜드 색으로 그림 (파랑/초록/노랑/빨강)
    canvas.drawArc(rect, _deg(-40), _deg(100), false, paintBase..color = const Color(0xFF4285F4));
    canvas.drawArc(rect, _deg(60), _deg(70), false, paintBase..color = const Color(0xFF34A853));
    canvas.drawArc(rect, _deg(130), _deg(80), false, paintBase..color = const Color(0xFFFBBC05));
    canvas.drawArc(rect, _deg(210), _deg(110), false, paintBase..color = const Color(0xFFEA4335));

    // 오른쪽 가로 막대 (G의 특징적인 획)
    final barPaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.5, h * 0.42, w * 0.46, h * 0.18),
      barPaint,
    );
  }

  double _deg(double degrees) => degrees * 3.1415926535 / 180;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 소셜 로그인 버튼 공용 위젯 - customIcon(위젯) 또는 icon(IconData) 중 하나를 받음
class _SocialButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final IconData? icon;
  final Widget? customIcon;
  final bool loading;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.loading,
    required this.onPressed,
    this.icon,
    this.customIcon,
    this.borderColor,
  }) : assert(icon != null || customIcon != null, 'icon 또는 customIcon 중 하나는 필요합니다');

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor ?? Colors.transparent),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: loading
            ? SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: textColor),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            customIcon ?? Icon(icon, size: 20, color: textColor),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}