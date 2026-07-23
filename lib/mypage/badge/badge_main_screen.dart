import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 🌟 UI에 뿌려주기 위해 '전체 뱃지'와 '유저가 획득한 뱃지'를 합친 모델
class BadgeUIModel {
  final String id;
  final String name;
  final String imageUrl;
  final bool isEarned;
  final DateTime? earnedAt;
  final bool isSelected;

  BadgeUIModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.isEarned,
    this.earnedAt,
    this.isSelected = false,
  });
}

class BadgeMainScreen extends StatefulWidget {
  const BadgeMainScreen({Key? key}) : super(key: key);

  @override
  State<BadgeMainScreen> createState() => _BadgeMainScreenState();
}

class _BadgeMainScreenState extends State<BadgeMainScreen> {
  bool _isLoading = true;
  bool _showOnlyEarned = false; // 마스터만 보기 체크박스 상태
  List<BadgeUIModel> _allBadges = [];

  @override
  void initState() {
    super.initState();
    _fetchBadges();
  }

  // 🧠 [핵심 로직] 마스터 뱃지와 유저 뱃지를 가져와서 매핑합니다.
  Future<void> _fetchBadges() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      debugPrint('====================================');
      debugPrint('🔍 1. 현재 앱 로그인 UID: $uid');
      debugPrint('🔍 2. 테스트용 고정 UID: 4TtOtuHtn4QPXEplNBKy5dAqueb2');

      // 혹시라도 uid가 다르게 들어오는지(공백 포함 여부 등) 눈으로 직접 비교해 볼 수 있습니다.

      if (uid == null) {
        debugPrint('🔴 에러: 로그인 UID가 null입니다. (파이어베이스 Auth 연결 지연)');
        setState(() => _isLoading = false);
        return;
      }

      // 1. 마스터 뱃지 로드
      final badgeSnapshot = await FirebaseFirestore.instance
          .collection('badge')
          .where('isActive', isEqualTo: true)
          .get();
      debugPrint('🔍 3. DB에서 읽어온 활성화된 전체 뱃지 개수: ${badgeSnapshot.docs.length}');

      // 2. 유저 뱃지 로드
      final userBadgeSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('users_badge')
          .get();
      debugPrint('🔍 4. 유저 DB(users_badge)에서 읽어온 획득 뱃지 개수: ${userBadgeSnapshot.docs.length}');

      // 3. 맵핑
      final userBadgeMap = {
        for (var doc in userBadgeSnapshot.docs)
          doc.data()['badgeId']: doc.data()
      };
      debugPrint('🔍 5. 맵핑 성공한 유저 뱃지 ID 목록: ${userBadgeMap.keys.toList()}');

      // 4. 결합 및 필터링
      final List<BadgeUIModel> loadedBadges = badgeSnapshot.docs.map((doc) {
        final data = doc.data();
        final badgeId = doc.id;
        final isEarned = userBadgeMap.containsKey(badgeId);
        final userBadgeData = userBadgeMap[badgeId];

        return BadgeUIModel(
          id: badgeId,
          name: data['name'] ?? '이름없음',
          imageUrl: data['imageUrl'] ?? '',
          isEarned: isEarned,
          earnedAt: isEarned && userBadgeData!['earnedAt'] != null
              ? (userBadgeData['earnedAt'] as Timestamp).toDate()
              : null,
          isSelected: isEarned && userBadgeData!['isSelected'] == true,
        );
      }).where((badge) => badge.isEarned).toList();

      debugPrint('🔍 6. 화면에 렌더링될 최종 뱃지 개수: ${loadedBadges.length}');
      debugPrint('====================================');

      setState(() {
        _allBadges = loadedBadges;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('🔴 뱃지 데이터를 불러오는 중 에러 발생: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 이제 _allBadges에는 획득한 뱃지만 존재하므로, 그대로 화면에 보여주면 됩니다.
    final displayedBadges = _allBadges;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '뱃지',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 상단 필터 영역
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildFilterButton('전체'),
                    const SizedBox(width: 8),
                    _buildFilterButton('지역'),
                    const SizedBox(width: 8),
                    _buildFilterButton('메뉴'),
                    const SizedBox(width: 8),
                    _buildFilterButton('기간'),
                  ],
                ),
                Row(
                  children: [
                    _buildFilterButton('최신순'),
                    const SizedBox(width: 8),
                    _buildFilterButton('이름순'),
                  ],
                ),
              ],
            ),
          ),

          // 2. 마스터만 보기 체크박스 & 총 개수
          // (참고: 미획득 뱃지를 숨겼기 때문에, 이 체크박스는 추후 기획에 맞게 삭제하거나 '최고 등급만 보기' 등으로 활용할 수 있습니다.)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              children: [
                Checkbox(
                  value: _showOnlyEarned,
                  activeColor: Colors.black,
                  onChanged: (value) {
                    setState(() {
                      _showOnlyEarned = value ?? false;
                    });
                  },
                ),
                const Text('마스터만 보기', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              '총 뱃지 ${displayedBadges.length} 개',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          // 3. 뱃지 그리드 뷰
          Expanded(
            child: displayedBadges.isEmpty
                ? const Center(
              child: Text('아직 획득한 뱃지가 없습니다.', style: TextStyle(color: Colors.grey, fontSize: 16)),
            )
                : GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 24,
                childAspectRatio: 0.8, // 세로로 살짝 길게
              ),
              itemCount: displayedBadges.length,
              itemBuilder: (context, index) {
                final badge = displayedBadges[index];
                return _buildBadgeItem(badge);
              },
            ),
          ),
        ],
      ),
    );
  }

  // 상단 필터 버튼 위젯 렌더링
  Widget _buildFilterButton(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }

  // 개별 뱃지 아이템 렌더링 (PNG 이미지 원본 그대로 표현)
  Widget _buildBadgeItem(BadgeUIModel badge) {
    return Column(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1, // 1:1 정사각형 비율 유지
            child: Image.network(
              badge.imageUrl,
              fit: BoxFit.contain, // 🌟 PNG 뱃지 비율을 왜곡 없이 쏙 담아냅니다.
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              },
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image, color: Colors.grey, size: 40),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 뱃지 이름
        Text(
          badge.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold, // 이제 모두 획득한 뱃지이므로 진하게 고정
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}