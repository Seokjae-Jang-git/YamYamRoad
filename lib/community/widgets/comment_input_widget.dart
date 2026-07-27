import 'package:flutter/material.dart';
import '../../features/emoticon/emoticon_picker_sheet.dart';
import '../../features/emoticon/emoticon_text_controller.dart';
import '../community_comment.dart';

class CommentInputWidget extends StatelessWidget {
  final EmoticonTextEditingController controller;
  final FocusNode focusNode;
  final CommunityComment? replyTarget;
  final bool showEmoticonPicker;
  final String currentUserId;
  final VoidCallback onCancelReply;
  final VoidCallback onToggleEmoticon;
  final VoidCallback onFieldTap;
  final VoidCallback onSubmit;

  const CommentInputWidget({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.replyTarget,
    required this.showEmoticonPicker,
    required this.currentUserId,
    required this.onCancelReply,
    required this.onToggleEmoticon,
    required this.onFieldTap,
    required this.onSubmit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            if (replyTarget != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Text('${replyTarget!.authorNickname}님에게 답글 남기는 중',
                        style: const TextStyle(fontSize: 12, color: Color(0xFFFF8A3D))),
                    const Spacer(),
                    GestureDetector(
                      onTap: onCancelReply,
                      child: const Icon(Icons.close, size: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    showEmoticonPicker ? Icons.keyboard_alt_outlined : Icons.emoji_emotions_outlined,
                    color: Colors.grey,
                  ),
                  tooltip: '이모티콘',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onToggleEmoticon,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onTap: onFieldTap,
                    decoration: InputDecoration(
                      hintText: replyTarget != null ? '답글을 입력하세요' : '댓글을 입력하세요',
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
                    onSubmitted: (_) => onSubmit(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onSubmit,
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
            if (showEmoticonPicker)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: EmoticonPickerSheet(
                  uid: currentUserId,
                  onSelect: (token, imageUrl) {
                    controller.insertEmoticon(token, imageUrl);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}