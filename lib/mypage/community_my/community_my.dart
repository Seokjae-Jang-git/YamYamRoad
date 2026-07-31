import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../common/user_data.dart';
import 'widgets/feed_card_widget.dart';

// 🌟 디렉토리 구조에 맞춰 상세 화면 import 추가
import '../../community/community_detail.dart';

class CommunityMyScreen extends StatefulWidget {
  const CommunityMyScreen({Key? key}) : super(key: key);

  @override
  State<CommunityMyScreen> createState() => _CommunityMyScreenState();
}

class _CommunityMyScreenState extends State<CommunityMyScreen> {
  String _selectedFilter = '전체';
  String _selectedSort = '최신순';

  // 🌟 내 피드와 내 스크랩을 필터에 맞게 조합하여 가져오는 함수
  Future<List<Map<String, dynamic>>> _loadMyFeeds() async {
    List<Map<String, dynamic>> combinedFeeds = [];
    Set<String> uniqueIds = {}; // 내 피드를 내가 스크랩했을 경우 중복 표출 방지

    try {
      // 1. '내 피드' 로드 (필터가 '전체' 이거나 '내 피드' 일 때)
      if (_selectedFilter == '전체' || _selectedFilter == '내 피드') {
        final myPostsSnapshot = await FirebaseFirestore.instance
            .collection('posts')
            .where('userId', isEqualTo: UserData.uid)
            .where('status', isEqualTo: 'active')
            .get();

        for (var doc in myPostsSnapshot.docs) {
          if (!uniqueIds.contains(doc.id)) {
            combinedFeeds.add({...doc.data(), 'postId': doc.id});
            uniqueIds.add(doc.id);
          }
        }
      }

      // 2. '내 스크랩' 로드 (필터가 '전체' 이거나 '스크랩' 일 때)
      if (_selectedFilter == '전체' || _selectedFilter == '스크랩') {
        final scrapSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(UserData.uid)
            .collection('users_myscrap')
            .get();

        for (var scrapDoc in scrapSnapshot.docs) {
          if (!uniqueIds.contains(scrapDoc.id)) {
            final postDoc = await FirebaseFirestore.instance
                .collection('posts')
                .doc(scrapDoc.id)
                .get();

            if (postDoc.exists) {
              final data = postDoc.data() as Map<String, dynamic>;
              if (data['status'] == 'active') {
                // 스크랩 정렬을 위해 스크랩한 시간 정보 추가
                combinedFeeds.add({
                  ...data,
                  'postId': postDoc.id,
                  'scrapedAt': scrapDoc.data()['scrapedAt']
                });
                uniqueIds.add(scrapDoc.id);
              }
            }
          }
        }
      }

      // 3. 선택된 정렬 기준에 따라 리스트 정렬
      if (_selectedSort == '최신순') {
        combinedFeeds.sort((a, b) {
          final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
          final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('얌얌북', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade300, height: 1.0),
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

          // 🌟 FutureBuilder를 통해 조합된 피드 리스트를 렌더링
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadMyFeeds(), // 상태(_selectedFilter, _selectedSort)가 바뀔 때마다 재호출됨
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.black));
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
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                          '총 ${feeds.length} 개',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: feeds.isEmpty
                          ? const Center(child: Text('조건에 맞는 피드가 없습니다.', style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: feeds.length,
                        itemBuilder: (context, index) {
                          final feed = feeds[index];

                          return GestureDetector(
                            onTap: () {
                              final String postId = feed['postId'] ?? '';
                              if (postId.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CommunityDetailScreen(postId: postId),
                                  ),
                                );
                              }
                            },
                            child: FeedCardWidget(feed: feed),
                          );
                        },
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
    return Row(
      children: filters.map((filter) {
        bool isSelected = _selectedFilter == filter;
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: InkWell(
            onTap: () => setState(() => _selectedFilter = filter), // setState로 FutureBuilder 트리거
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: isSelected ? Colors.black : Colors.grey.shade300),
                color: isSelected ? Colors.black : Colors.white,
              ),
              child: Text(
                  filter,
                  style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                  )
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSortButtons() {
    List<String> sorts = ['최신순', '좋아요순', '댓글순', '스크랩순'];
    return Row(
      children: sorts.map((sort) {
        bool isSelected = _selectedSort == sort;
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: InkWell(
            onTap: () => setState(() => _selectedSort = sort), // setState로 FutureBuilder 트리거
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: isSelected ? Colors.black : Colors.grey.shade300),
                color: isSelected ? Colors.black : Colors.white,
              ),
              child: Text(
                  sort,
                  style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                  )
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}