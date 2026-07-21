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
    return AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      titlePadding: const EdgeInsets.only(right: 8, top: 8),
      title: Align(
        alignment: Alignment.topRight,
        child: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• 일시 (터치하여 수정)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context, initialDate: _dialogSelectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030),
                  builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Colors.black87, onPrimary: Colors.white, onSurface: Colors.black)), child: child!),
                );
                if (pickedDate != null) {
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context, initialTime: TimeOfDay.fromDateTime(_dialogSelectedDate), initialEntryMode: TimePickerEntryMode.input,
                    builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
                  );
                  if (pickedTime != null) {
                    setState(() => _dialogSelectedDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute));
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('yyyy. MM. dd  HH:mm').format(_dialogSelectedDate), style: const TextStyle(fontSize: 14)),
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('• 가게 / 장소 이름', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
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
                  controller: controller, focusNode: focusNode, onEditingComplete: onEditingComplete,
                  decoration: InputDecoration(
                    hintText: '가게 이름을 입력하세요',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400), borderRadius: BorderRadius.zero),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.black), borderRadius: BorderRadius.zero),
                  ),
                );
              },
            )
                : Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              color: Colors.grey.shade100,
              child: Text(_initialStoreName, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
            ),
            const SizedBox(height: 16),
            const Text('• 한줄 기록', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400), borderRadius: BorderRadius.zero),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.black), borderRadius: BorderRadius.zero),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () async {
                    bool? confirmDelete = await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        title: const Text('삭제 확인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        content: const Text('정말로 이 기록을 삭제하시겠습니까?', style: TextStyle(fontSize: 14)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소', style: TextStyle(color: Colors.grey))),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );

                    if (confirmDelete == true) {
                      if (!_isManual && widget.entry['stampId'] != null) {
                        await FirebaseFirestore.instance.collection('stamp').doc(widget.entry['stampId']).delete();
                      }
                      await FirebaseFirestore.instance.collection('users').doc(UserData.uid).collection('users_diary_entry').doc(widget.entry['diaryId']).delete();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제되었습니다.')));
                    }
                  },
                  child: const Text('삭제', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
                OutlinedButton(
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
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                    side: BorderSide(color: Colors.grey.shade400),
                  ),
                  child: const Text('수정'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}