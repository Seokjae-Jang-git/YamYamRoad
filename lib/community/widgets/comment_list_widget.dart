import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/emoticon/emoticon_span_builder.dart';
import '../community_comment.dart';
import '../../features/emoticon/emoticon_picker_sheet.dart';
import '../../features/emoticon/emoticon_text_controller.dart';

class CommentListWidget extends StatelessWidget {
  final String postId;
  final String currentUserId;
  final Function(CommunityComment) onStartReply;
  final Function(CommunityComment) onDeleteComment;
  final Function(CommunityComment) onLikeToggle;
  final Function(CommunityComment) onReport;
  final Function(CommunityComment, String) onEditSubmit;

  const CommentListWidget({
    Key? key,
    required this.postId,
    required this.currentUserId,
    required this.onStartReply,
    required this.onDeleteComment,
    required this.onLikeToggle,
    required this.onReport,
    required this.onEditSubmit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
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

        final allComments = snapshot.data!.docs.map((doc) => CommunityComment.fromFirestore(doc)).toList();
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
                _buildCommentTile(context, comment, isReply: false),
                ...replies.map((reply) => _buildCommentTile(context, reply, isReply: true)),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCommentTile(BuildContext context, CommunityComment comment, {required bool isReply}) {
    final bool isMine = comment.userId == currentUserId;

    return Padding(
      padding: EdgeInsets.only(left: isReply ? 40 : 0, top: 12, bottom: 0),
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
            backgroundImage: comment.profileImage != null ? NetworkImage(comment.profileImage!) : null,
            child: comment.profileImage == null
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
                    Text(comment.nickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 6),
                    if (comment.createdAt != null)
                      Text(_formatTime(comment.createdAt!), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    if (comment.updatedAt != null) ...[
                      const SizedBox(width: 4),
                      const Text('(수정됨)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                    const Spacer(),
                    // 🌟 내 댓글이면 수정/삭제, 남의 댓글이면 신고
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.more_horiz, size: 18, color: Colors.grey),
                      onSelected: (value) {
                        if (value == 'edit') _showEditDialog(context, comment);
                        if (value == 'delete') onDeleteComment(comment);
                        if (value == 'report') onReport(comment);
                      },
                      itemBuilder: (context) => isMine
                          ? const [
                        PopupMenuItem(value: 'edit', child: Text('수정')),
                        PopupMenuItem(value: 'delete', child: Text('삭제')),
                      ]
                          : const [
                        PopupMenuItem(value: 'report', child: Text('신고')),
                      ],
                    ),
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
                      onTap: () => onStartReply(comment),
                      child: const Text('답글쓰기',
                          style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 12),
                    // 🌟 좋아요 - StreamBuilder로 내 좋아요 여부 확인
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('posts').doc(postId)
                          .collection('comments').doc(comment.id)
                          .collection('comment_like').doc(currentUserId)
                          .snapshots(),
                      builder: (context, likeSnap) {
                        final isLiked = likeSnap.data?.exists ?? false;
                        return GestureDetector(
                          onTap: () => onLikeToggle(comment),
                          child: Row(
                            children: [
                              Icon(isLiked ? Icons.favorite : Icons.favorite_border,
                                  size: 14, color: isLiked ? Colors.red : Colors.grey),
                              const SizedBox(width: 3),
                              Text('${comment.likeCount}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, CommunityComment comment) async {
    final newContent = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _CommentEditDialog(
        initialContent: comment.content,
        currentUserId: currentUserId,
      ),
    );

    if (newContent == null || newContent.isEmpty || newContent == comment.content) return;
    onEditSubmit(comment, newContent);
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${time.month}/${time.day}';
  }
}

class _CommentEditDialog extends StatefulWidget {
  final String initialContent;
  final String currentUserId;

  const _CommentEditDialog({
    required this.initialContent,
    required this.currentUserId,
  });

  @override
  State<_CommentEditDialog> createState() => _CommentEditDialogState();
}

class _CommentEditDialogState extends State<_CommentEditDialog> {
  late final EmoticonTextEditingController _controller;
  bool _loading = true;
  bool _showEmoticonPicker = false;

  @override
  void initState() {
    super.initState();
    _controller = EmoticonTextEditingController();
    _loadContent();
  }

  Future<void> _loadContent() async {
    await _controller.loadStoredContent(widget.initialContent);
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleEmoticonPicker() {
    setState(() {
      if (_showEmoticonPicker) {
        _showEmoticonPicker = false;
      } else {
        FocusScope.of(context).unfocus();
        _showEmoticonPicker = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('댓글 수정'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(color: Colors.black),
              )
            else ...[
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _showEmoticonPicker ? Icons.keyboard_alt_outlined : Icons.emoji_emotions_outlined,
                      color: Colors.grey,
                    ),
                    tooltip: '이모티콘',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _toggleEmoticonPicker,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: 3,
                      autofocus: true,
                      onTap: () {
                        if (_showEmoticonPicker) setState(() => _showEmoticonPicker = false);
                      },
                      decoration: const InputDecoration(hintText: '댓글을 입력해주세요'),
                    ),
                  ),
                ],
              ),
              if (_showEmoticonPicker)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: EmoticonPickerSheet(
                    uid: widget.currentUserId,
                    onSelect: (token, imageUrl) {
                      _controller.insertEmoticon(token, imageUrl);
                    },
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context, _controller.toStorageText()),
          child: const Text('완료'),
        ),
      ],
    );
  }
}