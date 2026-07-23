import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../common/user_data.dart';
import '../repository/mypage_repository.dart';
import '../stamp/repository/stamp_repository.dart';

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
              // 🌟 [핵심 수정] 없는 필드인 'title' 대신 'storeName'을 사용하고 null 처리를 합니다!
              buildListRow(
                entry['storeName'] ?? '가게명 없음',
                entry['note'] ?? '내용 없음',
              ),
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

// 3. 스탬프 콘텐츠 (최근 수집한 스탬프 5개 연동)
Widget buildStampContent() {
  return StreamBuilder<List<Map<String, dynamic>>>(
    stream: StampRepository.getMyLatest5StampsStream(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const SizedBox(
          height: 55,
          child: Center(child: CircularProgressIndicator(color: Colors.orange, strokeWidth: 2)),
        );
      }

      final fetchedStamps = snapshot.data ?? [];

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(5, (index) {
          // 수집한 스탬프 데이터가 존재하면 도장 표시, 없으면 빈 슬롯 표시
          if (index < fetchedStamps.length) {
            final stamp = fetchedStamps[index];
            final String storeName = stamp['storeName'] ?? '매장';

            String dateStr = '';
            if (stamp['issuedAt'] != null) {
              final DateTime dt = (stamp['issuedAt'] as Timestamp).toDate();
              dateStr = DateFormat('yy.MM.dd').format(dt);
            }

            // 🌟 획득한 스탬프 (빨간 도장 스타일)
            return Transform.rotate(
              angle: -0.1, // 비스듬하게 찍힌 도장 느낌
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red.shade700, width: 1.8),
                  color: Colors.red.shade50.withOpacity(0.3),
                ),
                padding: const EdgeInsets.all(2),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 7.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            // 🌟 아직 미수집된 빈 스탬프 슬롯
            return Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 1.2),
                color: Colors.grey.shade50,
              ),
              alignment: Alignment.center,
              child: Icon(Icons.add, size: 18, color: Colors.grey.shade400),
            );
          }
        }),
      );
    },
  );
}

// 4. 뱃지 콘텐츠 (최근 발급받은 뱃지 5개 가로 정렬)
Widget buildBadgeContent() {
  return StreamBuilder<List<String>>(
    stream: MypageRepository.getMyLatest5BadgeIdsStream(),
    builder: (context, badgeIdsSnapshot) {
      if (badgeIdsSnapshot.connectionState == ConnectionState.waiting) {
        return const SizedBox(
          height: 52,
          child: Center(child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)),
        );
      }

      final badgeIds = badgeIdsSnapshot.data ?? [];

      if (badgeIds.isEmpty) {
        return const Text('획득한 뱃지가 없습니다.', style: TextStyle(color: Colors.grey, fontSize: 13));
      }

      return FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchBadgeDetails(badgeIds),
        builder: (context, badgeSnapshot) {
          if (badgeSnapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 52,
              child: Center(child: CircularProgressIndicator(color: Colors.black, strokeWidth: 1.5)),
            );
          }

          final badges = badgeSnapshot.data ?? [];

          // 🌟 5개 항목을 공간에 맞춰 균등 배치 (스탬프와 동일한 스타일)
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (index) {
              if (index < badges.length) {
                final badge = badges[index];
                return SizedBox(
                  width: 52,
                  height: 52,
                  child: Image.network(
                    badge['imageUrl'],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, color: Colors.grey, size: 30),
                  ),
                );
              } else {
                // 획득한 뱃지가 5개 미만일 때의 빈 슬롯
                return Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 1.2),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade50,
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.workspace_premium, size: 20, color: Colors.grey.shade300),
                );
              }
            }),
          );
        },
      );
    },
  );
}

// 뱃지 상세 정보 조회 헬퍼 함수
Future<List<Map<String, dynamic>>> _fetchBadgeDetails(List<String> badgeIds) async {
  List<Map<String, dynamic>> details = [];
  for (String bId in badgeIds) {
    final doc = await FirebaseFirestore.instance.collection('badge').doc(bId).get();
    if (doc.exists && doc.data()?['isActive'] == true) {
      details.add({
        'id': bId,
        'imageUrl': doc.data()?['imageUrl'] ?? '',
        'name': doc.data()?['name'] ?? '',
      });
    }
  }
  return details;
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