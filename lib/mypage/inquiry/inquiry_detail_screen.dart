import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'inquiry_model.dart';
import 'inquiry_write_screen.dart'; // 🌟 경로 확인 필요

class InquiryDetailScreen extends StatefulWidget {
  final String inquiryId;

  const InquiryDetailScreen({Key? key, required this.inquiryId}) : super(key: key);

  @override
  State<InquiryDetailScreen> createState() => _InquiryDetailScreenState();
}

class _InquiryDetailScreenState extends State<InquiryDetailScreen> {
  bool _isDeleting = false;

  // 수정 화면으로 이동
  Future<void> _onEdit(InquiryModel inquiry) async {
    final edited = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => InquiryWriteScreen(editTarget: inquiry), // 🌟 WriteScreen에서 수정 모드 지원 필요
      ),
    );

    // 수정 후 상세 화면도 닫고 리스트로 복귀 (StreamBuilder라 리스트는 자동 갱신됨)
    if (edited == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  // 삭제 처리
  Future<void> _onDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('문의 삭제', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('삭제한 문의는 다시 볼 수 없어요.\n정말 삭제하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('삭제', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      await FirebaseFirestore.instance.collection('inquiry').doc(widget.inquiryId).delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('문의가 삭제되었습니다.')));
      Navigator.of(context).pop(); // 삭제 성공 시 화면 닫기
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('삭제에 실패했습니다: $e')));
    }
  }

  // 날짜 포맷팅 (설계안: 2026.07.27. 15:59)
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
                      inquiry.displayStatus,
                      style: TextStyle(
                        color: isAnswered ? Colors.black87 : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    if (isAnswered && inquiry.answeredAt != null) ...[
                      const Text('  |  ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(
                        _formatDate(inquiry.answeredAt),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // 3. 본문 내용 (설계안의 박스 디자인 반영)
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

                // 5. 버튼 영역 (답변 대기 상태일 때만 노출)
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
                          onPressed: _isDeleting ? null : _onDelete,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isDeleting
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                              : const Text('삭제', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),

                // 6. 답변 내용 (답변 완료 상태일 때만 노출)
                if (isAnswered && inquiry.adminMemo != null) ...[
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