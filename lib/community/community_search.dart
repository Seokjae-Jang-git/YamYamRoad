import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'community_post.dart';
import 'community_detail.dart';

// 🌟 커뮤니티 검색 화면
// - 내용/닉네임/지역/카테고리에 검색어가 포함된 글을 찾아줍니다.
// - Firestore는 부분 문자열 검색을 기본 지원하지 않기 때문에,
//   최근 글들을 불러온 뒤 클라이언트에서 필터링하는 방식으로 구현했습니다.
class CommunitySearchScreen extends StatefulWidget {
  const CommunitySearchScreen({Key? key}) : super(key: key);

  @override
  State<CommunitySearchScreen> createState() => _CommunitySearchScreenState();
}

class _CommunitySearchScreenState extends State<CommunitySearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(CommunityPost post, String query) {
    if (query.isEmpty) return false;
    final q = query.toLowerCase();
    return post.content.toLowerCase().contains(q) ||
        (post.authorNickname ?? '').toLowerCase().contains(q) ||
        post.region.toLowerCase().contains(q) ||
        post.category.toLowerCase().contains(q);
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
          decoration: InputDecoration(
            hintText: '내용, 닉네임, 지역, 카테고리로 검색',
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
      body: _query.isEmpty
          ? const Center(
        child: Text('검색어를 입력해주세요.', style: TextStyle(color: Colors.grey, fontSize: 13)),
      )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('community_posts')
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
      ),
    );
  }

  Widget _buildResultTile(CommunityPost post) {
    return GestureDetector(
      onTap: () => _openDetail(post),
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
                    Text(post.authorNickname ?? '익명',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 6),
                    Text('${post.region} · ${post.category}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
