import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'community_post.dart';
import '../../common/user_data.dart';
import '../../services/auth_service.dart';
import 'community_write.dart';
import 'community_detail.dart';
import 'community_search.dart';

enum FeedTab { all, mine, scrap }
enum SortOption { latest, likes, comments, scrap }

class CommunityMainScreen extends StatefulWidget {
  const CommunityMainScreen({Key? key}) : super(key: key);

  @override
  State<CommunityMainScreen> createState() => _CommunityMainScreenState();
}

class _CommunityMainScreenState extends State<CommunityMainScreen> {
  FeedTab _feedTab = FeedTab.all;
  SortOption _sortOption = SortOption.latest;

  String? get _myUid => AuthService.currentUser?.uid ?? UserData.uid;

  String get _sortLabel {
    switch (_sortOption) {
      case SortOption.latest:
        return '최신순';
      case SortOption.likes:
        return '좋아요순';
      case SortOption.comments:
        return '댓글순';
      case SortOption.scrap:
        return '스크랩순';
    }
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

  /// 🌟 얌얌북과 동일하게, 피드탭(전체/내 피드/스크랩)만 서버 쿼리에 반영합니다.
  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> query =
    FirebaseFirestore.instance.collection('community_posts');

    if (_feedTab == FeedTab.mine) {
      final uid = _myUid;
      query = query.where('userId', isEqualTo: uid ?? '__none__'); // 🌟 authorId → userId
    } else if (_feedTab == FeedTab.scrap) {
      final uid = _myUid;
      query = query.where('scrappedBy', arrayContains: uid ?? '__none__');
    }

    query = query.orderBy(_sortField, descending: true);
    return query;
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
          _buildFeedTabRow(),
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

  Widget _buildFeedTabRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _feedTabButton('전체', FeedTab.all),
          const SizedBox(width: 8),
          _feedTabButton('내 피드', FeedTab.mine),
          const SizedBox(width: 8),
          _feedTabButton('스크랩', FeedTab.scrap),
        ],
      ),
    );
  }

  Widget _feedTabButton(String label, FeedTab tab) {
    final bool selected = _feedTab == tab;
    return OutlinedButton(
      onPressed: () => setState(() => _feedTab = tab),
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? Colors.white : Colors.black87,
        backgroundColor: selected ? Colors.black : Colors.white,
        side: BorderSide(color: selected ? Colors.black : Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildSortRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          debugPrint('🔴 [Community] 쿼리 실패: ${snapshot.error}');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '글을 불러오는 중 오류가 발생했습니다.\n(색인이 아직 준비 중일 수 있어요)',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
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

  // 🌟 얌얌북 스타일 카드: 헤더(아바타+닉네임+위치 아이콘+시간) + 본문 + 큰 이미지 캐러셀 + 텍스트형 통계
  Widget _buildPostCard(CommunityPost post) {
    return GestureDetector(
      onTap: () => _openDetail(post),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFF5F5F5),
                  backgroundImage: post.authorProfileImage != null
                      ? NetworkImage(post.authorProfileImage!)
                      : null,
                  child: post.authorProfileImage == null
                      ? const Icon(Icons.person_outline, size: 18, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(post.authorNickname ?? '익명',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(width: 4),
                const Icon(Icons.location_on, size: 15, color: Color(0xFFFF8A3D)),
                const Spacer(),
                Text(_formatTime(post.createdAt),
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
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

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${time.month}/${time.day}';
  }
}

// 🌟 이미지 여러 장을 스와이프로 넘겨보는 캐러셀 (얌얌북 화면의 점 인디케이터 재현)
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
