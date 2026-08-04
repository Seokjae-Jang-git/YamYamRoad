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

    // UID 안정성 체크
    final String uid = UserData.uid ?? '';
    if (uid.isEmpty) {
      debugPrint('유저 UID가 없습니다.');
      return [];
    }

    try {
      // 1. '내 피드' 로드 (필터가 '전체' 이거나 '내 피드' 일 때)
      if (_selectedFilter == '전체' || _selectedFilter == '내 피드') {
        final myPostsSnapshot = await FirebaseFirestore.instance
            .collection('posts')
            .where('userId', isEqualTo: uid)
        // 🌟 수정됨: active, hidden, admin_deleted 상태 모두 불러오기
            .where('status', whereIn: ['active', 'hidden', 'admin_deleted'])
            .get();

        for (var doc in myPostsSnapshot.docs) {
          final data = doc.data();

          // 🌟 방어 코드: 허용된 3가지 상태만 확실하게 필터링
          if (data['status'] == 'active' || data['status'] == 'hidden' || data['status'] == 'admin_deleted') {
            if (!uniqueIds.contains(doc.id)) {
              combinedFeeds.add({...data, 'postId': doc.id});
              uniqueIds.add(doc.id);
            }
          }
        }
      }

      // 2. '내 스크랩' 로드 (users_myscrap 활용)
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

              // 🌟 내 스크랩은 오직 'active' 상태일 때만 리스트에 추가
              if (postData['status'] == 'active') {
                final scrapData = scrapDoc.data();

                combinedFeeds.add({
                  ...postData,
                  'postId': postId,
                  'scrapedAt': scrapData['scrapedAt'] // 정렬을 위해 스크랩한 시간 기록
                });
                uniqueIds.add(postId);
              }
            }
          }
        }
      }

      // 3. 선택된 정렬 기준에 따라 리스트 정렬
      if (_selectedSort == '최신순') {
        combinedFeeds.sort((a, b) {
          // 스크랩된 글은 스크랩 시간 기준, 내 피드는 작성 시간 기준으로 정렬
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

                          // 🌟 상태 체크 (hidden 및 admin_deleted 분리)
                          final bool isHidden = feed['status'] == 'hidden';
                          final bool isAdminDeleted = feed['status'] == 'admin_deleted';
                          final bool isRestricted = isHidden || isAdminDeleted;

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
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16.0), // 카드 간격
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // 🌟 1-1. 비공개 안내 배너 (hidden일 때)
                                  if (isHidden)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 8.0),
                                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8.0),
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

                                  // 🌟 1-2. 삭제 안내 배너 (admin_deleted일 때)
                                  if (isAdminDeleted)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 8.0),
                                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8.0),
                                        border: Border.all(color: Colors.red.shade100),
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

                                  // 🌟 2. 원본 피드 카드 (비정상 상태일 경우 투명도를 낮춰 비활성화 느낌 강조)
                                  Opacity(
                                    opacity: isRestricted ? 0.6 : 1.0,
                                    child: FeedCardWidget(feed: feed),
                                  ),
                                ],
                              ),
                            ),
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