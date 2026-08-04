import 'package:flutter/material.dart';

import 'emoticon/emoticon_tab.dart';
import 'giftcon/gifticon_tab.dart';
import 'point_history/point_history_tab.dart';

class PointMainScreen extends StatefulWidget {
  const PointMainScreen({Key? key}) : super(key: key);

  @override
  State<PointMainScreen> createState() => _PointMainScreenState();
}

class _PointMainScreenState extends State<PointMainScreen> {
  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color creamyIvory = Color(0xFFFFFDF9);
  static const Color subTextColor = Color(0xFF7A6B63);

  // 🌟 각 탭의 스크롤을 제어할 컨트롤러 생성
  final ScrollController _pointScrollController = ScrollController();
  final ScrollController _gifticonScrollController = ScrollController();

  @override
  void dispose() {
    _pointScrollController.dispose();
    _gifticonScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: creamyIvory,
        appBar: AppBar(
          backgroundColor: creamyIvory,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: deepChocolate, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            '포인트',
            style: TextStyle(
              color: deepChocolate,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
          bottom: TabBar(
            onTap: (index) {
              // 🌟 현재 선택된 탭을 다시 눌렀을 때 최상단 이동 처리
              if (index == 0 && _pointScrollController.hasClients) {
                _pointScrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              } else if (index == 2 && _gifticonScrollController.hasClients) {
                _gifticonScrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            },
            labelColor: pointCoralRed,
            unselectedLabelColor: subTextColor,
            indicatorColor: pointCoralRed,
            indicatorWeight: 3.0,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: deepChocolate.withOpacity(0.12),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            tabs: const [
              Tab(text: '포인트'),
              Tab(text: '이모티콘'),
              Tab(text: '기프티콘'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            PointHistoryTab(scrollController: _pointScrollController),
            const EmoticonTab(),
            // 🌟 컨트롤러 주입
            GifticonTab(scrollController: _gifticonScrollController),
          ],
        ),
      ),
    );
  }
}