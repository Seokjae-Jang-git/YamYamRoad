import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../common/user_data.dart';
import 'repository/community_my_repository.dart';
import 'widgets/feed_card_widget.dart';

class CommunityMyScreen extends StatefulWidget {
  const CommunityMyScreen({Key? key}) : super(key: key);

  @override
  State<CommunityMyScreen> createState() => _CommunityMyScreenState();
}

class _CommunityMyScreenState extends State<CommunityMyScreen> {
  String _selectedFilter = '전체';
  String _selectedSort = '최신순';

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
          Expanded(
            child: _selectedFilter == '스크랩'
                ? StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(UserData.uid)
                  .collection('users_myscrap')
                  .orderBy('scrapedAt', descending: true) // 🌟 scrapedAt 으로 맞춤
                  .snapshots(),
              builder: (context, scrapSnapshot) {
                if (scrapSnapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        '에러 발생:\n${scrapSnapshot.error}',
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (scrapSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.black));
                }

                final scrapDocs = scrapSnapshot.data?.docs ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('총 ${scrapDocs.length} 개', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: scrapDocs.isEmpty
                          ? const Center(child: Text('스크랩한 피드가 없습니다.', style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: scrapDocs.length,
                        itemBuilder: (context, index) {
                          final scrapDoc = scrapDocs[index];
                          final String targetPostId = scrapDoc.id; // 문서 ID가 원본 피드 ID

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('posts').doc(targetPostId).get(),
                            builder: (context, postSnapshot) {
                              if (postSnapshot.connectionState == ConnectionState.waiting) {
                                return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: Colors.black, strokeWidth: 1.5)));
                              }

                              if (!postSnapshot.hasData || !postSnapshot.data!.exists) {
                                return const SizedBox.shrink();
                              }

                              final originFeed = postSnapshot.data!.data() as Map<String, dynamic>;
                              originFeed['postId'] = postSnapshot.data!.id;

                              return FeedCardWidget(feed: originFeed);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            )
                : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .where('status', isEqualTo: 'active')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.black));
                }

                final List<Map<String, dynamic>> processedFeeds = CommunityMyRepository.processFeeds(
                  docs: snapshot.data?.docs ?? [],
                  selectedFilter: _selectedFilter,
                  selectedSort: _selectedSort,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('총 ${processedFeeds.length} 개', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: processedFeeds.isEmpty
                          ? const Center(child: Text('조건에 맞는 피드가 없습니다.', style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: processedFeeds.length,
                        itemBuilder: (context, index) => FeedCardWidget(feed: processedFeeds[index]),
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
            onTap: () => setState(() => _selectedFilter = filter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: isSelected ? Colors.black : Colors.grey.shade300),
                color: isSelected ? Colors.black : Colors.white,
              ),
              child: Text(filter, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
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
            onTap: () => setState(() => _selectedSort = sort),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: isSelected ? Colors.black : Colors.grey.shade300),
                color: isSelected ? Colors.black : Colors.white,
              ),
              child: Text(sort, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ),
          ),
        );
      }).toList(),
    );
  }
}