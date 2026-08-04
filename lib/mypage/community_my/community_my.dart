import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../common/user_data.dart';

import '../../community/community_post.dart';
import '../../community/community_detail.dart';
import '../../community/community_search.dart';
import '../../community/widgets/community_post_card.dart';

class CommunityMyScreen extends StatefulWidget {
  const CommunityMyScreen({Key? key}) : super(key: key);

  @override
  State<CommunityMyScreen> createState() => _CommunityMyScreenState();
}

class _CommunityMyScreenState extends State<CommunityMyScreen> {
  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color creamyIvory = Color(0xFFFFFDF9);
  static const Color subTextColor = Color(0xFF7A6B63);

  String _selectedFilter = '전체';
  String _selectedSort = '최신순';

  final ScrollController _scrollController = ScrollController();
  bool _showBackToTopButton = false;

  late Future<List<Map<String, dynamic>>> _feedsFuture;

  @override
  void initState() {
    super.initState();
    _feedsFuture = _loadMyFeeds();

    _scrollController.addListener(() {
      if (_scrollController.offset >= 400 && !_showBackToTopButton) {
        setState(() => _showBackToTopButton = true);
      } else if (_scrollController.offset < 400 && _showBackToTopButton) {
        setState(() => _showBackToTopButton = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refetch() async {
    setState(() {
      _feedsFuture = _loadMyFeeds();
    });
    await _feedsFuture;
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  Future<List<Map<String, dynamic>>> _loadMyFeeds() async {
    List<Map<String, dynamic>> combinedFeeds = [];
    Set<String> uniqueIds = {};

    final String uid = UserData.uid ?? '';
    if (uid.isEmpty) {
      debugPrint('유저 UID가 없습니다.');
      return [];
    }

    try {
      if (_selectedFilter == '전체' || _selectedFilter == '내 피드') {
        final myPostsSnapshot = await FirebaseFirestore.instance
            .collection('posts')
            .where('userId', isEqualTo: uid)
            .where('status', whereIn: ['active', 'hidden', 'admin_deleted'])
            .get();

        for (var doc in myPostsSnapshot.docs) {
          final data = doc.data();

          if (data['status'] == 'active' || data['status'] == 'hidden' || data['status'] == 'admin_deleted') {
            if (!uniqueIds.contains(doc.id)) {
              combinedFeeds.add({...data, 'postId': doc.id, 'id': doc.id});
              uniqueIds.add(doc.id);
            }
          }
        }
      }

      if (_selectedFilter == '전체' || _selectedFilter == '스크랩') {
        final scrapSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('users_myscrap')
            .get();

        for (var scrapDoc in scrapSnapshot.docs) {
          final String postId = scrapDoc.id;

          if (!uniqueIds.contains(postId)) {
            final postDoc = await FirebaseFirestore.instance
                .collection('posts')
                .doc(postId)
                .get();

            if (postDoc.exists) {
              final postData = postDoc.data() as Map<String, dynamic>;

              if (postData['status'] == 'active') {
                final scrapData = scrapDoc.data();

                combinedFeeds.add({
                  ...postData,
                  'postId': postId,
                  'id': postId,
                  'scrapedAt': scrapData['scrapedAt']
                });
                uniqueIds.add(postId);
              }
            }
          }
        }
      }

      if (_selectedSort == '최신순') {
        combinedFeeds.sort((a, b) {
          final aTime = (a['scrapedAt'] as Timestamp?)?.toDate() ?? (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
          final bTime = (b['scrapedAt'] as Timestamp?)?.toDate() ?? (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
          return bTime.compareTo(aTime);
        });
      } else if (_selectedSort == '좋아요순') {
        combinedFeeds.sort((a, b) => (b['likeCount'] ?? 0).compareTo(a['likeCount'] ?? 0));
      } else if (_selectedSort == '댓글순') {
        combinedFeeds.sort((a, b) => (b['commentCount'] ?? 0).compareTo(a['commentCount'] ?? 0));
      } else if (_selectedSort == '스크랩순') {
        combinedFeeds.sort((a, b) => (b['scrapCount'] ?? 0).compareTo(a['scrapCount'] ?? 0));
      }

    } catch (e) {
      debugPrint('피드 로드 에러: $e');
    }

    return combinedFeeds;
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
          child: const Text('내 얌얌북', style: TextStyle(color: deepChocolate, fontWeight: FontWeight.bold)),
        ),
        backgroundColor: creamyIvory,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: deepChocolate),
      ),
      // 🌟 좌측 하단에 최상단 이동 버튼 배치
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start, // 왼쪽 정렬
          children: [
            AnimatedOpacity(
              opacity: _showBackToTopButton ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: FloatingActionButton(
                heroTag: 'my_community_top_btn',
                backgroundColor: pointCoralRed,
                elevation: 3,
                onPressed: _showBackToTopButton ? _scrollToTop : null,
                child: const Icon(Icons.arrow_upward, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilterButtons(),
                const SizedBox(height: 12),
                _buildSortButtons(),
              ],
            ),
          ),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _feedsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: deepChocolate));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      '데이터를 불러오는 중 에러가 발생했습니다.',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  );
                }

                final feeds = snapshot.data ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                      child: Text(
                        '총 ${feeds.length}개',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: deepChocolate,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: RefreshIndicator(
                        color: pointCoralRed,
                        backgroundColor: Colors.white,
                        onRefresh: _refetch,
                        child: feeds.isEmpty
                            ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: const Center(
                                child: Text('조건에 맞는 피드가 없습니다.', style: TextStyle(color: subTextColor)),
                              ),
                            ),
                          ],
                        )
                            : ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 80.0), // 버튼과 겹치지 않도록 하단 여백 추가
                          itemCount: feeds.length,
                          itemBuilder: (context, index) {
                            final feed = feeds[index];

                            final bool isHidden = feed['status'] == 'hidden';
                            final bool isAdminDeleted = feed['status'] == 'admin_deleted';
                            final bool isRestricted = isHidden || isAdminDeleted;

                            final post = CommunityPost.fromMap(feed, feed['postId'] ?? feed['id'] ?? '');

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (isHidden)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 8.0),
                                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(12.0),
                                        border: Border.all(color: Colors.orange.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.visibility_off, size: 16, color: Colors.orange.shade700),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '신고 누적으로 인해 관리자에 의해 비공개 처리되었습니다.',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.orange.shade800,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  if (isAdminDeleted)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 8.0),
                                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(12.0),
                                        border: Border.all(color: Colors.red.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, size: 16, color: Colors.red.shade400),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '커뮤니티 가이드라인 위반으로 관리자에 의해 삭제된 게시글입니다.',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.red.shade600,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  Opacity(
                                    opacity: isRestricted ? 0.6 : 1.0,
                                    child: CommunityPostCard(
                                      post: post,
                                      onTap: () async {
                                        final String postId = post.id;
                                        if (postId.isNotEmpty) {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => CommunityDetailScreen(postId: postId),
                                            ),
                                          );
                                          _refetch();
                                        }
                                      },
                                      onTagTap: _openTagSearch,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    List<String> filters = ['전체', '내 피드', '스크랩'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          bool isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                if (_selectedFilter != filter) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                  _refetch();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? pointCoralRed : deepChocolate.withOpacity(0.15),
                  ),
                  color: isSelected ? pointCoralRed : Colors.white,
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected ? Colors.white : subTextColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSortButtons() {
    List<String> sorts = ['최신순', '좋아요순', '댓글순', '스크랩순'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: sorts.map((sort) {
          bool isSelected = _selectedSort == sort;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                if (_selectedSort != sort) {
                  setState(() {
                    _selectedSort = sort;
                  });
                  _refetch();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? deepChocolate : deepChocolate.withOpacity(0.15),
                  ),
                  color: isSelected ? deepChocolate : Colors.white,
                ),
                child: Text(
                  sort,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected ? Colors.white : subTextColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}