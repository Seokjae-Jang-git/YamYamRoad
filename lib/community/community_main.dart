import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'community_post.dart';
import '../../common/user_data.dart';
import 'community_write.dart';
import 'community_detail.dart';

// 🌟 필터 모드: 지역별 / 메뉴별
enum FilterMode { region, category }

// 🌟 피드 탭: 전체 / 내 피드 / 스크랩
enum FeedTab { all, mine, scrap }

// 🌟 정렬 옵션
enum SortOption { latest, likes, comments, scrap }

class CommunityMainScreen extends StatefulWidget {
  const CommunityMainScreen({Key? key}) : super(key: key);

  @override
  State<CommunityMainScreen> createState() => _CommunityMainScreenState();
}

class _CommunityMainScreenState extends State<CommunityMainScreen> {
  FilterMode _filterMode = FilterMode.region;
  FeedTab _feedTab = FeedTab.all;
  SortOption _sortOption = SortOption.latest;

  String _selectedChip = '전체';

  final List<String> _regionChips = ['전체', '성수동', '가로수길', '이태원'];
  final List<String> _categoryChips = ['전체', '빵', '떡', '음료', '유행상품'];

  List<String> get _currentChips =>
      _filterMode == FilterMode.region ? _regionChips : _categoryChips;

  // 🌟 필터 모드가 바뀌면 선택된 칩도 '전체'로 초기화
  void _switchFilterMode(FilterMode mode) {
    setState(() {
      _filterMode = mode;
      _selectedChip = '전체';
    });
  }

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

  // 🌟 Firestore 쿼리를 현재 필터/탭/정렬 조건에 맞춰 조립
  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> query =
    FirebaseFirestore.instance.collection('community_posts');

    if (_selectedChip != '전체') {
      if (_filterMode == FilterMode.region) {
        query = query.where('region', isEqualTo: _selectedChip);
      } else {
        query = query.where('category', isEqualTo: _selectedChip);
      }
    }

    if (_feedTab == FeedTab.mine) {
      query = query.where('authorId', isEqualTo: 'test_user_01');
    } else if (_feedTab == FeedTab.scrap) {
      query = query.where('scrappedBy',
          arrayContains: 'test_user_01');
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
            onPressed: () {
              // TODO: 검색 기능은 추후 구현
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterModeToggle(),
          _buildChipRow(),
          const Divider(height: 1),
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

  // 지역별 / 메뉴별 토글
  Widget _buildFilterModeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildToggleText('지역별', FilterMode.region),
          const SizedBox(width: 16),
          _buildToggleText('메뉴별', FilterMode.category),
        ],
      ),
    );
  }

  Widget _buildToggleText(String label, FilterMode mode) {
    final bool selected = _filterMode == mode;
    return GestureDetector(
      onTap: () => _switchFilterMode(mode),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 18,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? const Color(0xFFFF8A3D) : Colors.grey,
        ),
      ),
    );
  }

  // 지역/카테고리 칩 목록
  Widget _buildChipRow() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _currentChips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chip = _currentChips[index];
          final bool selected = chip == _selectedChip;
          return ChoiceChip(
            label: Text(chip),
            selected: selected,
            selectedColor: const Color(0xFFFF8A3D),
            labelStyle: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontSize: 13,
            ),
            backgroundColor: const Color(0xFFF5F5F5),
            onSelected: (_) => setState(() => _selectedChip = chip),
          );
        },
      ),
    );
  }

  // 전체 / 내 피드 / 스크랩
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
        backgroundColor: selected ? const Color(0xFFFF8A3D) : Colors.white,
        side: BorderSide(color: selected ? const Color(0xFFFF8A3D) : Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  // 정렬 옵션 + 총 개수 표시는 리스트 StreamBuilder 안에서 함께 처리
  Widget _buildSortRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          PopupMenuButton<SortOption>(
            initialValue: _sortOption,
            onSelected: (value) => setState(() => _sortOption = value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: SortOption.latest, child: Text('최신순')),
              PopupMenuItem(value: SortOption.likes, child: Text('좋아요순')),
              PopupMenuItem(value: SortOption.comments, child: Text('댓글순')),
              PopupMenuItem(value: SortOption.scrap, child: Text('스크랩순')),
            ],
            child: Row(
              children: [
                Text(_sortLabel, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const Icon(Icons.arrow_drop_down, size: 18, color: Colors.black54),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _buildQuery().snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('글을 불러오는 중 오류가 발생했습니다.'));
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
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _buildPostCard(posts[index]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    final bool isMine = post.authorId == ('test_user_01');
    return GestureDetector(
      onTap: () => _openDetail(post),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
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
                Text(post.authorNickname ?? '알 수 없는 유저',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 6),
                if (isMine)
                  const Text('(내 글)', style: TextStyle(fontSize: 11, color: Colors.orange)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              post.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.favorite_border, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${post.likeCount}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 12),
                const Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${post.commentCount}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 12),
                const Icon(Icons.bookmark_border, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${post.scrapCount}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
