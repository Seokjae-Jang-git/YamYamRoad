import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'inquiry_list_screen.dart';
import 'inquiry_detail_screen.dart';

class InquirySuccessScreen extends StatelessWidget {
  final String inquiryId;
  final String title;

  const InquirySuccessScreen({
    Key? key,
    required this.inquiryId,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color pointCoralRed = Color(0xFFFF6B57);
    const Color deepChocolate = Color(0xFF4A3225);
    const Color creamyIvory = Color(0xFFFFFDF9);
    const Color subTextColor = Color(0xFF7A6B63);

    final String currentTime = DateFormat('yyyy.MM.dd. HH:mm').format(DateTime.now());

    return Scaffold(
      backgroundColor: creamyIvory,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pointCoralRed.withOpacity(0.1),
                  border: Border.all(color: pointCoralRed, width: 2),
                ),
                child: const Icon(Icons.check, color: pointCoralRed, size: 40),
              ),
              const SizedBox(height: 24),

              const Text(
                '문의가 등록되었어요',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: deepChocolate),
              ),
              const SizedBox(height: 12),

              const Text(
                '영업일 기준 1~2일 이내에\n답변 확인이 가능합니다.\n(이메일로도 답변 확인 가능합니다.)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: subTextColor, height: 1.5),
              ),
              const SizedBox(height: 32),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: deepChocolate.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(color: deepChocolate.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('문의번호', inquiryId),
                    const SizedBox(height: 8),
                    _infoRow('문의일시', currentTime),
                    const SizedBox(height: 8),
                    _infoRow('제    목', title, maxLines: 1),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => InquiryDetailScreen(inquiryId: inquiryId),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pointCoralRed,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('문의 상세 보기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const InquiryListScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: deepChocolate.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('문의 내역으로 돌아가기', style: TextStyle(color: deepChocolate, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {int? maxLines}) {
    const Color deepChocolate = Color(0xFF4A3225);
    const Color subTextColor = Color(0xFF7A6B63);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 75,
          child: Text('• $label: ', style: const TextStyle(fontSize: 13, color: subTextColor, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: maxLines,
            overflow: maxLines != null ? TextOverflow.ellipsis : null,
            style: const TextStyle(fontSize: 13, color: deepChocolate, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}