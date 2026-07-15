import 'package:flutter/material.dart';
import 'yamyam_home/main_home_screen.dart'; // road 폴더 아래의 메인 홈 스크린 임포트

void main() {
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