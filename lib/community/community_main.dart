import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'community_post.dart';
import 'community_write.dart';
import 'community_detail.dart';
import 'community_search.dart';

enum SortOption { latest, likes, comments, scrap }

class CommunityMainScreen extends StatefulWidget {
  const CommunityMainScreen({Key? key}) : super(key: key);

  @override
  State<CommunityMainScreen> createState() => _CommunityMainScreenState();
}

class _CommunityMainScreenState extends State<CommunityMainScreen> {
  SortOption _sortOption = SortOption.latest;

  String get _sortField {
    switch (_sortOption) {
      case SortOption.latest:
        return 'createdAt';
      case SortOption.likes:
        return 'likeCount';
      case SortOption.comments:
        return 'commentCount';
      case SortOption.scrap:
        return 'scrapCount';
    }
  }

  Query<Map<String, dynamic>> _buildQuery() {
    return FirebaseFirestore.instance
        .collection('community_posts')
        .orderBy(_sortField, descending: true);
  }

  void _openWriteScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CommunityWriteScreen()),
    );
  }

  void _openDetail(CommunityPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityDetailScreen(postId: post.id),
      ),
    );
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CommunitySearchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('커뮤니티',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: _openSearch,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSortRow(),
          Expanded(child: _buildPostList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF8A3D),
        onPressed: _openWriteScreen,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildSortRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _sortTabButton('최신순', SortOption.latest),
          const SizedBox(width: 8),
          _sortTabButton('좋아요순', SortOption.likes),
          const SizedBox(width: 8),
          _sortTabButton('댓글순', SortOption.comments),
          const SizedBox(width: 8),
          _sortTabButton('스크랩순', SortOption.scrap),
        ],
      ),
    );
  }

  Widget _sortTabButton(String label, SortOption option) {
    final bool selected = _sortOption == option;
    return GestureDetector(
      onTap: () => setState(() => _sortOption = option),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? Colors.black : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildPostList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _buildQuery().snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '글을 불러오는 중 오류가 발생했습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Colors.black));
        }

        final docs = snapshot.data!.docs;
        final posts = docs.map((d) => CommunityPost.fromFirestore(d)).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text('총 ${posts.length}개',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: posts.isEmpty
                  ? const Center(child: Text('아직 등록된 글이 없어요.'))
                  : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: posts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) => _buildPostCard(posts[index]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    return GestureDetector(
      onTap: () => _openDetail(post),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌟 뱃지 정보를 불러와 출력하는 헤더 위젯
            _PostHeaderWithBadges(
              userId: post.userId,
              authorNickname: post.nickname ?? '익명',
              authorProfileImage: post.profileImage,
              createdAt: post.createdAt,
            ),
            const SizedBox(height: 10),
            Text(
              post.content,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            if (post.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 10),
              _PostImageCarousel(imageUrls: post.imageUrls),
            ],
            const SizedBox(height: 10),
            Text(
              '좋아요 ${post.likeCount}   댓글 ${post.commentCount}   스크랩 ${post.scrapCount}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🌟 작성자의 뱃지 아이콘 및 추가 뱃지 개수를 가져와 닉네임 옆에 나열해주는 위젯
/// 얌얌북(FeedCardWidget)과 동일한 규칙: 획득한 전체 뱃지 중 대표 뱃지(isSelected+displayOrder)를
/// 우선 정렬해 최대 3개까지 아이콘으로 보여주고, 나머지는 +N으로 표시합니다.
/// 아이콘/+N을 탭하면 얌얌북과 동일한 좌우 스와이프 뱃지 상세 바텀시트가 뜹니다.
class _PostHeaderWithBadges extends StatelessWidget {
  final String userId;
  final String authorNickname;
  final String? authorProfileImage;
  final DateTime createdAt;

  const _PostHeaderWithBadges({
    Key? key,
    required this.userId,
    required this.authorNickname,
    this.authorProfileImage,
    required this.createdAt,
  }) : super(key: key);

  // 🌟 대표 뱃지(isSelected: true)를 displayOrder 순(1->2->3)으로 우선 배치하고,
  // 나머지 획득한 뱃지들을 뒤에 이어서 붙여 전체 뱃지 목록을 생성합니다. (얌얌북과 동일 로직)
  Future<List<Map<String, dynamic>>> _fetchAllUserBadges(String userId) async {
    final cleanUid = userId.trim();
    if (cleanUid.isEmpty) {
      debugPrint('⚠️ [BadgeCheck] userId가 없어 뱃지 조회를 건너뜁니다.');
      return [];
    }

    try {
      final userBadgeSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(cleanUid)
          .collection('users_badge')
          .get();

      if (userBadgeSnap.docs.isEmpty) return [];

      var selectedDocs = userBadgeSnap.docs
          .where((d) => d.data()['isSelected'] == true)
          .toList();

      selectedDocs.sort((a, b) {
        int orderA = (a.data()['displayOrder'] as num?)?.toInt() ?? 99;
        int orderB = (b.data()['displayOrder'] as num?)?.toInt() ?? 99;
        return orderA.compareTo(orderB);
      });

      var unselectedDocs = userBadgeSnap.docs
          .where((d) => d.data()['isSelected'] != true)
          .toList();

      final allDocs = [...selectedDocs, ...unselectedDocs];
      final badgeIds = allDocs
          .map((d) => d.data()['badgeId'] as String?)
          .whereType<String>()
          .toList();

      final List<Map<String, dynamic>> badgeDetails = [];
      for (final bId in badgeIds) {
        final badgeDoc = await FirebaseFirestore.instance.collection('badge').doc(bId).get();
        if (badgeDoc.exists && badgeDoc.data()?['isActive'] == true) {
          final data = badgeDoc.data()!;
          badgeDetails.add({
            'id': bId,
            'name': data['name'] ?? '뱃지',
            'description': data['description'] ?? '',
            'imageUrl': data['imageUrl'] ?? '',
            'iconUrl': data['iconUrl'] ?? data['imageUrl'] ?? '',
          });
        }
      }

      return badgeDetails;
    } catch (e) {
      debugPrint('🔴 [BadgeCheck] 뱃지 로드 중 에러 발생: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchAllUserBadges(userId),
      builder: (context, snapshot) {
        final allBadges = snapshot.data ?? [];

        const int maxDisplayCount = 3;
        final displayBadges = allBadges.take(maxDisplayCount).toList();
        final bool hasMore = allBadges.length > maxDisplayCount;
        final int extraCount = allBadges.length - maxDisplayCount;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. 프로필 이미지
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFF5F5F5),
              backgroundImage: authorProfileImage != null && authorProfileImage!.isNotEmpty
                  ? NetworkImage(authorProfileImage!)
                  : null,
              child: authorProfileImage == null || authorProfileImage!.isEmpty
                  ? const Icon(Icons.person_outline, size: 20, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 10),

            // 2. 닉네임 + 작성 시간
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  authorNickname,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTime(createdAt),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(width: 8),

            // 3. 🌟 얌얌북과 동일한 뱃지 아이콘 목록 (최대 3개, 탭하면 상세 바텀시트)
            if (displayBadges.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: displayBadges.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final badge = entry.value;
                  final String iconUrl = badge['iconUrl'] ?? '';
                  return GestureDetector(
                    onTap: () => _showBadgeSliderBottomSheet(context, allBadges, initialIndex: index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 4),
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: ClipOval(
                        child: iconUrl.isEmpty
                            ? const SizedBox.shrink()
                            : Image.network(
                          iconUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

            // 4. 🌟 남은 뱃지 개수 표시 (+N, 탭하면 이어서 상세 바텀시트)
            if (hasMore)
              GestureDetector(
                onTap: () => _showBadgeSliderBottomSheet(context, allBadges, initialIndex: maxDisplayCount),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+$extraCount',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // 🌟 좌우 스와이프 가능한 슬라이드형 뱃지 전체보기 바텀 시트 (얌얌북 FeedCardWidget과 동일 UI)
  void _showBadgeSliderBottomSheet(
      BuildContext context,
      List<Map<String, dynamic>> allBadges, {
        int initialIndex = 0,
      }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        int currentPage = initialIndex;
        final PageController pageController = PageController(initialPage: initialIndex);

        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '보유한 뱃지 (${currentPage + 1}/${allBadges.length})',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(
                    height: 190,
                    child: PageView.builder(
                      controller: pageController,
                      itemCount: allBadges.length,
                      onPageChanged: (index) {
                        setBottomSheetState(() {
                          currentPage = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final badge = allBadges[index];
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: Image.network(
                                badge['imageUrl'],
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.workspace_premium, size: 70, color: Colors.orange),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              badge['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              badge['description'] ?? '',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                height: 1.3,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  if (allBadges.length > 1) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(allBadges.length, (dotIndex) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: currentPage == dotIndex ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: currentPage == dotIndex ? Colors.black : Colors.grey.shade300,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '확인',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${time.month}/${time.day}';
  }
}

class _PostImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  const _PostImageCarousel({required this.imageUrls});

  @override
  State<_PostImageCarousel> createState() => _PostImageCarouselState();
}

class _PostImageCarouselState extends State<_PostImageCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 220,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.imageUrls.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => Image.network(
                widget.imageUrls[i],
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
        ),
        if (widget.imageUrls.length > 1) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.imageUrls.length, (i) {
              final active = i == _index;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: active ? 6 : 5,
                height: active ? 6 : 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? const Color(0xFFFF8A3D) : Colors.grey.shade300,
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
