import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/user_data.dart';
import '../features/emoticon/emoticon_span_builder.dart';
import '../features/emoticon/emoticon_picker_sheet.dart';
import '../services/auth_service.dart';
import 'community_post.dart';
import 'community_comment.dart';
import 'community_write.dart';


class CommunityDetailScreen extends StatefulWidget {
  final String postId;

  const CommunityDetailScreen({Key? key, required this.postId}) : super(key: key);

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  String get _currentUserId => AuthService.currentUser?.uid ?? UserData.uid ?? 'unknown_uid';
  String get _currentUserNickname => UserData.nickname ?? '이름없음';

  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  // 🌟 대댓글 작성 중인 대상 (null이면 원댓글 작성 모드)
  CommunityComment? _replyTarget;

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

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
        debugPrint('글 삭제 중 오류 발생: $e');
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

    // 🌟 '기타' 선택 시 상세 사유 입력받기
    String? detail;
    if (selected == '기타') {
      detail = await _askReportDetail();
      if (detail == null || detail.trim().isEmpty) return; // 취소 시 신고 안 함
    }

    // 🌟 중복 신고 방지 (같은 유저가 같은 글 두 번 신고 못하게)
    final existing = await FirebaseFirestore.instance
        .collection('reports')
        .where('targetId', isEqualTo: widget.postId)
        .where('userId', isEqualTo: _currentUserId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 신고한 게시글이에요.')),
        );
      }
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'targetType': 'post',
        'targetId': widget.postId,
        'userId': _currentUserId,
        'reason': selected,
        'status': 'pending',
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
      debugPrint('신고 처리 중 오류 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('신고 접수에 실패했어요.')),
        );
      }
    }
  }

  Future<String?> _askReportDetail() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('신고 상세 사유'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: '구체적인 사유를 입력해주세요'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('확인')),
        ],
      ),
    );
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

  // 🌟 댓글/대댓글 등록
  // - _replyTarget이 null이면 원댓글로 등록됩니다.
  // - _replyTarget이 원댓글이면 그 댓글의 id가 parentId가 되고,
  //   _replyTarget이 이미 대댓글이면 같은 원댓글 아래로 묶이도록 parentId를 그대로 이어받습니다.
  //   (대댓글에 또 답글을 달아도 트리가 2단계로만 유지됨)
  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final postRef = FirebaseFirestore.instance.collection('community_posts').doc(widget.postId);
    final commentsRef = postRef.collection('comments');

    final comment = CommunityComment(
      id: '',
      userId: _currentUserId, // 🌟 authorId → userId
      authorNickname: _currentUserNickname,
      authorProfileImage: UserData.profileImagePath,
      content: text,
      parentId: _replyTarget?.parentId ?? _replyTarget?.id,
      replyToNickname: _replyTarget?.authorNickname,
    );

    try {
      await commentsRef.add(comment.toMap());
      await postRef.update({'commentCount': FieldValue.increment(1)});
      _commentController.clear();
      setState(() => _replyTarget = null);
      FocusScope.of(context).unfocus();
    } catch (e) {
      debugPrint('댓글 등록 중 오류 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글 등록에 실패했어요.')),
        );
      }
    }
  }

  // 🌟 댓글/대댓글 삭제
  Future<void> _deleteComment(CommunityComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('댓글 삭제'),
        content: const Text('이 댓글을 삭제하시겠어요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final postRef = FirebaseFirestore.instance.collection('community_posts').doc(widget.postId);

    try {
      await postRef.collection('comments').doc(comment.id).delete();
      await postRef.update({'commentCount': FieldValue.increment(-1)});
    } catch (e) {
      debugPrint('댓글 삭제 중 오류 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글 삭제에 실패했어요.')),
        );
      }
    }
  }

  void _startReply(CommunityComment comment) {
    setState(() => _replyTarget = comment);
    _commentFocusNode.requestFocus();
  }

  // 🌟 댓글/대댓글 입력창에서 이모티콘 삽입 (커서 위치 기준)
  void _insertCommentEmoticon(String token) {
    final text = _commentController.text;
    final selection = _commentController.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;
    final newText = text.replaceRange(start, end, token);
    _commentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + token.length),
    );
  }

  void _cancelReply() {
    setState(() => _replyTarget = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
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
          final bool isMine = post.userId == _currentUserId; // 🌟 authorId → userId
          final bool liked = post.likedBy.contains(_currentUserId);
          final bool scrapped = post.scrappedBy.contains(_currentUserId);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(0xFFF5F5F5),
                            backgroundImage: post.profileImage != null
                                ? NetworkImage(post.profileImage!)
                                : null,
                            child: post.profileImage == null
                                ? const Icon(Icons.person_outline, color: Colors.grey)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 🌟 닉네임 옆에 뱃지 노출 (얌얌북/커뮤니티 목록과 동일 방식)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(post.nickname ?? '익명',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    ),
                                    const SizedBox(width: 6),
                                    _AuthorBadgeRow(userId: post.userId),
                                  ],
                                ),
                                Text('${post.region} · ${post.category}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
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
                      EmoticonRichContent(
                        content: post.content,
                        style: const TextStyle(fontSize: 14, color: Colors.black),
                      ),
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
                      const Divider(height: 32),
                      // 🌟 댓글 목록
                      _buildCommentList(),
                    ],
                  ),
                ),
              ),
              _buildCommentInput(),
            ],
          );
        },
      ),
    );
  }

  // 🌟 댓글 목록 (원댓글 + 대댓글 트리 구성)
  Widget _buildCommentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community_posts')
          .doc(widget.postId)
          .collection('comments')
          .orderBy('createdAt')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(color: Colors.black)),
          );
        }

        final allComments =
        snapshot.data!.docs.map((doc) => CommunityComment.fromFirestore(doc)).toList();

        final topLevel = allComments.where((c) => c.parentId == null).toList();
        final repliesByParent = <String, List<CommunityComment>>{};
        for (final c in allComments.where((c) => c.parentId != null)) {
          repliesByParent.putIfAbsent(c.parentId!, () => []).add(c);
        }

        if (topLevel.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text('첫 댓글을 남겨보세요!', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ),
          );
        }

        return Column(
          children: topLevel.map((comment) {
            final replies = repliesByParent[comment.id] ?? [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCommentTile(comment, isReply: false),
                ...replies.map((reply) => _buildCommentTile(reply, isReply: true)),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCommentTile(CommunityComment comment, {required bool isReply}) {
    final bool isMine = comment.userId == _currentUserId;

    return Padding(
      padding: EdgeInsets.only(
        left: isReply ? 40 : 0,
        top: 12,
        bottom: 0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isReply)
            const Padding(
              padding: EdgeInsets.only(right: 6, top: 2),
              child: Icon(Icons.subdirectory_arrow_right, size: 16, color: Colors.grey),
            ),
          CircleAvatar(
            radius: isReply ? 14 : 16,
            backgroundColor: const Color(0xFFF5F5F5),
            backgroundImage: comment.authorProfileImage != null
                ? NetworkImage(comment.authorProfileImage!)
                : null,
            child: comment.authorProfileImage == null
                ? Icon(Icons.person_outline, size: isReply ? 14 : 16, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment.authorNickname,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 6),
                    if (comment.createdAt != null)
                      Text(_formatTime(comment.createdAt!),
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 3),
                EmoticonRichContent(
                  content: comment.content,
                  emojiSize: 16,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  leadingSpans: comment.replyToNickname != null
                      ? [
                    TextSpan(
                      text: '@${comment.replyToNickname} ',
                      style: const TextStyle(color: Color(0xFFFF8A3D), fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ]
                      : const [],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _startReply(comment),
                      child: const Text('답글쓰기',
                          style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _deleteComment(comment),
                        child: const Text('삭제', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 하단 댓글 입력창
  Widget _buildCommentInput() {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyTarget != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Text('${_replyTarget!.authorNickname}님에게 답글 남기는 중',
                        style: const TextStyle(fontSize: 12, color: Color(0xFFFF8A3D))),
                    const Spacer(),
                    GestureDetector(
                      onTap: _cancelReply,
                      child: const Icon(Icons.close, size: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                // 🌟 댓글/대댓글용 이모티콘 버튼 (보유한 팩만 노출됨)
                IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
                  tooltip: '이모티콘',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => EmoticonPickerSheet.show(
                    context,
                    uid: _currentUserId,
                    onSelect: _insertCommentEmoticon,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _commentFocusNode,
                    decoration: InputDecoration(
                      hintText: _replyTarget != null ? '답글을 입력하세요' : '댓글을 입력하세요',
                      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _submitComment,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF8A3D),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, size: 16, color: Colors.white),
                  ),
                ),
              ],
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
    return '${time.month}/${time.day}';
  }
}

/// 🌟 게시글 상세 화면의 작성자 닉네임 옆에 붙는 뱃지 목록.
/// 얌얌북(FeedCardWidget)과 동일한 규칙: 획득한 전체 뱃지 중 대표 뱃지(isSelected+displayOrder)를
/// 우선 정렬해 최대 3개까지 아이콘으로 보여주고, 나머지는 +N으로 표시합니다.
/// (대표 뱃지를 지정하지 않은 계정도 획득한 뱃지가 있으면 아이콘이 뜹니다.)
class _AuthorBadgeRow extends StatelessWidget {
  final String userId;

  const _AuthorBadgeRow({Key? key, required this.userId}) : super(key: key);

  Future<List<Map<String, dynamic>>> _fetchAllUserBadges() async {
    final cleanUid = userId.trim();
    if (cleanUid.isEmpty) {
      return [];
    }

    try {
      final userBadgeSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(cleanUid)
          .collection('users_badge')
          .get();

      if (userBadgeSnap.docs.isEmpty) return [];

      var selectedDocs = userBadgeSnap.docs
          .where((d) => d.data()['isSelected'] == true)
          .toList();

      selectedDocs.sort((a, b) {
        final orderA = (a.data()['displayOrder'] as num?)?.toInt() ?? 99;
        final orderB = (b.data()['displayOrder'] as num?)?.toInt() ?? 99;
        return orderA.compareTo(orderB);
      });

      var unselectedDocs = userBadgeSnap.docs
          .where((d) => d.data()['isSelected'] != true)
          .toList();

      final allDocs = [...selectedDocs, ...unselectedDocs];
      final badgeIds = allDocs
          .map((d) => d.data()['badgeId'] as String?)
          .whereType<String>()
          .toList();

      final List<Map<String, dynamic>> badgeDetails = [];
      for (final bId in badgeIds) {
        final badgeDoc = await FirebaseFirestore.instance.collection('badge').doc(bId).get();
        if (badgeDoc.exists && badgeDoc.data()?['isActive'] == true) {
          final data = badgeDoc.data()!;
          badgeDetails.add({
            'id': bId,
            'name': data['name'] ?? '뱃지',
            'description': data['description'] ?? '',
            'imageUrl': data['imageUrl'] ?? '',
            'iconUrl': data['iconUrl'] ?? data['imageUrl'] ?? '',
          });
        }
      }

      return badgeDetails;
    } catch (e) {
      debugPrint('🔴 [BadgeCheck] 뱃지 로드 중 에러 발생: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchAllUserBadges(),
      builder: (context, snapshot) {
        final allBadges = snapshot.data ?? [];
        if (allBadges.isEmpty) return const SizedBox.shrink();

        const int maxDisplayCount = 3;
        final displayBadges = allBadges.take(maxDisplayCount).toList();
        final bool hasMore = allBadges.length > maxDisplayCount;
        final int extraCount = allBadges.length - maxDisplayCount;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...displayBadges.asMap().entries.map((entry) {
              final int index = entry.key;
              final badge = entry.value;
              final String iconUrl = badge['iconUrl'] ?? '';
              return GestureDetector(
                onTap: () => _showBadgeSliderBottomSheet(context, allBadges, initialIndex: index),
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: ClipOval(
                    child: iconUrl.isEmpty
                        ? const SizedBox.shrink()
                        : Image.network(
                      iconUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              );
            }),
            if (hasMore)
              GestureDetector(
                onTap: () => _showBadgeSliderBottomSheet(context, allBadges, initialIndex: maxDisplayCount),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+$extraCount',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // 🌟 좌우 스와이프 가능한 슬라이드형 뱃지 전체보기 바텀 시트 (얌얌북 FeedCardWidget과 동일 UI)
  void _showBadgeSliderBottomSheet(
      BuildContext context,
      List<Map<String, dynamic>> allBadges, {
        int initialIndex = 0,
      }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        int currentPage = initialIndex;
        final PageController pageController = PageController(initialPage: initialIndex);

        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '보유한 뱃지 (${currentPage + 1}/${allBadges.length})',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(
                    height: 190,
                    child: PageView.builder(
                      controller: pageController,
                      itemCount: allBadges.length,
                      onPageChanged: (index) {
                        setBottomSheetState(() {
                          currentPage = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final badge = allBadges[index];
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: Image.network(
                                badge['imageUrl'],
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.workspace_premium, size: 70, color: Colors.orange),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              badge['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              badge['description'] ?? '',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                height: 1.3,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  if (allBadges.length > 1) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(allBadges.length, (dotIndex) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: currentPage == dotIndex ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: currentPage == dotIndex ? Colors.black : Colors.grey.shade300,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '확인',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }
}