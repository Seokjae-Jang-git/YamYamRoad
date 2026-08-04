import 'package:flutter/material.dart';
import '../diary/diary.dart';
import '../setting/setting.dart';

class MenuGrid extends StatelessWidget {
  final VoidCallback openDiary;
  final VoidCallback openCommunity;
  final VoidCallback openStamp;
  final VoidCallback openBadge;
  final VoidCallback openPoint;
  final VoidCallback openInquiry;
  final VoidCallback openReport;
  final VoidCallback openSetting;

  // YamYamRoad 브랜드 공식 컬러 상수 정의
  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color subStrawberryPink = Color(0xFFFFA09B);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color mint = Color(0xFF9CE3D4);
  static const Color yellow = Color(0xFFF5D070);

  const MenuGrid({
    Key? key,
    required this.openDiary,
    required this.openCommunity,
    required this.openStamp,
    required this.openBadge,
    required this.openPoint,
    required this.openInquiry,
    required this.openReport,
    required this.openSetting,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 각 기능별 공식 팔레트 기반 파스텔 배경색 매핑
    final List<Map<String, dynamic>> menuItems = [
      {
        'icon': Icons.book_outlined,
        'label': '다이어리',
        'bgColor': mint.withOpacity(0.22),
      },
      {
        'icon': Icons.people_outlined,
        'label': '얌얌북',
        'bgColor': mint.withOpacity(0.22),
      },
      {
        'icon': Icons.verified_outlined,
        'label': '스탬프',
        'bgColor': yellow.withOpacity(0.25),
      },
      {
        'icon': Icons.military_tech_outlined,
        'label': '뱃지',
        'bgColor': yellow.withOpacity(0.25),
      },
      {
        'icon': Icons.help_outlined,
        'label': '문의',
        'bgColor': pointCoralRed.withOpacity(0.12),
      },
      {
        'icon': Icons.report_problem_outlined,
        'label': '신고',
        'bgColor': pointCoralRed.withOpacity(0.12),
      },
      {
        'icon': Icons.monetization_on_outlined,
        'label': '포인트',
        'bgColor': deepChocolate.withOpacity(0.08),
      },
      {
        'icon': Icons.settings_outlined,
        'label': '설정',
        'bgColor': deepChocolate.withOpacity(0.08),
      },
    ];

    final row1Items = menuItems.sublist(0, 4);
    final row2Items = menuItems.sublist(4, 8);

    Widget buildMenuItem(BuildContext context, Map<String, dynamic> item) {
      final String label = item['label'];
      final Color tileColor = item['bgColor'] as Color;

      return Expanded(
        child: GestureDetector(
          onTap: () {
            if (label == '다이어리') {
              openDiary();
            } else if (label == '얌얌북') {
              openCommunity();
            } else if (label == '스탬프') {
              openStamp();
            } else if (label == '뱃지') {
              openBadge();
            } else if (label == '포인트') {
              openPoint();
            } else if (label == '문의') {
              openInquiry();
            } else if (label == '신고') {
              openReport();
            } else if (label == '설정') {
              openSetting();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label 화면 준비중'),
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tileColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item['icon'],
                  color: deepChocolate,
                  size: 23,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: deepChocolate,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white, // 크림색 바탕 위 명확한 순백색 카드
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: deepChocolate.withOpacity(0.12), // 통일된 딥 초콜릿 외곽선
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: deepChocolate.withOpacity(0.04), // 부드러운 입체 그림자
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
            row1Items.map((item) => buildMenuItem(context, item)).toList(),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
            row2Items.map((item) => buildMenuItem(context, item)).toList(),
          ),
        ],
      ),
    );
  }
}