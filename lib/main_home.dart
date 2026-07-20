import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart'; // 👈 네이버 지도 패키지 추가
import 'yamyam_home/main_home_screen.dart'; // 기존 임포트 경로 유지
import 'firebase_options.dart';

void main() async {
  // 1. 플러터 프레임워크가 완전히 준비될 때까지 기다립니다.
  WidgetsFlutterBinding.ensureInitialized();

  // 2. .env 환경변수 파일 로드
  await dotenv.load(fileName: ".env");

  // 3. 파이어베이스 엔진 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 4. 네이버 지도 SDK 초기화 (AndroidManifest의 Client ID 사용)
  await NaverMapSdk.instance.initialize(
    clientId: '8lra5wnbp9',
    onAuthFailed: (ex) {
      debugPrint("네이버 지도 인증 실패: $ex");
    },
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
      home: const MainHomeScreen(),
    );
  }
}