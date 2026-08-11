import 'package:flutter/material.dart';
import '../colors/stamp_colors.dart';

class VisitNoteInput extends StatelessWidget {
  final TextEditingController controller;

  const VisitNoteInput({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: 100,
      maxLines: 3,
      style: const TextStyle(
        fontSize: 14,
        color: YamYamStampColors.deepChocolate,
      ),
      decoration: InputDecoration(
        hintText: '이곳에서의 소중한 추억을 한 줄로 기록해 보세요.',
        hintStyle: TextStyle(
          fontSize: 13,
          color: YamYamStampColors.subTextColor.withOpacity(0.6),
        ),
        filled: true,
        fillColor: Colors.white,
        counterStyle: const TextStyle(
          color: YamYamStampColors.subTextColor,
          fontSize: 11,
        ),
        contentPadding: const EdgeInsets.all(16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: YamYamStampColors.borderPink, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: YamYamStampColors.coralRed, width: 1.5),
        ),
      ),
    );
  }
}