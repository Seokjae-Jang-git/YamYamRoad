import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🌟 Firestore 패키지 임포트 추가!
import '../common/bottom_circle_tab_bar.dart';
import '../community/community_main.dart';
import 'setting/setting.dart';
import '../common/user_data.dart';
import 'setting/setting.dart';
import 'diary/diary.dart';
import 'setting/myinfo.dart';
import '../inquiry/inquiry_list_screen.dart';


// 🌟 StatelessWidget에서 StatefulWidget으로 변경하여 상태 관리 기능 부여!
class MyPageMainScreen extends StatefulWidget {
  const MyPageMainScreen({Key? key}) : super(key: key);

  @override
  State<MyPageMainScreen> createState() => _MyPageMainScreenState();
}

class _MyPageMainScreenState extends State<MyPageMainScreen> {
  bool _isLoading = true; // 🌟 DB 데이터를 읽어오는 동안 보여줄 로딩 상태 변수

  @override
  void initState() {
    super.initState();
    _loadUserData(); // 🌟 화면이 처음 켜질 때 Firestore에서 최신 유저 정보를 동기화합니다.
  }

  Future<void> _loadUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(UserData.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

        setState(() {
          // DB에 저장된 실제 데이터들을 로컬 전역 변수(UserData)에 대입
          UserData.nickname = data['nickname'] ?? '디저트킬러';
          UserData.name = data['name'] ?? '홍길동';
          UserData.phone = data['phone'] ?? '';
          UserData.profileImagePath = data['profileImageUrl']; // 스토리지의 다운로드 URL 대입

          // 이미지 URL 존재 여부에 따라 기본 이미지 사용 여부(bool) 판별
          UserData.isDefaultProfileImage = (data['profileImageUrl'] == null);
          _isLoading = false; // 데이터 동기화가 완료되었으므로 로딩 해제
        });
      } else {
        // 문서 자체가 없을 경우 임시 로딩 해제
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Firestore에서 유저 데이터를 가져오는 도중 오류 발생: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 데이터를 아직 불러오는 중이라면 화면 중앙에 빙글빙글 도는 로딩 서클을 표시합니다.
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Colors.black),
        ),
      );
    }

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
              _buildProfileSection(context),
              const SizedBox(height: 24),
              _buildMenuGrid(),
              const SizedBox(height: 24),
              _buildCardSection('다이어리', _buildDiaryContent()),
              const SizedBox(height: 16),
              // 🌟 '자세히 보기'를 누르면 커뮤니티 화면으로 이동하도록 콜백 추가
              _buildCardSection('커뮤니티', _buildCommunityContent(),
                  onDetailTap: _openCommunity),
              const SizedBox(height: 16),
              _buildCardSection('스탬프', _buildStampContent()),
              const SizedBox(height: 16),
              _buildCardSection('뱃지', _buildBadgeContent()),
              const SizedBox(height: 16),
              _buildCardSection('포인트', _buildPointContent()),
              const SizedBox(height: 16),
              _buildCardSection('문의', _buildInquiryContent(),
                  onDetailTap: _openInquiry),
              _buildCardSection('신고', _buildReportContent()),
              const SizedBox(height: 32), // 하단 여유 공간
            ],
          ),
        ),
      ),
    );
  }

  // 🌟 커뮤니티 화면으로 이동하는 함수
  void _openCommunity() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CommunityMainScreen()),
    );
  }

  // 🌟 문의 화면으로 이동하는 함수
  void _openInquiry() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const InquiryListScreen()),
    );
  }

  // 1. 프로필 영역
  Widget _buildProfileSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFFF5F5F5),
              // 🌟 URL 경로가 null이거나 비어있으면 기본 아이콘을, 주소가 있으면 Image.network로 가져옵니다!
              child: UserData.isDefaultProfileImage || UserData.profileImagePath == null
                  ? const Icon(Icons.person_outline, size: 35, color: Colors.grey)
                  : ClipOval(
                child: Image.network(
                  UserData.profileImagePath!, // Storage에서 받은 https://... 주소
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  // 네트워크로 이미지를 로딩하는 동안 보여줄 플레이스홀더 설정 (선택)
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.person_outline, size: 35, color: Colors.grey);
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                UserData.nickname ?? '로딩중...',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            OutlinedButton(
              onPressed: () {
                // 🌟 [수정 완료 후 즉시 반영 핵심 로직]
                // 내 정보 수정 화면으로 이동했다가, 정보 수정을 마치고 pop() 되어 돌아오는 순간
                // .then((_) { ... }) 블록이 실행되면서 DB의 최신 데이터로 화면을 강제 갱신합니다!
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyInfoScreen()),
                ).then((_) {
                  setState(() {
                    _isLoading = true; // 새로고침 효과를 위해 로딩바 활성화 후 재조회
                  });
                  _loadUserData();
                });
              },
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
          return GestureDetector(
            onTap: () {
              // 🌟 1. 다이어리 클릭 시 DiaryScreen으로 이동!
              if (menuItems[index]['label'] == '다이어리') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DiaryScreen()),
                );
              }
              // 🌟 2. 설정 클릭 시 SettingScreen으로 이동!
              else if (menuItems[index]['label'] == '설정') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingScreen()),
                );
              } else if (label == '커뮤니티') {
                _openCommunity();
              } else if (label == '문의') {
                _openInquiry();
              } else {
                // 다른 메뉴를 눌렀을 때의 임시 피드백
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('$label 화면 준비중'),
                      duration: const Duration(seconds: 1)
                  ),
                );
              }
            },
            child: Column(
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
                Text(menuItems[index]['label'], style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }

  // 공통 카드 섹션 컨테이너 (타이틀 + 자세히보기 + 내용)
  // 🌟 onDetailTap 콜백을 추가하여 섹션별로 다른 화면으로 이동할 수 있게 함
  Widget _buildCardSection(String title, Widget content, {VoidCallback? onDetailTap}) {
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
                onPressed: onDetailTap ?? () {},
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
    // 🌟 커뮤니티 미리보기 글도 누르면 바로 커뮤니티 화면으로 이동하도록 GestureDetector로 감쌈
    return GestureDetector(
      onTap: _openCommunity,
      child: Column(
        children: [
          _buildListRow('커뮤니티 글 내용.... 오늘은 카페 라떼를....', '', showIcons: true),
          const SizedBox(height: 8),
          _buildListRow('커뮤니티 글 내용.... 오늘은 성수동에 유명한....', '', showIcons: true),
        ],
      ),
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