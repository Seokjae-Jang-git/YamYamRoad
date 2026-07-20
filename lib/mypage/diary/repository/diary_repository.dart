import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../common/user_data.dart';

class DiaryRepository {
  // DB의 날짜 문자열('2026.7.10 0:00')을 DateTime 객체로 변환
  static DateTime parseDateStr(String dateStr) {
    try {
      String cleanDateStr = dateStr.split(' ')[0].replaceAll('.', '-');
      List<String> parts = cleanDateStr.split('-');
      return DateTime.utc(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    } catch (e) {
      return DateTime.utc(2000, 1, 1);
    }
  }

  // 데이터 스트림 통합 로드
  static Stream<List<Map<String, dynamic>>> getDiaryStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(UserData.uid)
        .collection('users_diary_entry')
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> combinedEntries = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> diaryData = doc.data();
        diaryData['diaryId'] = doc.id;

        String storeName = '장소 미지정';
        if (diaryData['placeId'] != null && diaryData['placeId'].toString().isNotEmpty) {
          var placeDoc = await FirebaseFirestore.instance.collection('place').doc(diaryData['placeId']).get();
          if (placeDoc.exists) storeName = placeDoc.data()?['name'] ?? storeName;
        } else if (diaryData['manualStoreName'] != null && diaryData['manualStoreName'].toString().isNotEmpty) {
          storeName = diaryData['manualStoreName'];
        }
        diaryData['storeName'] = storeName;

        String note = '기록된 한줄 평이 없습니다.';
        String time = '00:00';

        if (diaryData['stampId'] != null && diaryData['stampId'].toString().isNotEmpty) {
          var stampDoc = await FirebaseFirestore.instance.collection('stamp').doc(diaryData['stampId']).get();
          if (stampDoc.exists) {
            String dbNote = stampDoc.data()?['oneLineNote'] ?? '';
            note = dbNote.trim().isEmpty ? '기록된 한줄 평이 없습니다.' : dbNote;

            Timestamp? issuedAt = stampDoc.data()?['issuedAt'];
            if (issuedAt != null) time = DateFormat('HH:mm').format(issuedAt.toDate());
          }
        } else {
          String dbNote = diaryData['note'] ?? '';
          note = dbNote.trim().isEmpty ? '기록된 한줄 평이 없습니다.' : dbNote;

          if (diaryData['date'] != null && diaryData['date'].toString().contains(' ')) {
            time = diaryData['date'].toString().split(' ')[1];
          }
        }

        diaryData['note'] = note;
        diaryData['time'] = time;

        combinedEntries.add(diaryData);
      }
      return combinedEntries;
    });
  }

  // 장소 자동완성 검색
  static Future<Iterable<Map<String, dynamic>>> searchPlaces(String query) async {
    if (query.isEmpty) return const Iterable<Map<String, dynamic>>.empty();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('place')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + '\uf8ff')
          .limit(10)
          .get();

      return snapshot.docs.map((doc) => {
        'placeId': doc.id,
        'name': doc.data()['name'] ?? '이름 없음',
      });
    } catch (e) {
      debugPrint("가게 검색 에러: $e");
      return const Iterable<Map<String, dynamic>>.empty();
    }
  }
}