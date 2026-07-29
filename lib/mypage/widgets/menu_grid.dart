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
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color subTextColor = Color(0xFF7A6B63);
  static const Color cardBorderColor = Color(0xFFEFE8E0);
  static const Color iconBgColor = Color(0xFFFFF4F2);

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
    final List<Map<String, dynamic>> menuItems = [
      {'icon': Icons.book_outlined, 'label': '다이어리'},
      {'icon': Icons.people_outlined, 'label': '얌얌북'},
      {'icon': Icons.verified_outlined, 'label': '스탬프'},
      {'icon': Icons.military_tech_outlined, 'label': '뱃지'},
      {'icon': Icons.monetization_on_outlined, 'label': '포인트'},
      {'icon': Icons.help_outlined, 'label': '문의'},
      {'icon': Icons.report_problem_outlined, 'label': '신고'},
      {'icon': Icons.settings_outlined, 'label': '설정'},
    ];

    final row1Items = menuItems.sublist(0, 4);
    final row2Items = menuItems.sublist(4, 8);

    Widget buildMenuItem(BuildContext context, Map<String, dynamic> item) {
      final String label = item['label'];
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
                SnackBar(content: Text('$label 화면 준비중'), duration: const Duration(seconds: 1)),
              );
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item['icon'],
                  color: deepChocolate,
                  size: 22,
                ),
              ),
              const SizedBox(height: 6),
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
        color: Colors.white,
        border: Border.all(color: cardBorderColor, width: 1.2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: row1Items.map((item) => buildMenuItem(context, item)).toList(),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: row2Items.map((item) => buildMenuItem(context, item)).toList(),
          ),
        ],
      ),
    );
  }
}