import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../common/data/temp_user_session.dart';
import '../common/user_data.dart';
import '../features/emoticon/emoticon_text_controller.dart';
import '../noti/logic/noti_community_api_client.dart';
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
  final NotiCommunityApiClient _notiApiClient = NotiCommunityApiClient();

  CommunityComment? _replyTarget;
  bool _showEmoticonPicker = false;
  bool _isDeleting = false; // 🌟 삭제 진행 중에는 화면을 오버레이로 가려서 중간 과정이 안 보이게 함

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
      setState(() => _isDeleting = true); // 🌟 즉시 오버레이를 띄워서 이후 과정을 가림
      try {
        await _softDeletePost(widget.postId);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제에 실패했어요.')));
        }
      }
    }
  }

  // 🌟 실제 문서/서브컬렉션(comments, post_like, post_scrap 등)은 그대로 두고
  // status만 'deleted'로 바꾸는 소프트 삭제. 하드 삭제가 필요해질 경우를 대비해
  // 아래에 배치 삭제 유틸(_deleteAllDocsInSubcollection, _deleteAllDocs)은 남겨둠.
  Future<void> _softDeletePost(String postId) async {
    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

    await postRef.update({
      'status': 'deleted',
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  // 🌟 특정 서브컬렉션의 모든 문서를 조회해서 배치로 삭제 (하드 삭제가 다시 필요할 때 사용)
  Future<void> _deleteAllDocsInSubcollection(DocumentReference parentRef, String subcollectionName) async {
    final snap = await parentRef.collection(subcollectionName).get();
    await _deleteAllDocs(snap.docs.map((d) => d.reference).toList());
  }

  // 🌟 문서 참조 리스트를 배치(최대 500개 단위)로 삭제 (Firestore 배치 쓰기 제한 대응)
  Future<void> _deleteAllDocs(List<DocumentReference> refs) async {
    const chunkSize = 400; // 여유 있게 400개씩
    for (var i = 0; i < refs.length; i += chunkSize) {
      final chunk = refs.sublist(i, i + chunkSize > refs.length ? refs.length : i + chunkSize);
      final batch = FirebaseFirestore.instance.batch();
      for (final ref in chunk) {
        batch.delete(ref);
      }
      await batch.commit();
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

  // 🌟 게시글/댓글 신고 공통 로직 - targetType/targetId만 다르게 넘겨서 재사용합니다.
  Future<void> _submitReport({
    required String targetType,
    required String targetId,
    required Future<void> Function() onIncrementCount,
  }) async {
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
        .where('targetId', isEqualTo: targetId)
        .where('userId', isEqualTo: _currentUserId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이미 신고했어요.')));
      return;
    }

    try {
      final String reportId = await _generateUniqueReportId();

      await FirebaseFirestore.instance.collection('reports').doc(reportId).set({
        'reportId': reportId,
        'targetType': targetType,
        'targetId': targetId,
        'userId': _currentUserId,
        'reason': selected,
        'reasonDetail': detail ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await onIncrementCount();

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('신고가 접수되었습니다.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('신고 접수에 실패했어요.')));
    }
  }

  Future<void> _reportPost() => _submitReport(
    targetType: 'post',
    targetId: widget.postId,
    onIncrementCount: () => FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .update({'reportCount': FieldValue.increment(1)}),
  );

  // 🌟 댓글 신고
  Future<void> _reportComment(CommunityComment comment) => _submitReport(
    targetType: 'comment',
    targetId: comment.id,
    onIncrementCount: () => FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(comment.id)
        .update({'reportCount': FieldValue.increment(1)}),
  );

  // 🌟 게시글 좋아요 (post_like 서브컬렉션 + 트랜잭션, 인당 1번 제한 자동 보장)
  Future<void> _toggleLike(CommunityPost post) async {
    final postRef = FirebaseFirestore.instance.collection('posts').doc(post.id);
    final likeRef = postRef.collection('post_like').doc(_currentUserId);

    try {
      final isAdded = await FirebaseFirestore.instance.runTransaction<bool>((tx) async {
        final likeSnap = await tx.get(likeRef);
        if (likeSnap.exists) {
          tx.delete(likeRef);
          tx.update(postRef, {'likeCount': FieldValue.increment(-1)});
          return false;
        } else {
          tx.set(likeRef, {'likedAt': FieldValue.serverTimestamp()});
          tx.update(postRef, {'likeCount': FieldValue.increment(1)});
          return true;
        }
      });
      if (isAdded) {
        _requestCommunityNotification(
          event: NotiCommunityEvent.postLike,
          postId: post.id,
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('처리에 실패했어요.')));
    }
  }

  // 🌟 게시글 스크랩 (post_scrap 서브컬렉션 + users_myscrap 서브컬렉션을 같은 트랜잭션으로 동기화)
  // - posts/{postId}/post_scrap 문서 ID = 스크랩한 사용자의 uid
  // - users/{uid}/users_myscrap 문서 ID = 스크랩된 게시글의 postId
  // 양쪽 다 "문서 ID로 바로 존재 여부 확인/삭제"가 가능하도록 맞춰서, 마이페이지의
  // 내 스크랩 목록에서 취소할 때도 where 쿼리 없이 doc(postId)로 바로 지울 수 있게 함.
  Future<void> _toggleScrap(CommunityPost post) async {
    final postRef = FirebaseFirestore.instance.collection('posts').doc(post.id);
    final scrapRef = postRef.collection('post_scrap').doc(_currentUserId);
    final myScrapRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .collection('users_myscrap')
        .doc(post.id);

    try {
      final isAdded = await FirebaseFirestore.instance.runTransaction<bool>((tx) async {
        final scrapSnap = await tx.get(scrapRef);
        if (scrapSnap.exists) {
          tx.delete(scrapRef);
          tx.delete(myScrapRef);
          tx.update(postRef, {'scrapCount': FieldValue.increment(-1)});
          return false;
        } else {
          final scrappedAt = FieldValue.serverTimestamp();
          tx.set(scrapRef, {'scrappedAt': scrappedAt});
          tx.set(myScrapRef, {
            'postId': post.id,
            'scrappedAt': scrappedAt,
          });
          tx.update(postRef, {'scrapCount': FieldValue.increment(1)});
          return true;
        }
      });
      if (isAdded) {
        _requestCommunityNotification(
          event: NotiCommunityEvent.postScrap,
          postId: post.id,
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('처리에 실패했어요.')));
    }
  }

  // 🌟 댓글 좋아요
  Future<void> _handleCommentLike(CommunityComment comment) async {
    final uid = _currentUserId;
    final commentRef = FirebaseFirestore.instance
        .collection('posts').doc(widget.postId)
        .collection('comments').doc(comment.id);
    final likeRef = commentRef.collection('comment_like').doc(uid);

    try {
      final isAdded = await FirebaseFirestore.instance.runTransaction<bool>((tx) async {
        final likeSnap = await tx.get(likeRef);

        if (likeSnap.exists) {
          tx.delete(likeRef);
          tx.update(commentRef, {'likeCount': FieldValue.increment(-1)});
          return false;
        } else {
          tx.set(likeRef, {'likedAt': FieldValue.serverTimestamp()});
          tx.update(commentRef, {'likeCount': FieldValue.increment(1)});
          return true;
        }
      });
      if (isAdded) {
        _requestCommunityNotification(
          event: NotiCommunityEvent.commentLike,
          postId: widget.postId,
          commentId: comment.id,
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('처리에 실패했어요.')));
    }
  }

  // 🌟 댓글 수정
  Future<void> _editComment(CommunityComment comment, String newContent) async {
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(comment.id)
          .update({
        'content': newContent,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('댓글 수정에 실패했어요.')));
    }
  }

  Future<void> _submitComment(CommunityPost post) async {
    final text = _commentController.toStorageText().trim(); // 저장용 토큰으로 변환하여 저장
    if (text.isEmpty) return;

    final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);
    final commentsRef = postRef.collection('comments');

    final comment = CommunityComment(
      id: '',
      userId: _currentUserId,
      nickname: _currentUserNickname,
      profileImage: UserData.profileImagePath,
      content: text,
      parentId: _replyTarget?.parentId ?? _replyTarget?.id,
      replyToNickname: _replyTarget?.nickname,
    );

    try {
      final commentRef = await commentsRef.add(comment.toMap());
      await postRef.update({'commentCount': FieldValue.increment(1)});
      _requestCommunityNotification(
        event: NotiCommunityEvent.postComment,
        postId: post.id,
        commentId: commentRef.id,
      );
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

  void _requestCommunityNotification({
    required NotiCommunityEvent event,
    required String postId,
    String? commentId,
  }) {
    unawaited(
      _sendCommunityNotification(
        event: event,
        postId: postId,
        commentId: commentId,
      ),
    );
  }

  Future<void> _sendCommunityNotification({
    required NotiCommunityEvent event,
    required String postId,
    String? commentId,
  }) async {
    try {
      await _notiApiClient.send(
        event: event,
        postId: postId,
        commentId: commentId,
      );
    } catch (error) {
      debugPrint('커뮤니티 알림 요청 실패: $error');
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
      // 🌟 1단계: 게시글 문서 자체를 구독 (여기서 post 변수가 만들어집니다)
      body: Stack(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('posts').doc(widget.postId).snapshots(),
            builder: (context, postSnapshot) {
              if (!postSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: Colors.black));
              }
              if (!postSnapshot.data!.exists) {
                return const Center(child: Text('삭제되었거나 존재하지 않는 글이에요.'));
              }

              final post = CommunityPost.fromFirestore(postSnapshot.data!);

              // 🌟 소프트 삭제된 글이면(status == 'deleted') 상세 화면에서도 접근 불가 처리
              if (post.status == 'deleted') {
                return const Center(child: Text('삭제되었거나 존재하지 않는 글이에요.'));
              }

              // 🌟 2단계: 내가 이 글에 좋아요를 눌렀는지 구독
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts').doc(widget.postId)
                    .collection('post_like').doc(_currentUserId)
                    .snapshots(),
                builder: (context, likeSnap) {
                  final isLiked = likeSnap.data?.exists ?? false;

                  // 🌟 3단계: 내가 이 글을 스크랩했는지 구독
                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts').doc(widget.postId)
                        .collection('post_scrap').doc(_currentUserId)
                        .snapshots(),
                    builder: (context, scrapSnap) {
                      final isScrapped = scrapSnap.data?.exists ?? false;

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
                                    isLiked: isLiked,
                                    isScrapped: isScrapped,
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
                                    postAuthorId: post.userId,
                                    onStartReply: _startReply,
                                    onDeleteComment: _deleteComment,
                                    onLikeToggle: _handleCommentLike,
                                    onReport: _reportComment,
                                    onEditSubmit: _editComment,
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
                            onSubmit: () => _submitComment(post),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
          // 🌟 삭제 진행 중일 때만 표시되는 불투명 오버레이 - 상태 변경 요청 중
          // 화면이 깜빡이는 것을 방지하기 위함
          if (_isDeleting)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFFF8A3D)),
                    SizedBox(height: 12),
                    Text('삭제 중입니다...', style: TextStyle(color: Colors.black87, fontSize: 13)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
