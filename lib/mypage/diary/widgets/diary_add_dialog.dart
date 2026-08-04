import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../common/user_data.dart';
import '../repository/diary_repository.dart';

class DiaryAddDialog extends StatefulWidget {
  final DateTime initialDate;
  const DiaryAddDialog({Key? key, required this.initialDate}) : super(key: key);

  @override
  State<DiaryAddDialog> createState() => _DiaryAddDialogState();
}

class _DiaryAddDialogState extends State<DiaryAddDialog> {
  // 공통 색상 팔레트
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color creamyIvory = Color(0xFFFFFDF9);
  static const Color subTextColor = Color(0xFF7A6B63);

  late DateTime _dialogSelectedDate;
  final TextEditingController _noteController = TextEditingController();
  TextEditingController? _autoStoreController;
  String? _selectedPlaceId;

  @override
  void initState() {
    super.initState();
    _dialogSelectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: creamyIvory,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 (타이틀 + 닫기 버튼)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '다이어리 기록 추가',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: deepChocolate),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: subTextColor, size: 22),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 1. 일시 영역 (우측에 '오늘' 버튼 추가)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabel('일시'),
                  // 🌟 '오늘' 버튼 추가
                  GestureDetector(
                    onTap: () {
                      final now = DateTime.now();
                      setState(() {
                        // 날짜는 '오늘', 시간은 기존 선택했던 시간(또는 현재 시간)으로 세팅
                        _dialogSelectedDate = DateTime(
                          now.year,
                          now.month,
                          now.day,
                          _dialogSelectedDate.hour,
                          _dialogSelectedDate.minute,
                        );
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, right: 4.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: deepChocolate.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: deepChocolate.withOpacity(0.2)),
                        ),
                        child: const Text(
                          '오늘',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: deepChocolate,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // 날짜 선택 클릭 영역
              InkWell(
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _dialogSelectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: deepChocolate,
                          onPrimary: Colors.white,
                          onSurface: deepChocolate,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (pickedDate != null) {
                    final TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_dialogSelectedDate),
                      initialEntryMode: TimePickerEntryMode.input,
                      builder: (context, child) => MediaQuery(
                        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: deepChocolate,
                              onPrimary: Colors.white,
                              onSurface: deepChocolate,
                            ),
                          ),
                          child: child!,
                        ),
                      ),
                    );
                    if (pickedTime != null) {
                      setState(() => _dialogSelectedDate = DateTime(
                        pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute,
                      ));
                    }
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: deepChocolate.withOpacity(0.15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('yyyy. MM. dd   HH:mm').format(_dialogSelectedDate),
                        style: const TextStyle(fontSize: 14, color: deepChocolate, fontWeight: FontWeight.w500),
                      ),
                      const Icon(Icons.calendar_today_rounded, size: 18, color: subTextColor),
                    ],
                  ),
                ),
              ),

              // 2. 가게 / 장소 검색 영역
              _buildLabel('가게 / 장소 이름'),
              Autocomplete<Map<String, dynamic>>(
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  _selectedPlaceId = null;
                  return await DiaryRepository.searchPlaces(textEditingValue.text);
                },
                displayStringForOption: (option) => option['name'],
                onSelected: (Map<String, dynamic> selection) {
                  _selectedPlaceId = selection['placeId'];
                },
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  _autoStoreController = controller;
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onEditingComplete: onEditingComplete,
                    style: const TextStyle(color: deepChocolate, fontSize: 14, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: '가게 이름을 검색해 보세요',
                      hintStyle: TextStyle(color: subTextColor.withOpacity(0.5), fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: deepChocolate.withOpacity(0.15)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: deepChocolate, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // 3. 한줄 기록 영역
              _buildLabel('한줄 기록'),
              TextField(
                controller: _noteController,
                style: const TextStyle(color: deepChocolate, fontSize: 14, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: '오늘의 한줄 기록을 남겨보세요',
                  hintStyle: TextStyle(color: subTextColor.withOpacity(0.5), fontSize: 13),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: deepChocolate.withOpacity(0.15)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: deepChocolate, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 28),

              // 4. 저장 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    String dateStr = DateFormat('yyyy.M.d HH:mm').format(_dialogSelectedDate);
                    String finalStoreName = _autoStoreController?.text.trim() ?? '';
                    String finalNote = _noteController.text.trim();

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(UserData.uid)
                        .collection('users_diary_entry')
                        .add({
                      'date': dateStr,
                      'type': 'manual',
                      'stampId': '',
                      'placeId': _selectedPlaceId ?? '',
                      'manualStoreName': _selectedPlaceId == null ? finalStoreName : '',
                      'note': finalNote,
                      'createdAt': FieldValue.serverTimestamp(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deepChocolate,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('저장하기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 필드 라벨 헤더
  Widget _buildLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: subTextColor),
      ),
    );
  }
}