import 'package:flutter/material.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_service.dart';

import '../road/main_home_screen.dart';

// [네이티브 설정 필요]
//   - Android: AndroidManifest.xml에 카카오/네이버 키 해시, 스킴 등록
//   - iOS: Info.plist에 URL Scheme, 카카오/네이버 앱 키 등록
//   - Firebase 프로젝트에 google-services.json / GoogleService-Info.plist 추가
// ============================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color bgColor = Color(0xFFF4FAF6); // 바깥 배경 (연한 민트)
  static const Color cardColor = Color(0xFFFFFDF9); // 카드 배경 (아이보리)
  static const Color textDark = Color(0xFF3E2723);
  static const Color kakaoColor = Color(0xFFFEE500);
  static const Color naverColor = Color(0xFF03C75A);

  bool _isLoading = false;

  // ▼ 추가: 싱글톤 인스턴스 + 초기화 여부 플래그
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleSignInReady = false;

  @override
  void initState() {
    super.initState();
    _initGoogleSignIn();
  }

  // ▼ 추가: 앱 시작 시 한 번만 initialize
  Future<void> _initGoogleSignIn() async {
    try {
      await _googleSignIn.initialize(
        // iOS/macOS를 지원한다면 clientId 지정 필요
        // clientId: 'YOUR_IOS_CLIENT_ID',
        // 서버 인증(백엔드 검증)이 필요하면 serverClientId 지정
        // serverClientId: 'YOUR_WEB_CLIENT_ID',
      );
      _googleSignInReady = true;
    } catch (e) {
      // 초기화 실패는 조용히 두고, 실제 로그인 시도 시 다시 처리
    }
  }

  void _setLoading(bool value) {
    if (mounted) setState(() => _isLoading = value);
  }

  // ---------------- 카카오 로그인 ----------------
  Future<void> _handleKakaoLogin() async {
    _setLoading(true);
    try {
      bool isInstalled = await isKakaoTalkInstalled();
      OAuthToken token = isInstalled
          ? await UserApi.instance.loginWithKakaoTalk()
          : await UserApi.instance.loginWithKakaoAccount();

      User kakaoUser = await UserApi.instance.me();
      final socialId = kakaoUser.id.toString();

      final userModel = await AuthService.loginWithKakao(
        socialId: socialId,
        nickname: kakaoUser.kakaoAccount?.profile?.nickname,
        profileImageUrl: kakaoUser.kakaoAccount?.profile?.profileImageUrl,
      );

      LocalAuthState.isLoggedIn = true;
      LocalAuthState.profileImageUrl = userModel.profileImageUrl;

      await _mockSocialDelay();
      _goToHome();
    } catch (e) {
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
      if (result.status == NaverLoginStatus.loggedIn) {
        final account = result.account;
        if (account?.id == null) {
          _showError('네이버 계정 정보를 가져오지 못했습니다.');
          return;
        }

        final userModel = await AuthService.loginWithNaver(
          socialId: account!.id!,
          name: account.name,
          nickname: account.nickname,
          phone: account.mobile,
          profileImageUrl: account.profileImage,
        );

        LocalAuthState.isLoggedIn = true;
        LocalAuthState.profileImageUrl = userModel.profileImageUrl;
      } else {
        _showError('네이버 로그인이 취소되었습니다.');
        return;
      }

      await _mockSocialDelay();
      _goToHome();
    } catch (e) {
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

      final userModel = await AuthService.loginWithGoogle(
        socialId: account.id,
        name: account.displayName,
        profileImageUrl: account.photoUrl,
      );

      LocalAuthState.isLoggedIn = true;
      LocalAuthState.profileImageUrl = userModel.profileImageUrl;

      await _mockSocialDelay();
      _goToHome();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        _showError('구글 로그인이 취소되었습니다.');
      } else {
        _showError('구글 로그인에 실패했습니다.');
      }
    } catch (e) {
      _showError('구글 로그인에 실패했습니다.');
    } finally {
      _setLoading(false);
    }
  }
  // ---------------- 휴대폰 번호 로그인 ----------------
  void _handlePhoneLogin() {
    // 인증번호 발송 화면으로 이동 (Firebase Phone Auth 등 별도 화면에서 처리)
    Navigator.pushNamed(context, '/login/phone');
  }

  Future<void> _mockSocialDelay() async {
    await Future.delayed(const Duration(seconds: 1));
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
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 로고
                  const _AppLogo(),
                  const SizedBox(height: 14),
                  const Text(
                    '얌얌',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '동네 빵지순례, 얌얌과 함께',
                    style: TextStyle(fontSize: 13, color: textDark.withOpacity(0.55)),
                  ),

                  const SizedBox(height: 36),

                  // 카카오 로그인
                  _SocialButton(
                    label: '카카오로 시작하기',
                    backgroundColor: kakaoColor,
                    textColor: const Color(0xFF3C1E1E),
                    icon: Icons.chat_bubble_rounded,
                    loading: _isLoading,
                    onPressed: _handleKakaoLogin,
                  ),
                  const SizedBox(height: 10),

                  // 네이버 로그인
                  _SocialButton(
                    label: '네이버로 시작하기',
                    backgroundColor: naverColor,
                    textColor: Colors.white,
                    icon: Icons.abc, // TODO: 네이버 N 로고 asset으로 교체 권장
                    loading: _isLoading,
                    onPressed: _handleNaverLogin,
                  ),
                  const SizedBox(height: 10),

                  // 구글 로그인
                  _SocialButton(
                    label: '구글로 시작하기',
                    backgroundColor: Colors.white,
                    textColor: textDark,
                    borderColor: textDark.withOpacity(0.12),
                    icon: Icons.g_mobiledata_rounded,
                    loading: _isLoading,
                    onPressed: _handleGoogleLogin,
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(child: Divider(color: textDark.withOpacity(0.12))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '또는',
                          style: TextStyle(fontSize: 11, color: textDark.withOpacity(0.4)),
                        ),
                      ),
                      Expanded(child: Divider(color: textDark.withOpacity(0.12))),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 휴대폰 번호 로그인
                  _SocialButton(
                    label: '휴대폰 번호로 시작하기',
                    backgroundColor: Colors.white,
                    textColor: textDark,
                    borderColor: textDark.withOpacity(0.12),
                    icon: Icons.phone_iphone_rounded,
                    loading: false,
                    onPressed: _handlePhoneLogin,
                  ),

                  const SizedBox(height: 24),

                  Text(
                    '계속 진행 시 얌얌의 이용약관과\n개인정보처리방침에 동의하게 됩니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: textDark.withOpacity(0.4), height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 로고 위젯 - 도넛 + 지도핀 모티프
// 실제 디자인 asset이 있다면 Image.asset('assets/images/logo.png')로 교체 권장
class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: CustomPaint(
        painter: _PinLogoPainter(),
      ),
    );
  }
}

class _PinLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint pinPaint = Paint()..color = const Color(0xFFE8845A);
    final Paint holePaint = Paint()..color = const Color(0xFFF4FAF6);
    final Paint sprinkleDark = Paint()..color = const Color(0xFF3E2723);
    final Paint sprinklePink = Paint()..color = const Color(0xFFF4A6C0);

    final double w = size.width;
    final double h = size.height;

    // 핀(물방울) 모양
    final Path pinPath = Path()
      ..moveTo(w * 0.5, h * 0.05)
      ..cubicTo(w * 0.85, h * 0.05, w * 0.95, h * 0.35, w * 0.95, h * 0.5)
      ..cubicTo(w * 0.95, h * 0.75, w * 0.6, h * 0.95, w * 0.5, h * 1.0)
      ..cubicTo(w * 0.4, h * 0.95, w * 0.05, h * 0.75, w * 0.05, h * 0.5)
      ..cubicTo(w * 0.05, h * 0.35, w * 0.15, h * 0.05, w * 0.5, h * 0.05)
      ..close();

    canvas.drawPath(pinPath, pinPaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.42), w * 0.16, holePaint);

    // 스프링클 점
    canvas.drawCircle(Offset(w * 0.38, h * 0.3), w * 0.035, sprinkleDark);
    canvas.drawCircle(Offset(w * 0.62, h * 0.28), w * 0.035, sprinklePink);
    canvas.drawCircle(Offset(w * 0.68, h * 0.45), w * 0.035, sprinkleDark);
    canvas.drawCircle(Offset(w * 0.33, h * 0.5), w * 0.035, sprinklePink);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 소셜 로그인 버튼 공용 위젯
class _SocialButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  final IconData icon;
  final bool loading;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.loading,
    required this.onPressed,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor ?? Colors.transparent),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            Icon(icon, size: 18, color: textColor),
            const SizedBox(width: 8),
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
