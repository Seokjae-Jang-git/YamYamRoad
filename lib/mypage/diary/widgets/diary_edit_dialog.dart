import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../common/user_data.dart';
import '../repository/diary_repository.dart';

class DiaryEditDialog extends StatefulWidget {
  final Map<String, dynamic> entry;
  const DiaryEditDialog({Key? key, required this.entry}) : super(key: key);

  @override
  State<DiaryEditDialog> createState() => _DiaryEditDialogState();
}

class _DiaryEditDialogState extends State<DiaryEditDialog> {
  // 공통 색상 팔레트
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color creamyIvory = Color(0xFFFFFDF9);
  static const Color subTextColor = Color(0xFF7A6B63);
  static const Color pointCoralRed = Color(0xFFFF6B57);

  late bool _isManual;
  late DateTime _dialogSelectedDate;
  late TextEditingController _noteController;
  TextEditingController? _autoStoreController;

  String? _selectedPlaceId;
  late String _initialStoreName;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _isManual = entry['stampId'] == null || entry['stampId'].toString().isEmpty;

    String currentNote = entry['note'] ?? '';
    if (currentNote == '기록된 한줄 평이 없습니다.') currentNote = '';
    _noteController = TextEditingController(text: currentNote);

    _initialStoreName = entry['storeName'] ?? '';
    if (_initialStoreName == '장소 미지정') _initialStoreName = '';

    _selectedPlaceId = entry['placeId'];
    if (_selectedPlaceId != null && _selectedPlaceId!.trim().isEmpty) {
      _selectedPlaceId = null;
    }

    DateTime baseDate = DiaryRepository.parseDateStr(entry['date']);
    int hour = 0; int minute = 0;
    if (entry['time'] != null && entry['time'].toString().contains(':')) {
      List<String> timeParts = entry['time'].toString().split(':');
      hour = int.parse(timeParts[0]); minute = int.parse(timeParts[1]);
    }
    _dialogSelectedDate = DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
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
                    '다이어리 기록 수정',
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

              // 1. 일시 영역 (우측에 '오늘' 버튼 적용)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabel('일시'),
                  GestureDetector(
                    onTap: () {
                      final now = DateTime.now();
                      setState(() {
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
              const SizedBox(height: 16),

              // 2. 가게 / 장소 영역
              _buildLabel('가게 / 장소 이름'),
              _isManual
                  ? Autocomplete<Map<String, dynamic>>(
                initialValue: TextEditingValue(text: _initialStoreName),
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  _selectedPlaceId = null;
                  return await DiaryRepository.searchPlaces(textEditingValue.text);
                },
                displayStringForOption: (option) => option['name'],
                onSelected: (Map<String, dynamic> selection) {
                  _selectedPlaceId = selection['placeId'];
                  _autoStoreController?.text = selection['name'];
                },
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  _autoStoreController = controller;
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onEditingComplete: onEditingComplete,
                    style: const TextStyle(color: deepChocolate, fontSize: 14, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: '가게 이름을 입력하세요',
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
              )
                  : Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: deepChocolate.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: deepChocolate.withOpacity(0.1)),
                ),
                child: Text(_initialStoreName, style: const TextStyle(color: subTextColor, fontSize: 14, fontWeight: FontWeight.w500)),
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

              // 4. 하단 버튼 영역 (삭제 / 수정)
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: OutlinedButton(
                      onPressed: () async {
                        bool? confirmDelete = await showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: creamyIvory,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Text('기록 삭제', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: deepChocolate)),
                            content: const Text('정말로 이 기록을 삭제하시겠습니까?', style: TextStyle(fontSize: 14, color: subTextColor)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('취소', style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('삭제', style: TextStyle(color: pointCoralRed, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );

                        if (confirmDelete == true) {
                          if (!_isManual && widget.entry['stampId'] != null) {
                            await FirebaseFirestore.instance.collection('stamp').doc(widget.entry['stampId']).delete();
                          }
                          await FirebaseFirestore.instance.collection('users').doc(UserData.uid).collection('users_diary_entry').doc(widget.entry['diaryId']).delete();
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제되었습니다.')));
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: pointCoralRed.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('삭제', style: TextStyle(color: pointCoralRed, fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 6,
                    child: ElevatedButton(
                      onPressed: () async {
                        String newDateStr = DateFormat('yyyy.M.d HH:mm').format(_dialogSelectedDate);
                        String finalStoreName = _autoStoreController?.text.trim() ?? _initialStoreName;
                        String finalNote = _noteController.text.trim();

                        if (!_isManual) {
                          await FirebaseFirestore.instance.collection('stamp').doc(widget.entry['stampId']).update({
                            'oneLineNote': finalNote,
                            'issuedAt': Timestamp.fromDate(_dialogSelectedDate),
                            'noteUpdatedAt': FieldValue.serverTimestamp(),
                          });
                          await FirebaseFirestore.instance.collection('users').doc(UserData.uid).collection('users_diary_entry').doc(widget.entry['diaryId']).update({
                            'date': newDateStr,
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                        } else {
                          await FirebaseFirestore.instance.collection('users').doc(UserData.uid).collection('users_diary_entry').doc(widget.entry['diaryId']).update({
                            'date': newDateStr,
                            'placeId': _selectedPlaceId ?? '',
                            'manualStoreName': _selectedPlaceId == null ? finalStoreName : '',
                            'note': finalNote,
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                        }
                        if (mounted) {
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: deepChocolate,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('수정하기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
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