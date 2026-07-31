import 'dart:io';
import 'package:flutter/material.dart';
import 'colors/stamp_colors.dart';

class StampVerificationCompletePage extends StatelessWidget {
  final String placeName;
  final String receiptImagePath;
  final int rating;
  final String note;
  final int awardedPoints;

  const StampVerificationCompletePage({
    super.key,
    required this.placeName,
    required this.receiptImagePath,
    required this.rating,
    required this.note,
    required this.awardedPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YamYamStampColors.creamyIvory,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: YamYamStampColors.creamyIvory,
        foregroundColor: YamYamStampColors.deepChocolate,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '스탬프 인증 완료',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: YamYamStampColors.deepChocolate,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // 완료 상단 파스텔 카드
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [YamYamStampColors.softPink, YamYamStampColors.creamyIvory],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: YamYamStampColors.borderPink, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: YamYamStampColors.coralRed.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('🎉', style: TextStyle(fontSize: 38)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    placeName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: YamYamStampColors.deepChocolate,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: YamYamStampColors.coralRed,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      awardedPoints > 0
                          ? '스탬프 + $awardedPoints P 적립 완료!'
                          : '스탬프 적립 완료!',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 제출된 영수증 프리뷰
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                File(receiptImagePath),
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 18),

            // 내 별점 및 한 줄 메모 요약
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: YamYamStampColors.borderPink),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '내 남긴 별점: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: YamYamStampColors.deepChocolate,
                        ),
                      ),
                      Row(
                        children: List.generate(
                          5,
                              (index) => Icon(
                            index < rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: YamYamStampColors.starActive,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (note.isNotEmpty) ...[
                    const Divider(height: 20, color: YamYamStampColors.borderPink),
                    Text(
                      '" $note "',
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: YamYamStampColors.subTextColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 28),

            // 돌아가기 버튼
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: YamYamStampColors.coralRed,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}