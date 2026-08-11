import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'community_post.dart';
import 'community_detail.dart';

// 🌟 커뮤니티 검색 화면
// - 내용/닉네임/태그에 검색어가 포함된 글을 찾아줍니다.
// - Firestore는 부분 문자열 검색을 기본 지원하지 않기 때문에,
//   최근 글들을 불러온 뒤 클라이언트에서 필터링하는 방식으로 구현했습니다.
// - 최근 검색어는 기기 로컬(SharedPreferences)에 저장되어 검색창을 비웠을 때 노출됩니다.
class CommunitySearchScreen extends StatefulWidget {
  // 🌟 게시글의 태그를 눌러서 들어올 때 검색어를 미리 채워줍니다. (예: '#빵')
  final String? initialQuery;

  const CommunitySearchScreen({Key? key, this.initialQuery}) : super(key: key);

  @override
  State<CommunitySearchScreen> createState() => _CommunitySearchScreenState();
}

class _CommunitySearchScreenState extends State<CommunitySearchScreen> {
  static const String _recentSearchKey = 'community_recent_searches';
  static const int _maxRecentSearches = 10;

  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      _query = widget.initialQuery!.trim();
      _searchController.text = _query;
      _saveRecentSearch(_query);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 🌟 로컬(SharedPreferences)에서 최근 검색어 목록을 불러옵니다.
  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_recentSearchKey) ?? [];
    setState(() => _recentSearches = saved);
  }

  // 🌟 검색어를 최근 검색어 목록 맨 앞에 추가하고 로컬에 저장합니다.
  //    (중복 제거 + 최대 개수 제한)
  Future<void> _saveRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final updated = List<String>.from(_recentSearches);
    updated.removeWhere((e) => e.toLowerCase() == trimmed.toLowerCase());
    updated.insert(0, trimmed);
    if (updated.length > _maxRecentSearches) {
      updated.removeRange(_maxRecentSearches, updated.length);
    }

    await prefs.setStringList(_recentSearchKey, updated);
    setState(() => _recentSearches = updated);
  }

  // 🌟 최근 검색어 하나만 삭제합니다.
  Future<void> _removeRecentSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final updated = List<String>.from(_recentSearches)..remove(query);
    await prefs.setStringList(_recentSearchKey, updated);
    setState(() => _recentSearches = updated);
  }

  // 🌟 최근 검색어를 전체 삭제합니다.
  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchKey);
    setState(() => _recentSearches = []);
  }

  // 🌟 최근 검색어 탭 시 해당 검색어로 바로 검색을 실행합니다.
  void _onRecentSearchTap(String query) {
    _searchController.text = query;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    setState(() => _query = query);
    _saveRecentSearch(query);
  }

  // 🌟 검색어를 제출(엔터/완료)했을 때 최근 검색어에 저장합니다.
  void _onSubmitted(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    setState(() => _query = trimmed);
    _saveRecentSearch(trimmed);
  }

  bool _matches(CommunityPost post, String query) {
    if (query.isEmpty) return false;
    final q = query.toLowerCase();
    // 🌟 '#'을 붙여 검색하면 태그만 정확히 매칭합니다. (예: #빵)
    if (q.startsWith('#')) {
      final tagQuery = q.substring(1);
      if (tagQuery.isEmpty) return false;
      return post.tags.any((tag) => tag.toLowerCase().contains(tagQuery));
    }

    return post.content.toLowerCase().contains(q) ||
        (post.nickname ?? '').toLowerCase().contains(q) ||
        post.tags.any((tag) => tag.toLowerCase().contains(q));
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
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: (value) => setState(() => _query = value.trim()),
          onSubmitted: _onSubmitted,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: '내용, 닉네임, #태그로 검색',
            hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
              icon: const Icon(Icons.close, size: 18, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
          ),
        ),
      ),
      body: _query.isEmpty ? _buildRecentSearches() : _buildSearchResults(),
    );
  }

  // 🌟 검색어가 비어있을 때: 최근 검색어 목록을 보여줍니다.
  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return const Center(
        child: Text('검색어를 입력해주세요. (예: #빵)', style: TextStyle(color: Colors.grey, fontSize: 13)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('최근 검색어',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              GestureDetector(
                onTap: _clearRecentSearches,
                child: const Text('전체 삭제',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _recentSearches.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final query = _recentSearches[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time, size: 18, color: Colors.grey),
                title: Text(query, style: const TextStyle(fontSize: 13)),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                  onPressed: () => _removeRecentSearch(query),
                ),
                onTap: () => _onRecentSearchTap(query),
              );
            },
          ),
        ),
      ],
    );
  }

  // 🌟 검색어가 있을 때: Firestore에서 불러온 글을 클라이언트에서 필터링해 보여줍니다.
  Widget _buildSearchResults() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(200)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('검색 중 오류가 발생했어요.', style: TextStyle(color: Colors.grey)),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Colors.black));
        }

        final posts = snapshot.data!.docs
            .map((d) => CommunityPost.fromFirestore(d))
            .where((p) => _matches(p, _query))
            .toList();

        if (posts.isEmpty) {
          return const Center(
            child: Text('검색 결과가 없어요.', style: TextStyle(color: Colors.grey, fontSize: 13)),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: posts.length,
          separatorBuilder: (_, __) => const Divider(height: 24),
          itemBuilder: (context, index) => _buildResultTile(posts[index]),
        );
      },
    );
  }

  Widget _buildResultTile(CommunityPost post) {
    return GestureDetector(
      onTap: () {
        _saveRecentSearch(_query);
        _openDetail(post);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.imageUrls.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                post.imageUrls.first,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(post.nickname ?? '익명',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    if (post.tags.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          post.tags.map((t) => '#$t').join(' '),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  post.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, height: 1.3),
                ),
                const SizedBox(height: 4),
                Text(
                  '좋아요 ${post.likeCount}   댓글 ${post.commentCount}   스크랩 ${post.scrapCount}',
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}