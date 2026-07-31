import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'community_post.dart';
import 'community_write.dart';
import 'community_detail.dart';
import 'community_search.dart';
import 'widgets/community_sort_bar.dart';
import 'widgets/community_post_card.dart';

class CommunityMainScreen extends StatefulWidget {
  const CommunityMainScreen({super.key});

  @override
  State<CommunityMainScreen> createState() => _CommunityMainScreenState();
}

class _CommunityMainScreenState extends State<CommunityMainScreen> {
  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color creamyIvory = Color(0xFFFFFDF9);
  static const Color subTextColor = Color(0xFF7A6B63);

  SortOption _sortOption = SortOption.latest;
  SortPeriod _sortPeriod = SortPeriod.all;
  final ScrollController _scrollController = ScrollController();

  late Future<List<CommunityPost>> _postsFuture;
  static const int _candidatePoolSize = 100;

  @override
  void initState() {
    super.initState();
    _postsFuture = _fetchRankedPosts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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

  Future<List<CommunityPost>> _fetchRankedPosts() async {
    final bool isPeriodApplicable =
        _sortOption == SortOption.likes || _sortOption == SortOption.scrap;

    if (_sortPeriod == SortPeriod.all || !isPeriodApplicable) {
      final snap = await _buildQuery().get();
      return snap.docs.map((d) => CommunityPost.fromFirestore(d)).toList();
    }

    final String subcollection = _sortOption == SortOption.likes ? 'post_like' : 'post_scrap';
    final String timestampField = _sortOption == SortOption.likes ? 'likedAt' : 'scrappedAt';

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

    final indexed = List.generate(posts.length, (i) => MapEntry(posts[i], recentCounts[i]));
    indexed.sort((a, b) => b.value.compareTo(a.value));

    return indexed.map((e) => e.key).toList();
  }

  Future<void> _openWriteScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CommunityWriteScreen()),
    );
    _refetch();
  }

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

  void _openTagSearch(String tag) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CommunitySearchScreen(initialQuery: '#$tag')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamyIvory,
      appBar: AppBar(
        title: GestureDetector(
          onTap: _scrollToTop,
          child: const Text(
            '얌얌북',
            style: TextStyle(color: deepChocolate, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: creamyIvory,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: deepChocolate),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: deepChocolate),
            onPressed: _openSearch,
          ),
        ],
      ),
      body: Column(
        children: [
          CommunitySortBar(
            currentOption: _sortOption,
            currentPeriod: _sortPeriod,
            onOptionChanged: _changeSortOption,
            onPeriodChanged: _changeSortPeriod,
          ),
          Expanded(child: _buildPostList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: pointCoralRed,
        elevation: 3,
        onPressed: _openWriteScreen,
        child: const Icon(Icons.edit, color: Colors.white),
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
                style: TextStyle(color: subTextColor, fontSize: 13),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: deepChocolate));
        }

        final posts = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(
                '총 ${posts.length}개',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: deepChocolate,
                ),
              ),
            ),
            Expanded(
              child: posts.isEmpty
                  ? const Center(
                child: Text(
                  '아직 등록된 글이 없어요.',
                  style: TextStyle(color: subTextColor),
                ),
              )
                  : RefreshIndicator(
                color: pointCoralRed,
                backgroundColor: Colors.white,
                onRefresh: () async => _refetch(),
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: posts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return CommunityPostCard(
                      post: post,
                      onTap: () => _openDetail(post),
                      onTagTap: _openTagSearch,
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}