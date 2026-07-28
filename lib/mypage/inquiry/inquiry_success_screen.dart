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
    // 현재 시간을 문의 일시로 사용합니다.
    final String currentTime = DateFormat('yyyy.MM.dd. HH:mm').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. V 체크 아이콘
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: const Icon(Icons.check, color: Colors.black, size: 36),
              ),
              const SizedBox(height: 24),

              // 2. 완료 메시지
              const Text(
                '문의가 등록되었어요',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 12),

              // 3. 안내 문구 (설계안 반영)
              const Text(
                '영업일 기준 1~2일 이내에\n답변 확인이 가능합니다.\n(이메일로도 답변 확인 가능합니다.)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
              ),
              const SizedBox(height: 32),

              // 4. 등록된 문의 요약 정보 박스
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('문의번호', inquiryId),
                    const SizedBox(height: 8),
                    _infoRow('문의일시', currentTime),
                    const SizedBox(height: 8),
                    _infoRow('제목', title, maxLines: 1),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // 5. 하단 버튼 영역
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    // 문의 상세 보기: 현재 화면을 상세 화면으로 교체
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => InquiryDetailScreen(inquiryId: inquiryId),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('문의 상세 보기', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    // 문의 내역으로 돌아가기: 현재 화면을 내역 리스트 화면으로 교체
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const InquiryListScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('문의 내역으로 돌아가기', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 설계안에 맞춘 '• 라벨: 값' 형태의 정보 출력 위젯
  Widget _infoRow(String label, String value, {int? maxLines}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• $label: ', style: const TextStyle(fontSize: 13, color: Colors.black87)),
        Expanded(
          child: Text(
            value,
            maxLines: maxLines,
            overflow: maxLines != null ? TextOverflow.ellipsis : null,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}