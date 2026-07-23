import 'package:cloud_firestore/cloud_firestore.dart';
import '../../common/user_data.dart';

class MypageRepository {
  // 다이어리 최신 2개 스트림
  static Stream<List<Map<String, dynamic>>> getLatestDiaryStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(UserData.uid)
        .collection('users_diary_entry')
        .orderBy('createdAt', descending: true)
        .limit(2)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> combinedEntries = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> diaryData = doc.data();

        String storeName = '장소 미지정';
        if (diaryData['placeId'] != null && diaryData['placeId'].toString().isNotEmpty) {
          var placeDoc = await FirebaseFirestore.instance.collection('place').doc(diaryData['placeId']).get();
          if (placeDoc.exists) storeName = placeDoc.data()?['name'] ?? storeName;
        } else if (diaryData['manualStoreName'] != null && diaryData['manualStoreName'].toString().isNotEmpty) {
          storeName = diaryData['manualStoreName'];
        }

        String note = '기록된 한줄 평이 없습니다.';
        if (diaryData['stampId'] != null && diaryData['stampId'].toString().isNotEmpty) {
          var stampDoc = await FirebaseFirestore.instance.collection('stamp').doc(diaryData['stampId']).get();
          if (stampDoc.exists) {
            String dbNote = stampDoc.data()?['oneLineNote'] ?? '';
            note = dbNote.trim().isEmpty ? note : dbNote;
          }
        } else {
          String dbNote = diaryData['note'] ?? '';
          note = dbNote.trim().isEmpty ? note : dbNote;
        }

        String dateStr = diaryData['date']?.toString() ?? '';
        String shortDate = dateStr.split(' ')[0];
        if (shortDate.length >= 4 && shortDate.startsWith('20')) {
          shortDate = shortDate.substring(2).replaceAll('.', '. ');
        }

        combinedEntries.add({
          'title': '$shortDate $storeName',
          'storeName': storeName, // 🌟 UI에서 가게명만 단독으로 뽑아 쓸 수 있도록 키 추가
          'note': note,
        });
      }
      return combinedEntries;
    });
  }

  // 얌얌북 최신 2개 스트림 (인덱스 에러 방지 버전)
  static Stream<List<Map<String, dynamic>>> getLatestYamyamBookStream() {
    return FirebaseFirestore.instance
        .collection('posts')
        .where('userId', isEqualTo: UserData.uid)
        .snapshots()
        .map((snapshot) {
      List<Map<String, dynamic>> items = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'content': data['content'] ?? '내용 없음',
          'likeCount': data['likeCount'] ?? 0,
          'commentCount': data['commentCount'] ?? 0,
          'createdAt': data['createdAt'],
          'status': data['status'] ?? 'active',
        };
      }).toList();

      items = items.where((item) => item['status'] == 'active').toList();

      items.sort((a, b) {
        Timestamp aTime = a['createdAt'] ?? Timestamp.now();
        Timestamp bTime = b['createdAt'] ?? Timestamp.now();
        return bTime.compareTo(aTime);
      });

      return items.take(2).toList();
    });
  }

  // 최신 발행 뱃지 스트림

  static Stream<List<String>> getMyLatest5BadgeIdsStream() {
    final String? uid = UserData.uid;
    if (uid == null || uid.isEmpty) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('users_badge')
        .snapshots()
        .map((snapshot) {
      List<QueryDocumentSnapshot> docs = List.from(snapshot.docs);

      // earnedAt 기준 내림차순 정렬 (최신 획득순)
      docs.sort((a, b) {
        Timestamp? timeA = (a.data() as Map<String, dynamic>)['earnedAt'] as Timestamp?;
        Timestamp? timeB = (b.data() as Map<String, dynamic>)['earnedAt'] as Timestamp?;
        DateTime dtA = timeA?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
        DateTime dtB = timeB?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dtB.compareTo(dtA);
      });

      // 🌟 최신 획득 상위 5개 추출
      return docs
          .take(5)
          .map((d) => (d.data() as Map<String, dynamic>)['badgeId'] as String)
          .toList();
    });
  }
}