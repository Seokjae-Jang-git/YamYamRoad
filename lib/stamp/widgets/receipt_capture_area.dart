import 'dart:io';
import 'package:flutter/material.dart';
import '../colors/stamp_colors.dart';

class ReceiptCaptureArea extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onTap;

  const ReceiptCaptureArea({
    super.key,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasImage = imagePath != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        height: 250,
        decoration: BoxDecoration(
          color: hasImage ? Colors.black : YamYamStampColors.softPink.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasImage ? YamYamStampColors.coralRed : YamYamStampColors.borderPink,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: YamYamStampColors.coralRed.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: hasImage
            ? Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                File(imagePath!),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Center(
                  child: Text(
                    '사진을 불러오지 못했습니다.\n다시 촬영해 주세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      '다시 촬영하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: YamYamStampColors.coralRed.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 30,
                color: YamYamStampColors.coralRed,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '눌러서 영수증 촬영하기',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: YamYamStampColors.deepChocolate,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '상호명과 결제 시간이 선명하게 잘 보이도록 찍어주세요',
              style: TextStyle(
                fontSize: 12,
                color: YamYamStampColors.subTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}