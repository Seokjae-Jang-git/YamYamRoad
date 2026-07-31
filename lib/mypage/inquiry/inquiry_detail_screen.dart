import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'inquiry_model.dart';
import 'inquiry_write_screen.dart';
import 'inquiry_repository.dart';

class InquiryDetailScreen extends StatefulWidget {
  final String inquiryId;

  const InquiryDetailScreen({Key? key, required this.inquiryId}) : super(key: key);

  @override
  State<InquiryDetailScreen> createState() => _InquiryDetailScreenState();
}

class _InquiryDetailScreenState extends State<InquiryDetailScreen> {
  bool _isProcessing = false; // 취소/종료 처리 중 플래그

  // 수정 화면으로 이동
  Future<void> _onEdit(InquiryModel inquiry) async {
    final edited = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => InquiryWriteScreen(editTarget: inquiry),
      ),
    );

    if (edited == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  // 🌟 문의 취소 처리
  Future<void> _onCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('문의 취소', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('취소한 문의는 다시 되돌릴 수 없어요.\n정말 취소하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('닫기', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('문의 취소', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      await InquiryRepository.instance.cancelInquiry(widget.inquiryId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('문의가 취소되었습니다.')));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('문의 취소에 실패했습니다: $e')));
    }
  }

  // 🌟 문의 종료 처리
  Future<void> _onCloseInquiry() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('문의 종료', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('답변에 만족하셨나요?\n문의를 종료 상태로 변경합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('문의 종료', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      await InquiryRepository.instance.closeInquiry(widget.inquiryId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('문의가 종료되었습니다.')));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('문의 종료에 실패했습니다: $e')));
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('yyyy.MM.dd. HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '문의상세',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('inquiry').doc(widget.inquiryId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('존재하지 않거나 삭제된 문의입니다.', style: TextStyle(color: Colors.grey)));
          }

          final inquiry = InquiryModel.fromFirestore(snapshot.data!);
          final bool isAnswered = inquiry.status == 'answered';
          final bool isCanceled = inquiry.status == 'canceled';
          final bool isClosed = inquiry.status == 'closed';

          // 💡 화면 표시용 상태 라벨
          String displayStatusText = inquiry.displayStatus;
          if (isCanceled) {
            displayStatusText = '문의 취소';
          } else if (inquiry.status == 'pending') {
            displayStatusText = '답변 대기';
          } else if (isAnswered) {
            displayStatusText = '답변 완료';
          } else if (isClosed) {
            displayStatusText = '문의 종료';
          }

          // 💡 상태별 텍스트 색상
          Color statusColor = Colors.black87;
          if (inquiry.status == 'pending') {
            statusColor = Colors.orange;
          } else if (isCanceled || isClosed) {
            statusColor = Colors.grey.shade600;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 제목
                Text(
                  inquiry.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 12),

                // 2. 문의 정보 (문의번호, 작성일, 상태 등)
                Text(
                  '문의번호: ${inquiry.id}  |  ${_formatDate(inquiry.createdAt)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      displayStatusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    if ((isAnswered || isClosed) && inquiry.answeredAt != null) ...[
                      const Text('  |  ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(
                        _formatDate(inquiry.answeredAt),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // 3. 본문 내용
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    inquiry.content,
                    style: const TextStyle(color: Colors.black87, height: 1.5, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 16),

                // 4. 첨부 이미지 미리보기
                if (inquiry.imageUrl != null && inquiry.imageUrl!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        inquiry.imageUrl!,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Padding(
                            padding: EdgeInsets.all(40.0),
                            child: Center(child: CircularProgressIndicator(color: Colors.black)),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => const Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 5. 버튼 영역 (답변 대기 상태일 때만 노출 / 취소 또는 답변완료 건은 버튼 비노출)
                if (inquiry.status == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _onEdit(inquiry),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('수정', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isProcessing ? null : _onCancel,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                              : const Text('문의 취소', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),

                // 🌟 (기존에 중복된 답변 코드는 지우고, 이 블록 하나만 남겨주세요!)
                // 6. 답변 내용 및 문의 종료 버튼 (답변 완료/종료 상태일 때 노출)
                if ((isAnswered || isClosed) && inquiry.adminMemo != null) ...[
                  const SizedBox(height: 32),
                  const Text('답변', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      inquiry.adminMemo!,
                      style: const TextStyle(color: Colors.black87, height: 1.5, fontSize: 14),
                    ),
                  ),

                  // 🌟 답변이 완료된 상태(answered)에서만 안내 문구 및 [문의 종료] 버튼 노출
                  if (isAnswered) ...[
                    const SizedBox(height: 24),

                    // 💡 문의 종료 안내 텍스트
                    const Center(
                      child: Text(
                        '답변이 만족스러우셨다면 문의 종료를 눌러주시기 바랍니다.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _onCloseInquiry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                            : const Text('문의 종료', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}