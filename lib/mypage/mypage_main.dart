import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yamyam_road/mypage/badge/badge_main_screen.dart';
import 'package:yamyam_road/mypage/report/report_list_screen.dart';
import '../common/user_data.dart';
import '../../services/auth_service.dart';
import '../services/after_stamp_service.dart';
import 'diary/diary.dart';
import 'community_my/community_my.dart';
import 'inquiry/inquiry_list_screen.dart';
import 'stamp/stamp_main_screen.dart';
import 'badge/badge_main_screen.dart';
import 'point/point_main_screen.dart';

import 'badge_grant_debug_tool.dart';

// 분리한 컴포넌트들 임포트
import 'setting/setting.dart';
import 'widgets/profile_section.dart';
import 'widgets/menu_grid.dart';
import 'widgets/mypage_content_widgets.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/badge_service.dart'; // 뱃지 서비스 경로에 맞게 임포트 해주세요!

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
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection(
          'users').doc(currentUid).get();
      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          UserData.uid = currentUid;
          UserData.nickname = data['nickname'] ?? '이름없음';
          UserData.name = data['name'] ?? '';
          UserData.phone = data['phone'] ?? '';
          UserData.profileImagePath = data['profileImageUrl'];
          UserData.isDefaultProfileImage =
          (data['profileImageUrl'] == null || data['profileImageUrl']
              .toString()
              .isEmpty);
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

  void _openDiary() =>
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const DiaryScreen()));

  void _openCommunity() =>
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const CommunityMyScreen()));

  void _openStamp() =>
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const StampMainScreen()));

  void _openBadge() =>
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const BadgeMainScreen()));

  void _openPoint() =>
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const PointMainScreen()));

  void _openInquiry() =>
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const InquiryListScreen()));

  void _openSetting() =>
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const SettingScreen()));

  void _openReport() =>
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const ReportListScreen()));

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
        title: const Text('마이페이지',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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

              // 스탬프 발행 후 다이어리에 기록 안된 것 동기화 임시 버튼
              // ElevatedButton.icon(
              //   onPressed: () async {
              //     // 동기화 실행 중 로딩 표시
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       const SnackBar(
              //         content: Text('스탬프 ➔ 다이어리 동기화를 진행 중입니다...'),
              //         duration: Duration(seconds: 2),
              //       ),
              //     );
              //
              //     // 🌟 방금 만든 AfterStampService의 동기화 함수 호출!
              //     await AfterStampService.syncMissingDiaries(context);
              //   },
              //   icon: const Icon(Icons.sync, size: 16, color: Colors.white),
              //   label: const Text(
              //     '다이어리 동기화',
              //     style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              //   ),
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: Colors.orange.shade700,
              //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(20),
              //     ),
              //   ),
              // ),
              const SizedBox(height: 16),

              // 🌟 분리된 아이콘 격자 메뉴
              MenuGrid(
                openDiary: _openDiary,
                openCommunity: _openCommunity,
                openStamp: _openStamp,
                openBadge: _openBadge,
                openPoint: _openPoint,
                openInquiry: _openInquiry,
                openReport: _openReport,
                openSetting: _openSetting,
              ),
              const SizedBox(height: 16),

              // 외부에서 공급받는 컴포넌트 바인딩 구조
              _buildCardSection(
                  '다이어리', buildDiaryContent(), onDetailTap: _openDiary),
              const SizedBox(height: 16),
              _buildCardSection(
                  '얌얌북', buildYamyamBookContent(), onDetailTap: _openCommunity),
              const SizedBox(height: 16),
              _buildCardSection(
                  '스탬프', buildStampContent(), onDetailTap: _openStamp),
              const SizedBox(height: 16),
              _buildCardSection(
                  '뱃지', buildBadgeContent(), onDetailTap: _openBadge),
              const SizedBox(height: 16),
              _buildCardSection(
                  '포인트', buildPointContent(context), onDetailTap: _openPoint),
              const SizedBox(height: 16),
              _buildCardSection(
                  '문의', buildInquiryContent(), onDetailTap: _openInquiry),
              const SizedBox(height: 16),
              _buildCardSection(
                  '신고', buildReportContent(), onDetailTap: _openReport),
              const SizedBox(height: 32),
              const BadgeRealCheckDebugButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardSection(String title, Widget content,
      {VoidCallback? onDetailTap}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton(
                onPressed: onDetailTap ?? () {},
                style: TextButton.styleFrom(minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: const Text('자세히 보기',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }
}

// class TestBadgeButton extends StatefulWidget {
//   const TestBadgeButton({Key? key}) : super(key: key);
//
//   @override
//   State<TestBadgeButton> createState() => _TestBadgeButtonState();
// }
//
// class _TestBadgeButtonState extends State<TestBadgeButton> {
//   int _clickCount = 0;
//
//   final List<String> _realPlaceIds = [
//     'place_MA010120220800224498',
//     'place_MA010120220800226143',
//     'place_MA010120220800227349',
//   ];
//
//   final String _fixedUserId = "4TtOtuHtn4QPXEplNBKy5dAqueb2";
//   final String _fixedRoadId = '5jCYISR6BiXudM2FLGDo';
//
//   void _runTest() async {
//     // 3번 클릭(스탬프 3개)이 끝나면 종료
//     if (_clickCount >= 3) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('3개의 실제 업체 스탬프 테스트가 모두 완료되었습니다!')),
//       );
//       return;
//     }
//
//     final firestore = FirebaseFirestore.instance;
//
//     final currentPlaceId = _realPlaceIds[_clickCount];
//
//     // 타임스탬프를 활용해 중복 없는 문서 ID 생성
//     final String verificationDocId = 'test_veri_${DateTime.now().millisecondsSinceEpoch}';
//     final String stampDocId = 'test_stamp_${DateTime.now().millisecondsSinceEpoch}';
//
//     final int nextCount = _clickCount + 1;
//
//     try {
//       // 1. 인증 데이터 생성
//       await firestore.collection('verification').doc(verificationDocId).set({
//         'userId': _fixedUserId,
//         'placeId': currentPlaceId,
//         'roadId': _fixedRoadId,
//         'receiptImageUrl': null,
//         'status': 'approved',
//         'createdAt': FieldValue.serverTimestamp(),
//       });
//       debugPrint('1️⃣ 인증 데이터 생성 완료! (업체: $currentPlaceId)');
//
//       // 2. 스탬프 데이터 생성
//       await firestore.collection('stamp').doc(stampDocId).set({
//         'userId': _fixedUserId,
//         'placeId': currentPlaceId,
//         'verificationId': verificationDocId,
//         'roadId': _fixedRoadId,
//         'issuedAt': FieldValue.serverTimestamp(),
//         'oneLineNote': '기간 뱃지 테스트용 한줄기록',
//       });
//       debugPrint('2️⃣ 스탬프 데이터 생성 완료!');
//
//       setState(() {
//         _clickCount = nextCount;
//       });
//
//       // 3. 뱃지 발급 검사 로직 호출
//       if (context.mounted) {
//         debugPrint('3️⃣ 기간 뱃지 발급 조건 검사 시작...');
//         await BadgeService.checkAndGrantBadges(context, _fixedUserId);
//         debugPrint('4️⃣ 뱃지 발급 검사 완료!');
//       }
//
//     } catch (e) {
//       debugPrint('🔴 수동 테스트 실행 중 에러 발생: $e');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       margin: const EdgeInsets.symmetric(vertical: 16),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade100,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.grey.shade300),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             '🧪 뱃지 발급 테스트 (현재 $_clickCount/3 완료)',
//             style: const TextStyle(fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 12),
//           ElevatedButton(
//             onPressed: _runTest,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: _clickCount >= 5 ? Colors.grey : Colors.blue,
//               foregroundColor: Colors.white,
//             ),
//             child: const Text('스탬프 1개 추가 + 뱃지 검사'),
//           ),
//         ],
//       ),
//     );
//   }
// }