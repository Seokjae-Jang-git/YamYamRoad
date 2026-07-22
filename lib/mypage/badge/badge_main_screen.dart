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
      // 테스트를 위해 강제로 uid를 지정하려면 아래 주석을 풀고 사용하세요.
      // final uid = "4TtOtuHtn4QPXePlNBKy5dAqu...";

      if (uid == null) {
        debugPrint('로그인된 사용자가 없습니다.');
        setState(() => _isLoading = false);
        return;
      }

      // 1. 전체 마스터 뱃지 가져오기 (사용 여부가 true인 것만)
      final badgeSnapshot = await FirebaseFirestore.instance
          .collection('badge')
          .where('isActive', isEqualTo: true)
          .get();

      // 2. 현재 유저가 획득한 뱃지 가져오기
      final userBadgeSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('users_badge')
          .get();

      // 유저 뱃지 데이터를 Map 형태로 변환 (검색 속도 최적화: O(1))
      final userBadgeMap = {
        for (var doc in userBadgeSnapshot.docs)
          doc.data()['badgeId']: doc.data()
      };

      // 3. 마스터 뱃지를 돌면서 유저 획득 여부를 결합 (Join)
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
      }).toList();

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
    // '마스터만 보기' 필터 적용
    final displayedBadges = _showOnlyEarned
        ? _allBadges.where((b) => b.isEarned).toList()
        : _allBadges;

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
            child: GridView.builder(
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
            child: ColorFiltered(
              // 🌟 획득하지 않은 뱃지는 자동 흑백(Grayscale) 처리
              colorFilter: badge.isEarned
                  ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                  : const ColorFilter.matrix(<double>[
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0.2126, 0.7152, 0.0722, 0, 0,
                0,      0,      0,      1, 0,
              ]),
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
        ),
        const SizedBox(height: 8),
        // 뱃지 이름
        Text(
          badge.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: badge.isEarned ? FontWeight.bold : FontWeight.normal,
            color: badge.isEarned ? Colors.black : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}