import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // 🚀 AdMob SDK 임포트 추가
import 'yamyam_home/main_home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'common/user_data.dart';
import 'firebase_options.dart';

// 🌟 로그인 판별을 위해 필요한 파일 임포트
import 'login/login_screen.dart';
import 'services/auth_service.dart';

// 🌟 위치 상태 관리를 위한 Provider 임포트
import 'providers/user_location_provider.dart';

void main() async {
  // 1. 플러터 프레임워크가 완전히 준비될 때까지 기다립니다.
  WidgetsFlutterBinding.ensureInitialized();

  // 2. .env 환경변수 파일 로드
  await dotenv.load(fileName: ".env");

  // 3. 파이어베이스 엔진 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 4. 구글 애드몹 SDK 엔진 초기화 🚀
  await MobileAds.instance.initialize();

  // 카카오 SDK 초기화 - 반드시 앱 시작 시 한 번 호출해야 함
  kakao.KakaoSdk.init(
    nativeAppKey: '069a7990957fdbe501532762273b49dc', // 카카오 개발자센터에서 발급받은 값
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserLocationProvider()..initializeLocation(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YamYam Road',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: AuthService.authStateChanges,
        builder: (context, snapshot) {
          debugPrint('🟣 [StreamBuilder] state=${snapshot.connectionState}, hasData=${snapshot.hasData}, uid=${snapshot.data?.uid}');

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: Colors.black)),
            );
          }

          // 🌟 [핵심 보완] 로그인 데이터가 존재한다면!
          if (snapshot.hasData && snapshot.data != null) {
            // ➔ 하위 화면들이 내 데이터를 정상 조회할 수 있도록 전역 UID를 먼저 심어줍니다!
            UserData.uid = snapshot.data!.uid;

            return const MainHomeScreen();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}