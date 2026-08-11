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
  // 🌟 얌얌로드 공식 컬러 팔레트 적용
  // 🌟 얌얌로드 공식 컬러 팔레트 적용
  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color subStrawberryPink = Color(0xFFFFA09B); // ✅ FF를 추가하여 불투명한 핑크색으로 수정!
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color creamyIvory = Color(0xFFFFFDF9);

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
        SnackBar(
          content: const Text('해당 날짜에 작성된 기록이 없습니다.', style: TextStyle(color: creamyIvory)),
          backgroundColor: deepChocolate,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _showAddDialog() => showDialog(context: context, builder: (context) => DiaryAddDialog(initialDate: _selectedDay ?? DateTime.now()));
  void _showEditDialog(Map<String, dynamic> entry) => showDialog(context: context, builder: (context) => DiaryEditDialog(entry: entry));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamyIvory, // 🌟 전체 배경색 적용
      appBar: AppBar(
        title: const Text('다이어리', style: TextStyle(color: deepChocolate, fontWeight: FontWeight.bold)),
        backgroundColor: creamyIvory,
        elevation: 0,
        iconTheme: const IconThemeData(color: deepChocolate),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: DiaryRepository.getDiaryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: deepChocolate));
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
              // 1. 필터 및 추가 버튼 영역
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: pointCoralRed, // 🌟 얌얌로드 포인트 컬러
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: pointCoralRed.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add, size: 20, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. 캘린더 영역 (마이페이지 카드 스타일 적용)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: deepChocolate.withOpacity(0.12)),
                    boxShadow: [
                      BoxShadow(
                        color: deepChocolate.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
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
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(color: deepChocolate, fontSize: 16, fontWeight: FontWeight.bold),
                      leftChevronIcon: Icon(Icons.chevron_left, color: deepChocolate),
                      rightChevronIcon: Icon(Icons.chevron_right, color: deepChocolate),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: const TextStyle(color: deepChocolate),
                      weekendStyle: const TextStyle(color: pointCoralRed), // 🌟 주말은 포인트 컬러
                    ),
                    calendarStyle: CalendarStyle(
                      defaultTextStyle: const TextStyle(color: deepChocolate),
                      weekendTextStyle: const TextStyle(color: pointCoralRed),
                      outsideTextStyle: TextStyle(color: deepChocolate.withOpacity(0.3)),
                      selectedDecoration: const BoxDecoration(color: pointCoralRed, shape: BoxShape.circle),
                      todayDecoration: BoxDecoration(color: subStrawberryPink.withOpacity(0.6), shape: BoxShape.circle),
                      markerDecoration: const BoxDecoration(color: subStrawberryPink, shape: BoxShape.circle),
                      markersMaxCount: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. 리스트 영역
              Expanded(
                child: displayList.isEmpty
                    ? Center(child: Text('이번 달에 작성된 다이어리가 없습니다.', style: TextStyle(color: deepChocolate.withOpacity(0.5))))
                    : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 100.0), // 하단 여백 조절
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
                      margin: const EdgeInsets.only(bottom: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.white, // 카드 배경
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isTargetHighlight ? pointCoralRed : deepChocolate.withOpacity(0.12),
                          width: isTargetHighlight ? 1.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isTargetHighlight ? pointCoralRed.withOpacity(0.1) : deepChocolate.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
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

  // 🌟 라디오 버튼 디자인 적용
  Widget _buildRadioFilter(int value, String label) {
    bool isSelected = _filterType == value;
    return GestureDetector(
      onTap: () => setState(() => _filterType = value),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? pointCoralRed : deepChocolate.withOpacity(0.3),
                  width: 2,
                )
            ),
            child: isSelected
                ? Center(child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: pointCoralRed, shape: BoxShape.circle)))
                : null,
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 14, color: deepChocolate, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  // 🌟 다이어리 리스트 아이템 디자인 적용
  Widget _buildDiaryItem(Map<String, dynamic> entry) {
    bool hasStamp = entry['stampId'] != null && entry['stampId'].toString().isNotEmpty;
    String dateStr = entry['date']?.split(' ')[0] ?? '';
    String storeName = entry['storeName'] ?? '';

    return InkWell(
      onTap: () => _showEditDialog(entry),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_calendar, size: 18, color: deepChocolate.withOpacity(0.7)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$dateStr  $storeName',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: deepChocolate),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasStamp) _buildRedStampBadge(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              entry['note'] ?? '',
              style: TextStyle(fontSize: 14, color: deepChocolate.withOpacity(0.8), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  // 🌟 스탬프 뱃지 얌얌로드 스타일로 변경
  Widget _buildRedStampBadge() {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: creamyIvory,
        borderRadius: BorderRadius.circular(20), // 둥근 알약 형태
        border: Border.all(color: pointCoralRed),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, size: 12, color: pointCoralRed),
          const SizedBox(width: 4),
          const Text(
            '스탬프',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: pointCoralRed,
            ),
          ),
        ],
      ),
    );
  }
}