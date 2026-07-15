import 'package:flutter/material.dart';

class MyPageMainScreen extends StatelessWidget {
  const MyPageMainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '마이페이지',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0, // 플랫한 디자인을 위해 그림자 제거
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileSection(),
              const SizedBox(height: 24),
              _buildMenuGrid(),
              const SizedBox(height: 24),
              _buildCardSection('다이어리', _buildDiaryContent()),
              const SizedBox(height: 16),
              _buildCardSection('커뮤니티', _buildCommunityContent()),
              const SizedBox(height: 16),
              _buildCardSection('스탬프', _buildStampContent()),
              const SizedBox(height: 16),
              _buildCardSection('뱃지', _buildBadgeContent()),
              const SizedBox(height: 16),
              _buildCardSection('포인트', _buildPointContent()),
              const SizedBox(height: 16),
              _buildCardSection('문의', _buildInquiryContent()),
              const SizedBox(height: 16),
              _buildCardSection('신고', _buildReportContent()),
              const SizedBox(height: 32), // 하단 여유 공간
            ],
          ),
        ),
      ),
    );
  }

  // 1. 프로필 영역
  Widget _buildProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFFEEEEEE),
              child: Text('프로필\n이미지',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.black54)),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                '닉네임',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text('수정', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.only(left: 76.0), // 프로필 이미지 너비만큼 띄움
          child: Text('좋아요 0   스크랩 0', style: TextStyle(color: Colors.black87)),
        ),
      ],
    );
  }

  // 2. 8개 아이콘 메뉴 그리드 영역
  Widget _buildMenuGrid() {
    final List<Map<String, dynamic>> menuItems = [
      {'icon': Icons.book_outlined, 'label': '다이어리'},
      {'icon': Icons.people_outline, 'label': '커뮤니티'},
      {'icon': Icons.verified_outlined, 'label': '스탬프'},
      {'icon': Icons.military_tech_outlined, 'label': '뱃지'},
      {'icon': Icons.monetization_on_outlined, 'label': '포인트'},
      {'icon': Icons.help_outline, 'label': '문의'},
      {'icon': Icons.report_problem_outlined, 'label': '신고'},
      {'icon': Icons.settings_outlined, 'label': '설정'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(), // 스크롤 충돌 방지
        itemCount: menuItems.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 20,
          crossAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(menuItems[index]['icon'], color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              Text(menuItems[index]['label'],
                  style: const TextStyle(fontSize: 12)),
            ],
          );
        },
      ),
    );
  }

  // 공통 카드 섹션 컨테이너 (타이틀 + 자세히보기 + 내용)
  Widget _buildCardSection(String title, Widget content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('자세히 보기', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  // 각 섹션별 내부 컨텐츠 위젯들
  Widget _buildDiaryContent() {
    return Column(
      children: [
        _buildListRow('26. 7. 10 커피세상', '아메리카노는 쏘쏘 가성비 있음'),
        const SizedBox(height: 8),
        _buildListRow('26. 7. 8 떡마루', '부모님 생신 떡 케익 구매'),
      ],
    );
  }

  Widget _buildCommunityContent() {
    return Column(
      children: [
        _buildListRow('커뮤니티 글 내용.... 오늘은 카페 라떼를....', '', showIcons: true),
        const SizedBox(height: 8),
        _buildListRow('커뮤니티 글 내용.... 오늘은 성수동에 유명한....', '', showIcons: true),
      ],
    );
  }

  Widget _buildStampContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(5, (index) {
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade400),
          ),
          alignment: Alignment.center,
          child: const Text('스탬프', style: TextStyle(fontSize: 10)),
        );
      }),
    );
  }

  Widget _buildBadgeContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.only(right: 16),
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
          ),
          alignment: Alignment.center,
          // 다이아몬드 형태를 원한다면 Transform.rotate 사용
          child: Transform.rotate(
            angle: 0.785398, // 45 degrees
            child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400)),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPointContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildPointBox('보유 포인트', '8,000 Point'),
        _buildPointBox('충전 포인트', '10,000 Point'),
        _buildPointBox('사용 포인트', '2,000 Point'),
      ],
    );
  }

  Widget _buildPointBox(String title, String point) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 8),
            Text(point, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildInquiryContent() {
    return Column(
      children: [
        _buildListRow('문의 글 내용.... 오늘은 카페 라떼를....', '답변 대기 중'),
        const SizedBox(height: 8),
        _buildListRow('문의 글 내용.... 오늘은 성수동에 유명한....', '답변 완료'),
      ],
    );
  }

  Widget _buildReportContent() {
    return Column(
      children: [
        _buildListRow('신고 글 내용.... 오늘은 카페 라떼를....', '처리 대기 중'),
        const SizedBox(height: 8),
        _buildListRow('신고 글 내용.... 오늘은 성수동에 유명한....', '처리 완료'),
      ],
    );
  }

  // 리스트 형태의 텍스트 줄을 만들어주는 헬퍼 위젯
  Widget _buildListRow(String leftText, String rightText, {bool showIcons = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            '• $leftText',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        if (showIcons) ...[
          const Row(
            children: [
              Icon(Icons.favorite_border, size: 16, color: Colors.grey),
              SizedBox(width: 4),
              Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey),
            ],
          )
        ] else ...[
          Text(rightText, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ]
      ],
    );
  }
}