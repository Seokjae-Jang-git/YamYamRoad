import 'package:flutter/material.dart';
import 'road/main_home_screen.dart'; // road 폴더 아래의 메인 홈 스크린 임포트
import 'package:firebase_core/firebase_core.dart'; // 🌟 파이어베이스 코어 패키지 추가
import 'firebase_options.dart';

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
      title: 'YamYam Map',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const MainHomeScreen(),
    );
  }
}