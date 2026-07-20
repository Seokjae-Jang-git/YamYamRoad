import 'package:flutter/material.dart';
import '../repository/mypage_repository.dart';

// 헬퍼 공통 가로 행 위젯
Widget buildListRow(String leftText, String rightText) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        child: Text(
          '• $leftText',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13),
        ),
      ),
      Text(rightText, style: const TextStyle(fontSize: 13, color: Colors.black87)),
    ],
  );
}

// 1. 다이어리 콘텐츠 빌더
Widget buildDiaryContent() {
  return StreamBuilder<List<Map<String, dynamic>>>(
    stream: MypageRepository.getLatestDiaryStream(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))));
      }
      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
        return const Text('작성된 다이어리가 없습니다.', style: TextStyle(color: Colors.grey, fontSize: 13));
      }
      final entries = snapshot.data!;
      return Column(
        children: entries.map((entry) {
          int index = entries.indexOf(entry);
          return Column(
            children: [
              buildListRow(entry['title'], entry['note']),
              if (index < entries.length - 1) const SizedBox(height: 8),
            ],
          );
        }).toList(),
      );
    },
  );
}

// 2. 얌얌북 콘텐츠 빌더
Widget buildYamyamBookContent() {
  return StreamBuilder<List<Map<String, dynamic>>>(
    stream: MypageRepository.getLatestYamyamBookStream(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))));
      }
      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
        return const Text('작성된 얌얌북 피드가 없습니다.', style: TextStyle(color: Colors.grey, fontSize: 13));
      }
      final feeds = snapshot.data!;
      return Column(
        children: feeds.map((feed) {
          int index = feeds.indexOf(feed);
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '• ${feed['content']}',
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (index < feeds.length - 1) const SizedBox(height: 8),
            ],
          );
        }).toList(),
      );
    },
  );
}

// 3. 스탬프 콘텐츠
Widget buildStampContent() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: List.generate(5, (index) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade400)),
        alignment: Alignment.center,
        child: const Text('스탬프', style: TextStyle(fontSize: 10)),
      );
    }),
  );
}

// 4. 뱃지 콘텐츠
Widget buildBadgeContent() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: List.generate(3, (index) {
      return Container(
        margin: const EdgeInsets.only(right: 16),
        width: 50,
        height: 50,
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
        alignment: Alignment.center,
        child: Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
          ),
        ),
      );
    }),
  );
}

// 5. 포인트 콘텐츠
Widget buildPointContent() {
  Widget buildPointBox(String title, String point) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 8),
            Text(point, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      buildPointBox('보유 포인트', '8,000 Point'),
      buildPointBox('충전 포인트', '10,000 Point'),
      buildPointBox('사용 포인트', '2,000 Point'),
    ],
  );
}

// 6. 문의 콘텐츠
Widget buildInquiryContent() {
  return Column(
    children: [
      buildListRow('문의 글 내용.... 오늘은 카페 라떼를....', '답변 대기 중'),
      const SizedBox(height: 8),
      buildListRow('문의 글 내용.... 오늘은 성수동에 유명한....', '답변 완료'),
    ],
  );
}

// 7. 신고 콘텐츠
Widget buildReportContent() {
  return Column(
    children: [
      buildListRow('신고 글 내용.... 오늘은 카페 라떼를....', '처리 대기 중'),
      const SizedBox(height: 8),
      buildListRow('신고 글 내용.... 오늘은 성수동에 유명한....', '처리 완료'),
    ],
  );
}