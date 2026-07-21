import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'repository/diary_repository.dart';
import 'widgets/diary_add_dialog.dart';
import 'widgets/diary_edit_dialog.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({Key? key}) : super(key: key);

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int _filterType = 0;

  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Map<DateTime, List<Map<String, dynamic>>> _groupEntriesByDate(List<Map<String, dynamic>> entries) {
    Map<DateTime, List<Map<String, dynamic>>> dataMap = {};
    for (var entry in entries) {
      DateTime date = DiaryRepository.parseDateStr(entry['date']);
      DateTime normalizedDate = DateTime.utc(date.year, date.month, date.day);

      if (dataMap[normalizedDate] == null) {
        dataMap[normalizedDate] = [];
      }
      dataMap[normalizedDate]!.add(entry);
    }
    return dataMap;
  }

  void _scrollToDate(DateTime date, List<Map<String, dynamic>> filteredList) {
    int targetIndex = filteredList.indexWhere((entry) {
      DateTime entryDate = DiaryRepository.parseDateStr(entry['date']);
      return isSameDay(date, entryDate);
    });

    if (targetIndex != -1) {
      final targetEntry = filteredList[targetIndex];
      final targetKey = _itemKeys[targetEntry['diaryId']];

      if (targetKey != null && targetKey.currentContext != null) {
        Scrollable.ensureVisible(
          targetKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    } else {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('해당 날짜에 작성된 기록이 없습니다.'), duration: Duration(seconds: 1)),
      );
    }
  }

  void _showAddDialog() => showDialog(context: context, builder: (context) => DiaryAddDialog(initialDate: _selectedDay ?? DateTime.now()));
  void _showEditDialog(Map<String, dynamic> entry) => showDialog(context: context, builder: (context) => DiaryEditDialog(entry: entry));

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
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: DiaryRepository.getDiaryStream(),
        builder: (context, snapshot) {
          // 🌟 [핵심 수정 1]
          // 로딩 상태(waiting)이더라도 기존 데이터(snapshot.hasData)가 있다면 로딩 스피너를 띄우지 않습니다.
          // 오직 앱을 처음 켰을 때(데이터가 아예 없을 때)만 로딩 스피너를 보여줍니다.
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }

          final allEntries = snapshot.data ?? [];
          final eventsMap = _groupEntriesByDate(allEntries);

          List<Map<String, dynamic>> monthlyEntries = allEntries.where((entry) {
            DateTime entryDate = DiaryRepository.parseDateStr(entry['date']);
            return entryDate.year == _focusedDay.year && entryDate.month == _focusedDay.month;
          }).toList();

          monthlyEntries.sort((a, b) {
            DateTime aTime = DiaryRepository.parseDateStr(a['date']);
            DateTime bTime = DiaryRepository.parseDateStr(b['date']);
            return aTime.compareTo(bTime);
          });

          final displayList = monthlyEntries.where((entry) {
            if (_filterType == 1 && (entry['stampId'] == null || entry['stampId'].toString().isEmpty)) return false;
            return true;
          }).toList();

          return Column(
            children: [
              // 1. 필터 영역
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
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey)),
                        child: const Icon(Icons.add, size: 20, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. 캘린더 영역
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    eventLoader: (day) {
                      DateTime normalizedDay = DateTime.utc(day.year, day.month, day.day);
                      return eventsMap[normalizedDay] ?? [];
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      // 🌟 [핵심 수정 2]
                      // setState로 날짜가 바뀔 때 달력이 즉시 리빌드되므로
                      // 렌더링이 완전히 완료된 후 스크롤을 부드럽게 이동시킵니다.
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToDate(selectedDay, displayList);
                      });
                    },
                    onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
                    onFormatChanged: (format) => setState(() => _calendarFormat = format),
                    headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                    calendarStyle: const CalendarStyle(
                      selectedDecoration: BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                      todayDecoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                      markerDecoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                      markersMaxCount: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. 리스트 영역
              Expanded(
                child: displayList.isEmpty
                    ? const Center(child: Text('이번 달에 작성된 다이어리가 없습니다.', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 450.0),
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    final entry = displayList[index];
                    final String diaryId = entry['diaryId'] ?? '';

                    if (!_itemKeys.containsKey(diaryId)) {
                      _itemKeys[diaryId] = GlobalKey();
                    }

                    DateTime entryDate = DiaryRepository.parseDateStr(entry['date']);
                    bool isTargetHighlight = isSameDay(_selectedDay, entryDate);

                    return AnimatedContainer(
                      key: _itemKeys[diaryId],
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: isTargetHighlight ? Colors.orange.shade50.withOpacity(0.5) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _buildDiaryItem(entry),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRadioFilter(int value, String label) {
    return GestureDetector(
      onTap: () => setState(() => _filterType = value),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey)),
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

  Widget _buildDiaryItem(Map<String, dynamic> entry) {
    bool hasStamp = entry['stampId'] != null && entry['stampId'].toString().isNotEmpty;
    return GestureDetector(
      onTap: () => _showEditDialog(entry),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('•', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text('${entry['date'].split(' ')[0]} ${entry['storeName']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                if (hasStamp)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
                    child: const Text('스탬프', style: TextStyle(fontSize: 8, color: Colors.grey)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text(entry['note'], style: const TextStyle(fontSize: 14, color: Colors.black87)),
            ),
          ],
        ),
      ),
    );
  }
}