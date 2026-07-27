import 'package:flutter/material.dart';
// TODO: 각 탭 화면 파일 import 필요 (현재는 포인트 조회 탭만 연결)
import 'emoticon/emoticon_tab.dart';
import 'giftcon/gifticon_tab.dart';
import 'point_history/point_history_tab.dart';

class PointMainScreen extends StatelessWidget {
  const PointMainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // 탭 개수
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            '포인트',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
            tabs: [
              Tab(text: '포인트'),
              Tab(text: '이모티콘'),
              Tab(text: '기프티콘'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // 1. 포인트 내역 조회 탭
            PointHistoryTab(),

            // 2. 이모티콘 탭 (추후 구현)
            EmoticonTab(),

            // 3. 기프티콘 탭 (추후 구현)
            GifticonTab()
          ],
        ),
      ),
    );
  }
}