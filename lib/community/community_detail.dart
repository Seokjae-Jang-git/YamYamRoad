import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../common/user_data.dart';
import '../features/emoticon/emoticon_text_controller.dart';
import '../services/auth_service.dart';
import 'community_post.dart';
import 'community_comment.dart';
import 'community_write.dart';

// 🌟 방금 만든 위젯들 불러오기
import 'widgets/post_content_widget.dart';
import 'widgets/comment_list_widget.dart';
import 'widgets/comment_input_widget.dart';

class CommunityDetailScreen extends StatefulWidget {
  final String postId;

  const CommunityDetailScreen({Key? key, required this.postId}) : super(key: key);

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  String get _currentUserId => AuthService.currentUser?.uid ?? UserData.uid ?? 'unknown_uid';
  String get _currentUserNickname => UserData.nickname ?? '이름없음';

  final EmoticonTextEditingController _commentController = EmoticonTextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  CommunityComment? _replyTarget;
  bool _showEmoticonPicker = false;

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

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
        await FirebaseFirestore.instance.collection('posts').doc(widget.postId).delete();
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제에 실패했어요.')));
      }
    }
  }

  void _editPost(CommunityPost post) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => CommunityWriteScreen(existingPost: post)));
  }

  Future<String> _generateUniqueReportId() async {
    final now = DateTime.now();
    final String dateStr = DateFormat('yyyyMMdd').format(now);
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();

    String reportId;
    bool isDuplicate = true;

    do {
      final randomCode = List.generate(4, (index) => chars[random.nextInt(chars.length)]).join();
      reportId = 'REP-$dateStr-$randomCode';

      try {
        final doc = await FirebaseFirestore.instance.collection('reports').doc(reportId).get();
        isDuplicate = doc.exists;
      } catch (_) {
        isDuplicate = false;
      }
    } while (isDuplicate);

    return reportId;
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

    String? detail;
    if (selected == '기타') {
      detail = await _askReportDetail();
      if (detail == null || detail.trim().isEmpty) return;
    }

    final existing = await FirebaseFirestore.instance
        .collection('reports')
        .where('targetId', isEqualTo: widget.postId)
        .where('userId', isEqualTo: _currentUserId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이미 신고한 게시글이에요.')));
      return;
    }

    try {
      final String reportId = await _generateUniqueReportId();

      await FirebaseFirestore.instance.collection('reports').doc(reportId).set({
        'reportId': reportId,
        'targetType': 'post',
        'targetId': widget.postId,
        'userId': _currentUserId,
        'reason': selected,
        'reasonDetail': detail ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({'reportCount': FieldValue.increment(1)});

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('신고가 접수되었습니다.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('신고 접수에 실패했어요.')));
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
    final ref = FirebaseFirestore.instance.collection('posts').doc(post.id);
    final liked = post.likedBy.contains(_currentUserId);
    await ref.update({
      'likedBy': liked ? FieldValue.arrayRemove([_currentUserId]) : FieldValue.arrayUnion([_currentUserId]),
      'likeCount': FieldValue.increment(liked ? -1 : 1),
    });
  }

  Future<void> _toggleScrap(CommunityPost post) async {
    final ref = FirebaseFirestore.instance.collection('posts').doc(post.id);
    final scrapped = post.scrappedBy.contains(_currentUserId);
    await ref.update({
      'scrappedBy': scrapped ? FieldValue.arrayRemove([_currentUserId]) : FieldValue.arrayUnion([_currentUserId]),
      'scrapCount': FieldValue.increment(scrapped ? -1 : 1),
    });
  }

  Future<void> _submitComment() async {
    final text = _commentController.toStorageText().trim(); // 저장용 토큰으로 변환하여 저장
    if (text.isEmpty) return;

    final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);
    final commentsRef = postRef.collection('comments');

    final comment = CommunityComment(
      id: '',
      userId: _currentUserId,
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
      setState(() {
        _replyTarget = null;
        _showEmoticonPicker = false;
      });
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('댓글 등록에 실패했어요.')));
    }
  }

  Future<void> _deleteComment(CommunityComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('댓글 삭제'),
        content: const Text('이 댓글을 삭제하시겠어요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);
      await postRef.collection('comments').doc(comment.id).delete();
      await postRef.update({'commentCount': FieldValue.increment(-1)});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('댓글 삭제에 실패했어요.')));
    }
  }

  void _startReply(CommunityComment comment) {
    setState(() {
      _replyTarget = comment;
      _showEmoticonPicker = false;
    });
    _commentFocusNode.requestFocus();
  }

  void _toggleEmoticonPicker() {
    setState(() {
      if (_showEmoticonPicker) {
        _showEmoticonPicker = false;
        _commentFocusNode.requestFocus();
      } else {
        FocusScope.of(context).unfocus();
        _showEmoticonPicker = true;
      }
    });
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
        title: const Text('얌얌북', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('posts').doc(widget.postId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.black));
          if (!snapshot.data!.exists) return const Center(child: Text('삭제되었거나 존재하지 않는 글이에요.'));

          final post = CommunityPost.fromFirestore(snapshot.data!);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🌟 분리된 위젯 1: 게시글 본문 영역
                      PostContentWidget(
                        post: post,
                        currentUserId: _currentUserId,
                        isMine: post.userId == _currentUserId,
                        isLiked: post.likedBy.contains(_currentUserId),
                        isScrapped: post.scrappedBy.contains(_currentUserId),
                        onEdit: () => _editPost(post),
                        onDelete: _deletePost,
                        onReport: _reportPost,
                        onLikeToggle: () => _toggleLike(post),
                        onScrapToggle: () => _toggleScrap(post),
                      ),
                      const Divider(height: 32),
                      // 🌟 분리된 위젯 2: 댓글 리스트 영역
                      CommentListWidget(
                        postId: widget.postId,
                        currentUserId: _currentUserId,
                        onStartReply: _startReply,
                        onDeleteComment: _deleteComment,
                      ),
                    ],
                  ),
                ),
              ),
              // 🌟 분리된 위젯 3: 댓글 입력창 영역
              CommentInputWidget(
                controller: _commentController,
                focusNode: _commentFocusNode,
                replyTarget: _replyTarget,
                showEmoticonPicker: _showEmoticonPicker,
                currentUserId: _currentUserId,
                onCancelReply: () => setState(() => _replyTarget = null),
                onToggleEmoticon: _toggleEmoticonPicker,
                onFieldTap: () {
                  if (_showEmoticonPicker) setState(() => _showEmoticonPicker = false);
                },
                onSubmit: _submitComment,
              ),
            ],
          );
        },
      ),
    );
  }
}