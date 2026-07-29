import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../common/user_data.dart';
import '../../services/auth_service.dart';
import '../repository/mypage_repository.dart';
import '../stamp/repository/stamp_repository.dart';
import 'package:flutter_svg/flutter_svg.dart';

// YamYamRoad 브랜드 공식 컬러 상수
const Color deepChocolate = Color(0xFF4A3225);
const Color subTextColor = Color(0xFF7A6B63);
const Color cardBorderColor = Color(0xFFEFE8E0);
const Color coralRed = Color(0xFFFF5B45);
const Color lightBgColor = Color(0xFFFFF4F2);
const Color emptySlotColor = Color(0xFFFFFBF8);

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
          style: const TextStyle(
            fontSize: 13,
            color: deepChocolate,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      Text(
        rightText,
        style: const TextStyle(
          fontSize: 13,
          color: subTextColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

Widget _buildYamyambookPreviewText(String content) {
  final RegExp emojiRegex = RegExp(r'\[emoji:(.*?)\]');
  final Iterable<RegExpMatch> matches = emojiRegex.allMatches(content);

  // 이모티콘이 없으면 일반 텍스트 반환
  if (matches.isEmpty) {
    return Text(
      '• $content',
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  List<InlineSpan> spans = [];
  int currentIndex = 0;

  for (final match in matches) {
    if (match.start > currentIndex) {
      spans.add(TextSpan(text: content.substring(currentIndex, match.start)));
    }

    final String rawEmojiPath = match.group(1) ?? '';

    // 🌟 FeedCardWidget과 동일한 경로 치환 로직 적용
    String cleanPath = rawEmojiPath.replaceAll(':', '/');
    cleanPath = cleanPath.replaceAll('emo_character_test', 'character');
    cleanPath = cleanPath.replaceAll('emo_emoji_test', 'emoji');
    cleanPath = cleanPath.replaceAll('emo_penguin_test', 'penguin');
    cleanPath = cleanPath.replaceAll('emo_meme_test', 'meme');
    cleanPath = cleanPath.replaceAll('emo_cloud_test', 'cloud');

    spans.add(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.0),
          child: SvgPicture.asset(
            'assets/emoticons/$cleanPath',
            width: 16, // 미리보기 사이즈에 맞게 축소
            height: 16,
          ),
        ),
      ),
    );

    currentIndex = match.end;
  }

  if (currentIndex < content.length) {
    spans.add(TextSpan(text: content.substring(currentIndex)));
  }

  // 🌟 1줄 제한 및 말줄임표 적용된 RichText 반환
  return RichText(
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    text: TextSpan(
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      children: [
        const TextSpan(text: '• '),
        ...spans,
      ],
    ),
  );
}

// 1. 다이어리 콘텐츠 빌더
Widget buildDiaryContent() {
  return StreamBuilder<List<Map<String, dynamic>>>(
    stream: MypageRepository.getLatestDiaryStream(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: deepChocolate, strokeWidth: 2),
            ),
          ),
        );
      }
      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
        return const Text('작성된 다이어리가 없습니다.', style: TextStyle(color: subTextColor, fontSize: 13));
      }
      final entries = snapshot.data!;
      return Column(
        children: entries.map((entry) {
          int index = entries.indexOf(entry);
          return Column(
            children: [
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
        return const Center(
            child: Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
            )
        );
      }
      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
        return const Text('작성된 얌얌북 피드가 없습니다.', style: TextStyle(color: subTextColor, fontSize: 13));
      }

      final feeds = snapshot.data!;

      return Column(
        children: feeds.map((feed) {
          int index = feeds.indexOf(feed);
          final String rawContent = feed['content']?.toString() ?? '';

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    // 🌟 수정된 부분: 파싱 헬퍼 함수 사용
                    child: _buildYamyambookPreviewText(rawContent),
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
          child: Center(child: CircularProgressIndicator(color: coralRed, strokeWidth: 2)),
        );
      }

      final fetchedStamps = snapshot.data ?? [];

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(5, (index) {
          if (index < fetchedStamps.length) {
            final stamp = fetchedStamps[index];
            final String storeName = stamp['storeName'] ?? '매장';

            String dateStr = '';
            if (stamp['issuedAt'] != null) {
              final DateTime dt = (stamp['issuedAt'] as Timestamp).toDate();
              dateStr = DateFormat('yy.MM.dd').format(dt);
            }

            // 획득한 스탬프 (브랜드 코랄 레드 도장 스타일)
            return Transform.rotate(
              angle: -0.1,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: coralRed, width: 2.0),
                  color: lightBgColor,
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
                      style: const TextStyle(
                        color: coralRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: coralRed.withOpacity(0.85),
                        fontSize: 7.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            // 미수집된 빈 스탬프 슬롯
            return Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: cardBorderColor, width: 1.2),
                color: emptySlotColor,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.add, size: 18, color: subTextColor),
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
          child: Center(child: CircularProgressIndicator(color: deepChocolate, strokeWidth: 2)),
        );
      }

      final badgeIds = badgeIdsSnapshot.data ?? [];

      if (badgeIds.isEmpty) {
        return const Text('획득한 뱃지가 없습니다.', style: TextStyle(color: subTextColor, fontSize: 13));
      }

      return FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchBadgeDetails(badgeIds),
        builder: (context, badgeSnapshot) {
          if (badgeSnapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 52,
              child: Center(child: CircularProgressIndicator(color: deepChocolate, strokeWidth: 1.5)),
            );
          }

          final badges = badgeSnapshot.data ?? [];

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
                    const Icon(Icons.broken_image, color: subTextColor, size: 30),
                  ),
                );
              } else {
                return Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    border: Border.all(color: cardBorderColor, width: 1.2),
                    borderRadius: BorderRadius.circular(10),
                    color: emptySlotColor,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.workspace_premium, size: 20, color: subTextColor),
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

// 5. 포인트 콘텐츠 (실시간 DB 연동 + 거래 내역 기반 누적 집계)
Widget buildPointContent(BuildContext context) {
  final String uid = UserData.uid ?? '';

  if (uid.isEmpty) {
    return const Text('로그인 정보가 없습니다.', style: TextStyle(color: subTextColor, fontSize: 13));
  }

  final numberFormat = NumberFormat('#,###');

  num parseToNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  Widget buildPointBox(String title, String point) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: emptySlotColor,
          border: Border.all(color: cardBorderColor, width: 1.0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: subTextColor, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(point, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: deepChocolate)),
          ],
        ),
      ),
    );
  }

  return StreamBuilder<DocumentSnapshot>(
    stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
    builder: (context, userSnapshot) {
      if (userSnapshot.connectionState == ConnectionState.waiting) {
        return const SizedBox(
          height: 60,
          child: Center(child: CircularProgressIndicator(color: deepChocolate, strokeWidth: 2)),
        );
      }

      num paidPoint = 0;
      num freePoint = 0;

      if (userSnapshot.hasData && userSnapshot.data!.exists) {
        final userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
        paidPoint = parseToNum(userData['paidPointBalance']);
        freePoint = parseToNum(userData['freePointBalance']);
      }

      final num totalBalance = paidPoint + freePoint;

      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('users_point_transaction')
            .snapshots(),
        builder: (context, txSnapshot) {
          num totalChargedPoint = 0;
          num totalUsedPoint = 0;

          if (txSnapshot.hasData && txSnapshot.data!.docs.isNotEmpty) {
            for (var doc in txSnapshot.data!.docs) {
              final txData = doc.data() as Map<String, dynamic>;
              final num amount = parseToNum(txData['amount']);

              if (amount > 0) {
                totalChargedPoint += amount;
              } else if (amount < 0) {
                totalUsedPoint += amount.abs();
              }
            }
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildPointBox('보유 포인트', '${numberFormat.format(totalBalance)} P'),
              buildPointBox('충전 포인트', '${numberFormat.format(totalChargedPoint)} P'),
              buildPointBox('사용 포인트', '${numberFormat.format(totalUsedPoint)} P'),
            ],
          );
        },
      );
    },
  );
}

// 문의 DB 상태값을 화면용 한글로 변환하는 함수
String _getInquiryDisplayStatus(String status) {
  switch (status.trim().toLowerCase()) {
    case 'pending':
      return '답변 대기';
    case 'answered':
      return '답변 완료';
    case 'closed':
      return '종료';
    default:
      return status;
  }
}

// 6. 문의 콘텐츠 (실시간 데이터 연동)
Widget buildInquiryContent() {
  final String currentUserId = AuthService.currentUser?.uid ?? UserData.uid ?? '';

  if (currentUserId.isEmpty) {
    return const SizedBox.shrink();
  }

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('inquiry')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .limit(2)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator(color: deepChocolate)),
        );
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Text(
              '최근 접수된 문의 내역이 없습니다.',
              style: TextStyle(color: subTextColor, fontSize: 13),
            ),
          ),
        );
      }

      final docs = snapshot.data!.docs;

      return Column(
        children: List.generate(docs.length, (index) {
          final data = docs[index].data() as Map<String, dynamic>;
          final String inquiryId = docs[index].id;
          final String rawStatus = data['status'] ?? 'pending';

          final String displayStatus = _getInquiryDisplayStatus(rawStatus);

          return Padding(
            padding: EdgeInsets.only(bottom: index == docs.length - 1 ? 0 : 8.0),
            child: buildListRow('문의번호: $inquiryId', displayStatus),
          );
        }),
      );
    },
  );
}

// DB 상태값을 화면용 한글로 변환하는 함수
String _getDisplayStatus(String status) {
  switch (status.trim().toLowerCase()) {
    case 'pending':
      return '접수 완료';
    case 'in_review':
      return '처리 중';
    case 'completed':
      return '처리 완료';
    default:
      return status;
  }
}

// 7. 신고 콘텐츠 (실시간 데이터 연동)
Widget buildReportContent() {
  final String currentUserId = AuthService.currentUser?.uid ?? UserData.uid ?? '';

  if (currentUserId.isEmpty) {
    return const SizedBox.shrink();
  }

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('reports')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .limit(2)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator(color: deepChocolate)),
        );
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Text(
              '최근 접수된 신고 내역이 없습니다.',
              style: TextStyle(color: subTextColor, fontSize: 13),
            ),
          ),
        );
      }

      final docs = snapshot.data!.docs;

      return Column(
        children: List.generate(docs.length, (index) {
          final data = docs[index].data() as Map<String, dynamic>;
          final String reportId = data['reportId'] ?? docs[index].id;
          final String rawStatus = data['status'] ?? 'pending';

          final String displayStatus = _getDisplayStatus(rawStatus);

          return Padding(
            padding: EdgeInsets.only(bottom: index == docs.length - 1 ? 0 : 8.0),
            child: buildListRow('신고번호: $reportId', displayStatus),
          );
        }),
      );
    },
  );
}