import 'package:flutter/material.dart';
import 'yamyam_home/main_home_screen.dart'; // road 폴더 아래의 메인 홈 스크린 임포트
import 'package:firebase_core/firebase_core.dart'; // 🌟 파이어베이스 코어 패키지 추가
import 'firebase_options.dart';

// 🌟 로그인 판별을 위해 필요한 두 파일 임포트 추가
import 'login/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  // 🌟 1. 플러터 프레임워크가 완전히 준비될 때까지 기다립니다.
  WidgetsFlutterBinding.ensureInitialized();

  // 🌟 2. 내 PC에 설정된 파이어베이스 옵션값으로 엔진에 시동을 겁니다!
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
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
      // 🌟 3. 처음 화면을 고정하지 않고, FutureBuilder로 로그인 상태를 먼저 묻습니다.
      home: FutureBuilder(
        future: AuthService.getCurrentUser(),
        builder: (context, snapshot) {
          // 데이터를 기다리는 아주 짧은 찰나에는 기본 로딩을 보여줍니다.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.black)));
          }

          // 로그인 데이터가 존재한다면 바로 홈 화면으로 보냅니다.
          if (snapshot.hasData && snapshot.data != null) {
            return const MainHomeScreen();
          }

          // 그 외의 경우(비로그인 상태)에는 로그인 화면을 띄웁니다.
          return const LoginScreen();
        },
      ),
    );
  }
}