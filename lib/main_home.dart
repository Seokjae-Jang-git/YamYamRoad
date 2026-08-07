import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // 🌟 kDebugMode 사용을 위해 필수
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:firebase_app_check/firebase_app_check.dart';

import 'yamyam_home/main_home_screen.dart';
import 'common/user_data.dart';
import 'firebase_options.dart';

// 🌟 로그인 판별을 위해 필요한 파일 임포트
import 'login/login_screen.dart';
import 'services/auth_service.dart';

// 🌟 위치 상태 관리를 위한 Provider 임포트
import 'providers/user_location_provider.dart';

void main() async {
  // 1. 플러터 프레임워크 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 2. .env 환경변수 로드
  await dotenv.load(fileName: ".env");

  // 3. 파이어베이스 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 4. App Check 초기화 (MainActivity.kt 설정과 동기화)
  if (kDebugMode) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
  } else {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.deviceCheck,
    );
  }

  // 5. 구글 애드몹 초기화
  await MobileAds.instance.initialize();

  // 6. 카카오 SDK 초기화
  kakao.KakaoSdk.init(
    nativeAppKey: dotenv.env['KAKAO_APP_KEY'] ?? '',
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Colors.black),
              ),
            );
          }

          // 로그인 상태 확인 후 화면 분기
          if (snapshot.hasData && snapshot.data != null) {
            UserData.uid = snapshot.data!.uid;
            return const MainHomeScreen();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}