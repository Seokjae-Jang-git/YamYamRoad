import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../common/user_data.dart'; // 실제 경로에 맞게 맞춰주세요.

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({Key? key}) : super(key: key);

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  int _filterType = 0; // 0 = 전체보기, 1 = 스탬프만 보기

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  // 🌟 [유틸 함수] DB의 날짜 문자열('2026.7.10 0:00')을 DateTime 객체로 변환
  DateTime _parseDateStr(String dateStr) {
    try {
      String cleanDateStr = dateStr.split(' ')[0].replaceAll('.', '-');
      List<String> parts = cleanDateStr.split('-');
      return DateTime.utc(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    } catch (e) {
      return DateTime.utc(2000, 1, 1); // 파싱 실패 시 기본값
    }
  }

  // 🌟 1. 하위 컬렉션 경로 반영 및 데이터 조립 스트림
  Stream<List<Map<String, dynamic>>> _getDiaryStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(UserData.uid) // 🌟 특정 유저 문서 접근
        .collection('users_diary_entry') // 🌟 하위 컬렉션 접근!
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> combinedEntries = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> diaryData = doc.data();
        diaryData['diaryId'] = doc.id;

        // 2. placeId를 기반으로 place 마스터에서 가게 이름 조회
        String storeName = '알 수 없는 가게';
        if (diaryData['placeId'] != null && diaryData['placeId'].toString().isNotEmpty) {
          var placeDoc = await FirebaseFirestore.instance
              .collection('place')
              .doc(diaryData['placeId'])
              .get();
          if (placeDoc.exists) {
            storeName = placeDoc.data()?['name'] ?? '테스트카페';
          }
        }
        diaryData['storeName'] = storeName;

        // 3. stampId를 기반으로 한줄 기록 조회
        String note = '기록된 한줄 평이 없습니다.';
        String time = '00:00';
        if (diaryData['stampId'] != null && diaryData['stampId'].toString().isNotEmpty) {
          var stampDoc = await FirebaseFirestore.instance
              .collection('stamp')
              .doc(diaryData['stampId'])
              .get();
          if (stampDoc.exists) {
            note = stampDoc.data()?['oneLineNote'] ?? note;
            Timestamp? issuedAt = stampDoc.data()?['issuedAt'];
            if (issuedAt != null) {
              time = DateFormat('HH:mm').format(issuedAt.toDate());
            }
          }
        }
        diaryData['note'] = note;
        diaryData['time'] = time;

        combinedEntries.add(diaryData);
      }
      return combinedEntries;
    });
  }

  // 🌟 달력 이벤트용 Map 생성 로직 (날짜 밑에 점 찍기용)
  Map<DateTime, List<Map<String, dynamic>>> _groupEntriesByDate(List<Map<String, dynamic>> entries) {
    Map<DateTime, List<Map<String, dynamic>>> dataMap = {};
    for (var entry in entries) {
      DateTime date = _parseDateStr(entry['date']);
      // UTC 자정 기준으로 키를 만들어야 달력과 정확히 매칭됩니다.
      DateTime normalizedDate = DateTime.utc(date.year, date.month, date.day);

      if (dataMap[normalizedDate] == null) {
        dataMap[normalizedDate] = [];
      }
      dataMap[normalizedDate]!.add(entry);
    }
    return dataMap;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('다이어리', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade300, height: 1.0),
        ),
      ),
      // 🌟 화면 전체(달력 + 리스트)를 StreamBuilder로 감싸서 데이터를 한 번만 불러오게 만듭니다.
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getDiaryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }

          final allEntries = snapshot.data ?? [];
          final eventsMap = _groupEntriesByDate(allEntries); // 날짜별 데이터 그룹화

          // 선택된 날짜에 맞는 하단 리스트 필터링
          final filteredList = allEntries.where((entry) {
            DateTime entryDate = _parseDateStr(entry['date']);
            return isSameDay(_selectedDay, entryDate);
          }).toList();

          return Column(
            children: [
              // 1. 필터 및 추가 버튼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildRadioFilter(0, '전체보기'),
                        const SizedBox(width: 16),
                        _buildRadioFilter(1, '스탬프만 보기'),
                      ],
                    ),
                    GestureDetector(
                      onTap: _showAddDialog,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey),
                        ),
                        child: const Icon(Icons.add, size: 20, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. 달력 영역
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

                    // 🌟 날짜 밑에 점(이벤트 마커)을 찍어주는 핵심 코드!
                    eventLoader: (day) {
                      DateTime normalizedDay = DateTime.utc(day.year, day.month, day.day);
                      return eventsMap[normalizedDay] ?? [];
                    },

                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                    calendarStyle: const CalendarStyle(
                      selectedDecoration: BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                      todayDecoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                      // 🌟 이벤트 마커 디자인 (주황색 작은 동그라미)
                      markerDecoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 1, // 하루에 여러 개여도 점은 하나만 표시
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 3. 하단 다이어리 리스트 영역
              Expanded(
                child: filteredList.isEmpty
                    ? const Center(child: Text('작성된 다이어리가 없습니다.', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final entry = filteredList[index];

                    // 필터 적용 (스탬프만 보기)
                    if (_filterType == 1 && (entry['stampId'] == null || entry['stampId'].toString().isEmpty)) {
                      return const SizedBox.shrink();
                    }
                    return _buildDiaryItem(entry);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 필터 라디오 버튼
  Widget _buildRadioFilter(int value, String label) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterType = value;
        });
      },
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey),
            ),
            child: _filterType == value
                ? Center(child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle)))
                : null,
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  // 개별 다이어리 아이템
  Widget _buildDiaryItem(Map<String, dynamic> entry) {
    bool hasStamp = entry['stampId'] != null && entry['stampId'].toString().isNotEmpty;

    return GestureDetector(
      onTap: () => _showEditDialog(entry),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('•', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text(
                  '${entry['date'].split(' ')[0]} ${entry['storeName']}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                if (hasStamp)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: const Text('스탬프', style: TextStyle(fontSize: 8, color: Colors.grey)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text(
                entry['note'],
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ➕ 다이어리 추가 다이얼로그 (users_diary_entry 하위 컬렉션에 추가)
  void _showAddDialog() {
    final TextEditingController noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          titlePadding: const EdgeInsets.only(right: 8, top: 8),
          title: Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• 일시: ${DateFormat('yyyy. MM. dd').format(_selectedDay ?? DateTime.now())}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 16),
              const Text('• 한줄 기록', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400), borderRadius: BorderRadius.zero),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.black), borderRadius: BorderRadius.zero),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () async {
                    if (noteController.text.isNotEmpty) {
                      String dateStr = DateFormat('yyyy.M.d 0:00').format(_selectedDay ?? DateTime.now());

                      // 1. stamp 컬렉션에 한줄평 저장
                      DocumentReference stampRef = await FirebaseFirestore.instance.collection('stamp').add({
                        'userId': UserData.uid,
                        'oneLineNote': noteController.text,
                        'issuedAt': FieldValue.serverTimestamp(),
                      });

                      // 2. 🌟 users/{uid}/users_diary_entry 하위 컬렉션에 메인 기록 저장!
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(UserData.uid)
                          .collection('users_diary_entry')
                          .add({
                        'date': dateStr,
                        'type': 'manual',
                        'stampId': stampRef.id,
                        'placeId': '', // 수동 입력이므로 가게 정보 없음
                        'createdAt': FieldValue.serverTimestamp(),
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                    }
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                    side: BorderSide(color: Colors.grey.shade400),
                  ),
                  child: const Text('저장'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ✏️ 다이어리 수정 다이얼로그
  void _showEditDialog(Map<String, dynamic> entry) {
    final TextEditingController noteController = TextEditingController(text: entry['note']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          titlePadding: const EdgeInsets.only(right: 8, top: 8),
          title: Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• 일시: ${entry['date'].split(' ')[0]}  ${entry['time']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 16),
              const Text('• 한줄 기록', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400), borderRadius: BorderRadius.zero),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.black), borderRadius: BorderRadius.zero),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () async {
                    if (entry['stampId'] != null && entry['stampId'].toString().isNotEmpty) {
                      await FirebaseFirestore.instance
                          .collection('stamp')
                          .doc(entry['stampId'])
                          .update({
                        'oneLineNote': noteController.text,
                        'noteUpdatedAt': FieldValue.serverTimestamp(),
                      });
                    }
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                    side: BorderSide(color: Colors.grey.shade400),
                  ),
                  child: const Text('수정'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}