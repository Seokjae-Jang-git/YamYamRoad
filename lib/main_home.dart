import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'yamyam_home/main_home_screen.dart'; // road 폴더 아래의 메인 홈 스크린 임포트
import 'package:firebase_core/firebase_core.dart'; // 🌟 파이어베이스 코어 패키지 추가
import 'firebase_options.dart';

void main() async {
  // 🌟 1. 플러터 프레임워크가 완전히 준비될 때까지 기다립니다.
  WidgetsFlutterBinding.ensureInitialized();

  // 🌟 2. 내 PC에 설정된 파이어베이스 옵션값으로 엔진에 시동을 겁니다!
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 카카오 SDK 초기화 - 반드시 앱 시작 시 한 번 호출해야 함
  kakao.KakaoSdk.init(
    nativeAppKey: '069a7990957fdbe501532762273b49dc', // 카카오 개발자센터에서 발급받은 값
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