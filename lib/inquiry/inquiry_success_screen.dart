import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'inquiry.dart';
import 'inquiry_list_screen.dart';

/// 문의 등록 완료 후 보여주는 확인 화면.
class InquirySuccessScreen extends StatelessWidget {
  final Inquiry inquiry;

  const InquirySuccessScreen({super.key, required this.inquiry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black38,
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                ),
              ),
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: AppColors.primary, size: 36),
              ),
              const SizedBox(height: 20),
              const Text(
                '문의가 등록되었어요',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '영업일 기준 1~2일 이내에\n답변받을 이메일로 안내드릴게요',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _infoRow('문의 유형', inquiry.type.label),
                    const SizedBox(height: 10),
                    _infoRow('제목', inquiry.title),
                    const SizedBox(height: 10),
                    _infoRow('접수 번호', inquiry.receiptNumber, bold: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const InquiryListScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '문의 내역 보기',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
