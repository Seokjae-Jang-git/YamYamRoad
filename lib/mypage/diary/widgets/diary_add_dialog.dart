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
                  controller: controller, focusNode: focusNode, onEditingComplete: onEditingComplete,
                  decoration: InputDecoration(
                    hintText: '가게 이름을 검색해 보세요',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400), borderRadius: BorderRadius.zero),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.black), borderRadius: BorderRadius.zero),
                  ),
                );
              },
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
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () async {
                  String dateStr = DateFormat('yyyy.M.d HH:mm').format(_dialogSelectedDate);
                  String finalStoreName = _autoStoreController?.text.trim() ?? '';
                  String finalNote = _noteController.text.trim();

                  await FirebaseFirestore.instance.collection('users').doc(UserData.uid).collection('users_diary_entry').add({
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
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
                child: const Text('저장'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}