import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'community_post.dart';
import '../../common/user_data.dart';
import 'community_write.dart';

class CommunityDetailScreen extends StatefulWidget {
  final String postId;

  const CommunityDetailScreen({Key? key, required this.postId}) : super(key: key);

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  String get _currentUserId => 'test_user_01';

  // 🌟 게시글 삭제
  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('글 삭제'),
        content: const Text('이 글을 삭제하시겠어요? 삭제한 글은 복구할 수 없어요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('community_posts')
            .doc(widget.postId)
            .delete();
        if (mounted) Navigator.pop(context);
      } catch (e) {
        print('글 삭제 중 오류 발생: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('삭제에 실패했어요.')),
          );
        }
      }
    }
  }

  void _editPost(CommunityPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityWriteScreen(existingPost: post),
      ),
    );
  }

  // 🌟 신고 사유 선택 후 reports 컬렉션에 기록 + 게시글 reportCount 증가
  Future<void> _reportPost() async {
    final reasons = ['부적절한 내용', '스팸/광고', '욕설/비방', '허위 정보', '기타'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('신고 사유를 선택해주세요', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ...reasons.map((reason) => ListTile(
              title: Text(reason),
              onTap: () => Navigator.pop(context, reason),
            )),
          ],
        ),
      ),
    );

    if (selected == null) return;

    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'postId': widget.postId,
        'reporterId': _currentUserId,
        'reason': selected,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance
          .collection('community_posts')
          .doc(widget.postId)
          .update({'reportCount': FieldValue.increment(1)});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('신고가 접수되었습니다.')),
        );
      }
    } catch (e) {
      print('신고 처리 중 오류 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('신고 접수에 실패했어요.')),
        );
      }
    }
  }

  Future<void> _toggleLike(CommunityPost post) async {
    final ref = FirebaseFirestore.instance.collection('community_posts').doc(post.id);
    final liked = post.likedBy.contains(_currentUserId);
    await ref.update({
      'likedBy': liked
          ? FieldValue.arrayRemove([_currentUserId])
          : FieldValue.arrayUnion([_currentUserId]),
      'likeCount': FieldValue.increment(liked ? -1 : 1),
    });
  }

  Future<void> _toggleScrap(CommunityPost post) async {
    final ref = FirebaseFirestore.instance.collection('community_posts').doc(post.id);
    final scrapped = post.scrappedBy.contains(_currentUserId);
    await ref.update({
      'scrappedBy': scrapped
          ? FieldValue.arrayRemove([_currentUserId])
          : FieldValue.arrayUnion([_currentUserId]),
      'scrapCount': FieldValue.increment(scrapped ? -1 : 1),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('커뮤니티', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('community_posts')
            .doc(widget.postId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }
          if (!snapshot.data!.exists) {
            return const Center(child: Text('삭제되었거나 존재하지 않는 글이에요.'));
          }

          final post = CommunityPost.fromFirestore(snapshot.data!);
          final bool isMine = post.authorId == _currentUserId;
          final bool liked = post.likedBy.contains(_currentUserId);
          final bool scrapped = post.scrappedBy.contains(_currentUserId);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFF5F5F5),
                      backgroundImage: post.authorProfileImage != null
                          ? NetworkImage(post.authorProfileImage!)
                          : null,
                      child: post.authorProfileImage == null
                          ? const Icon(Icons.person_outline, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post.authorNickname ?? '알 수 없는 유저',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('${post.region} · ${post.category}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    // 🌟 본인 글이면 수정/삭제, 타인 글이면 신고 메뉴 노출
                    isMine
                        ? PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') _editPost(post);
                        if (value == 'delete') _deletePost();
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('수정')),
                        PopupMenuItem(value: 'delete', child: Text('삭제')),
                      ],
                    )
                        : PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'report') _reportPost();
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'report', child: Text('신고')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(post.content, style: const TextStyle(fontSize: 14)),
                if (post.imageUrls.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(post.imageUrls.first, fit: BoxFit.cover),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _toggleLike(post),
                      child: Icon(liked ? Icons.favorite : Icons.favorite_border,
                          size: 20, color: liked ? Colors.red : Colors.grey),
                    ),
                    const SizedBox(width: 4),
                    Text('좋아요 ${post.likeCount}', style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 16),
                    const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('댓글 ${post.commentCount}', style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => _toggleScrap(post),
                      child: Icon(scrapped ? Icons.bookmark : Icons.bookmark_border,
                          size: 20, color: scrapped ? const Color(0xFFFF8A3D) : Colors.grey),
                    ),
                    const SizedBox(width: 4),
                    Text('스크랩 ${post.scrapCount}', style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
