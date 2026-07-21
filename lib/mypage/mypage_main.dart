import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/user_data.dart';
import '../../services/auth_service.dart';
import 'diary/diary.dart';
import 'community_my/community_my.dart';
import '../inquiry/inquiry_list_screen.dart';
import 'stamp/stamp_main_screen.dart';

// 분리한 컴포넌트들 임포트
import 'setting/setting.dart';
import 'widgets/profile_section.dart';
import 'widgets/menu_grid.dart';
import 'widgets/mypage_content_widgets.dart';

class MyPageMainScreen extends StatefulWidget {
  const MyPageMainScreen({Key? key}) : super(key: key);

  @override
  State<MyPageMainScreen> createState() => _MyPageMainScreenState();
}

class _MyPageMainScreenState extends State<MyPageMainScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final String? currentUid = AuthService.currentUser?.uid;
    if (currentUid == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUid).get();
      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          UserData.uid = currentUid;
          UserData.nickname = data['nickname'] ?? '이름없음';
          UserData.name = data['name'] ?? '';
          UserData.phone = data['phone'] ?? '';
          UserData.profileImagePath = data['profileImageUrl'];
          UserData.isDefaultProfileImage = (data['profileImageUrl'] == null || data['profileImageUrl'].toString().isEmpty);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Firestore에서 유저 데이터를 가져오는 도중 오류 발생: $e");
      setState(() => _isLoading = false);
    }
  }

  void _openDiary() => Navigator.push(context, MaterialPageRoute(builder: (context) => const DiaryScreen()));
  void _openCommunity() => Navigator.push(context, MaterialPageRoute(builder: (context) => const CommunityMyScreen()));
  void _openInquiry() => Navigator.push(context, MaterialPageRoute(builder: (context) => const InquiryListScreen()));
  void _openSetting() => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingScreen()));
  void _openStamp() => Navigator.push(context, MaterialPageRoute(builder: (context) => const StampMainScreen()));

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('마이페이지', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🌟 분리된 프로필 섹션 (새로고침 콜백 연동)
              ProfileSection(onRefresh: () {
                setState(() => _isLoading = true);
                _loadUserData();
              }),
              const SizedBox(height: 16),

              // 🌟 분리된 아이콘 격자 메뉴
              MenuGrid(
                  openDiary: _openDiary,
                  openCommunity: _openCommunity,
                  openStamp: _openStamp,
                  openInquiry: _openInquiry,
                  openSetting: _openSetting,
              ),
              const SizedBox(height: 16),

              // 외부에서 공급받는 컴포넌트 바인딩 구조
              _buildCardSection('다이어리', buildDiaryContent(), onDetailTap: _openDiary),
              const SizedBox(height: 16),
              _buildCardSection('얌얌북', buildYamyamBookContent(), onDetailTap: _openCommunity),
              const SizedBox(height: 16),
              _buildCardSection('스탬프', buildStampContent(), onDetailTap: _openStamp),
              const SizedBox(height: 16),
              _buildCardSection('뱃지', buildBadgeContent()),
              const SizedBox(height: 16),
              _buildPointSection('포인트', buildPointContent()),
              const SizedBox(height: 16),
              _buildCardSection('문의', buildInquiryContent(), onDetailTap: _openInquiry),
              const SizedBox(height: 16),
              _buildCardSection('신고', buildReportContent()),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardSection(String title, Widget content, {VoidCallback? onDetailTap}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton(
                onPressed: onDetailTap ?? () {},
                style: TextButton.styleFrom(minimumSize: Size.zero, padding: EdgeInsets.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
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

  Widget _buildPointSection(String title, Widget content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }
}