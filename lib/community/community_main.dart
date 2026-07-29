import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/emoticon/emoticon_span_builder.dart';
import 'community_post.dart';
import 'community_write.dart';
import 'community_detail.dart';
import 'community_search.dart';
import 'widgets/post_image_carousel.dart'; // 🌟 메인/상세 공용 이미지 캐러셀

enum SortOption { latest, likes, comments, scrap }
// 🌟 좋아요순/스크랩순일 때만 의미가 있는 기간 필터. 최신순/댓글순은 항상 all 취급합니다.
enum SortPeriod { all, daily, weekly }

class CommunityMainScreen extends StatefulWidget {
  const CommunityMainScreen({Key? key}) : super(key: key);

  @override
  State<CommunityMainScreen> createState() => _CommunityMainScreenState();
}

class _CommunityMainScreenState extends State<CommunityMainScreen> {
  SortOption _sortOption = SortOption.latest;
  SortPeriod _sortPeriod = SortPeriod.all;
  final ScrollController _scrollController = ScrollController(); // 🌟 얌얌북 탭 시 맨 위로 스크롤하기 위한 컨트롤러

  // 🌟 일간/주간 정렬은 실시간 스트림이 아니라 필요할 때 다시 계산하는 Future로 관리합니다.
  late Future<List<CommunityPost>> _postsFuture;

  // 🌟 누적 카운트 기준 상위 몇 개까지를 "최근 인기글" 후보로 볼지. 이 풀 밖의 글은
  // 최근에 좋아요/스크랩이 아무리 몰려도 후보에 들지 못하는 한계가 있습니다.
  static const int _candidatePoolSize = 100;

  @override
  void initState() {
    super.initState();
    _postsFuture = _fetchRankedPosts();
  }

  @override
  void dispose() {
    _scrollController.dispose(); // 🌟 여기(메인 화면 State)에서 해제
    super.dispose();
  }

  // 🌟 AppBar 타이틀 '얌얌북'을 누르면 리스트 맨 위로 스크롤
  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  void _refetch() {
    setState(() {
      _postsFuture = _fetchRankedPosts();
    });
  }

  void _changeSortOption(SortOption option) {
    setState(() {
      _sortOption = option;
      // 최신순/댓글순으로 바꾸면 기간 필터는 의미가 없으니 초기화
      if (option != SortOption.likes && option != SortOption.scrap) {
        _sortPeriod = SortPeriod.all;
      }
    });
    _refetch();
  }

  void _changeSortPeriod(SortPeriod period) {
    setState(() => _sortPeriod = period);
    _refetch();
  }

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
        .collection('posts')
        .orderBy(_sortField, descending: true);
  }

  // 🌟 실제 정렬 로직.
  // - 전체 기간(all) 또는 좋아요/스크랩이 아닌 정렬: 기존처럼 누적 카운트/최신순 그대로
  // - 좋아요/스크랩 + 일간/주간: 누적 상위 후보 풀을 뽑고, 각 글마다 서브컬렉션에
  //   count() 집계 쿼리를 날려 "최근 기간 내" 개수만 센 뒤 그 값으로 다시 정렬
  Future<List<CommunityPost>> _fetchRankedPosts() async {
    final bool isPeriodApplicable =
        _sortOption == SortOption.likes || _sortOption == SortOption.scrap;

    if (_sortPeriod == SortPeriod.all || !isPeriodApplicable) {
      final snap = await _buildQuery().get();
      return snap.docs.map((d) => CommunityPost.fromFirestore(d)).toList();
    }

    final String subcollection = _sortOption == SortOption.likes ? 'post_like' : 'post_scrap';
    final String timestampField = _sortOption == SortOption.likes ? 'likedAt' : 'scrappedAt';

    // 1단계: 누적 카운트 기준 상위 N개를 후보로 확보
    final candidateSnap = await FirebaseFirestore.instance
        .collection('posts')
        .orderBy(_sortField, descending: true)
        .limit(_candidatePoolSize)
        .get();

    final posts = candidateSnap.docs.map((d) => CommunityPost.fromFirestore(d)).toList();
    if (posts.isEmpty) return posts;

    final cutoff = Timestamp.fromDate(
      DateTime.now().subtract(
        _sortPeriod == SortPeriod.daily ? const Duration(hours: 24) : const Duration(days: 7),
      ),
    );

    // 2단계: 각 후보마다 "최근 기간 내" 개수만 count() 집계로 조회 (병렬 실행)
    final recentCounts = await Future.wait(posts.map((post) async {
      final agg = await FirebaseFirestore.instance
          .collection('posts')
          .doc(post.id)
          .collection(subcollection)
          .where(timestampField, isGreaterThanOrEqualTo: cutoff)
          .count()
          .get();
      return agg.count ?? 0;
    }));

    // 3단계: 최근 기간 내 개수 기준으로 재정렬
    final indexed = List.generate(posts.length, (i) => MapEntry(posts[i], recentCounts[i]));
    indexed.sort((a, b) => b.value.compareTo(a.value));

    return indexed.map((e) => e.key).toList();
  }

  // 🌟 새 글 작성 후 돌아오면 목록을 다시 계산해서 새로고침 없이 바로 반영합니다.
  Future<void> _openWriteScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CommunityWriteScreen()),
    );
    _refetch();
  }

  // 🌟 상세 페이지에서 수정/삭제/좋아요 등 무엇을 했든, 돌아오면 목록을 다시 계산해서
  // 새로고침 없이도 바로 반영되게 합니다.
  Future<void> _openDetail(CommunityPost post) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityDetailScreen(postId: post.id),
      ),
    );
    _refetch();
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CommunitySearchScreen()),
    );
  }

  // 🌟 피드 카드에서 태그를 누르면 그 태그로 검색된 결과 화면으로 이동
  void _openTagSearch(String tag) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CommunitySearchScreen(initialQuery: '#$tag')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: GestureDetector(
          onTap: _scrollToTop,
          child: const Text('얌얌북',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
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
    final bool showPeriodRow =
        _sortOption == SortOption.likes || _sortOption == SortOption.scrap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
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
        ),
        // 🌟 좋아요순/스크랩순 선택 시에만 전체/일간/주간 기간 필터 노출
        if (showPeriodRow)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Row(
              children: [
                _periodChip('전체', SortPeriod.all),
                const SizedBox(width: 6),
                _periodChip('일간', SortPeriod.daily),
                const SizedBox(width: 6),
                _periodChip('주간', SortPeriod.weekly),
              ],
            ),
          ),
      ],
    );
  }

  Widget _sortTabButton(String label, SortOption option) {
    final bool selected = _sortOption == option;
    return GestureDetector(
      onTap: () => _changeSortOption(option),
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

  Widget _periodChip(String label, SortPeriod period) {
    final bool selected = _sortPeriod == period;
    return GestureDetector(
      onTap: () => _changeSortPeriod(period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFF8A3D) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildPostList() {
    return FutureBuilder<List<CommunityPost>>(
      future: _postsFuture,
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

        final posts = snapshot.data!;

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
                  : RefreshIndicator(
                // 🌟 실시간 스트림이 아니라 Future 기반이라, 당겨서 새로고침으로 최신 값을 다시 계산합니다.
                onRefresh: () async => _refetch(),
                child: ListView.separated(
                  controller: _scrollController, // 🌟 여기(메인 화면 리스트)에 연결
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: posts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) => _buildPostCard(posts[index]),
                ),
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
            // 🌟 이모티콘 토큰([emoji:xxx.svg])을 실제 이미지로 인라인 렌더링 (상세페이지와 동일)
            EmoticonRichContent(
              content: post.content,
              emojiSize: 16,
              style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black),
            ),
            // 🌟 태그 표시 - 상세 페이지와 동일하게, 누르면 해당 태그로 검색 화면 이동
            if (post.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: post.tags.map((tag) {
                  return GestureDetector(
                    onTap: () => _openTagSearch(tag),
                    child: Text(
                      '#$tag',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFF8A3D),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (post.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 10),
              PostImageCarousel(imageUrls: post.imageUrls),
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