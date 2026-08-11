import 'package:flutter/material.dart';
import 'location_info.dart';
import 'privacy.dart';
import 'agreement.dart';
import 'myinfo.dart';
import 'withdrawn.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  // 공통 색상 팔레트
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color creamyIvory = Color(0xFFFFFDF9);
  static const Color subTextColor = Color(0xFF7A6B63);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamyIvory,
      appBar: AppBar(
        title: const Text(
          '설정',
          style: TextStyle(color: deepChocolate, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: creamyIvory,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: deepChocolate, size: 28),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 계정 섹션
              _buildSectionTitle('계정'),
              _buildSectionCard([
                _buildListItem(context, '내 정보 수정'),
                _buildDivider(),
                _buildListItem(context, '계정 삭제'),
              ]),

              const SizedBox(height: 32),

              // 2. 기타 섹션
              _buildSectionTitle('기타'),
              _buildSectionCard([
                _buildListItem(context, '이용약관'),
                _buildDivider(),
                _buildListItem(context, '개인정보 처리방침'),
                _buildDivider(),
                _buildListItem(context, '위치기반서비스 이용약관'),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // 섹션 그룹 카드 (둥근 모서리 및 그림자)
  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: deepChocolate.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: deepChocolate.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Material(
        color: Colors.white,
        child: Column(children: children),
      ),
    );
  }

  // 리스트 아이템 간 구분선
  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: deepChocolate.withOpacity(0.08),
      indent: 20,
      endIndent: 20,
    );
  }

  // 섹션 타이틀
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: subTextColor),
      ),
    );
  }

  // 개별 리스트 아이템
  Widget _buildListItem(BuildContext context, String title) {
    return InkWell(
      onTap: () {
        if (title == '내 정보 수정') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyInfoScreen()),
          );
        } else if (title == '계정 삭제') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WithdrawnScreen()),
          );
        } else if (title == '이용약관') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AgreementScreen()),
          );
        } else if (title == '개인정보 처리방침') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PrivacyScreen()),
          );
        } else if (title == '위치기반서비스 이용약관') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LocationInfoScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title 페이지 준비중'), duration: const Duration(seconds: 1)),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
                title,
                style: const TextStyle(fontSize: 15, color: deepChocolate, fontWeight: FontWeight.w500)
            ),
            const Icon(Icons.chevron_right, color: subTextColor, size: 22),
          ],
        ),
      ),
    );
  }
}