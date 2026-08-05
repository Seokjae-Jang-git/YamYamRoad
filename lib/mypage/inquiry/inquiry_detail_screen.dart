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
  // 🌟 얌얌로드 공식 컬러 팔레트
  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color creamyIvory = Color(0xFFFFFDF9);
  static const Color subTextColor = Color(0xFF7A6B63);

  bool _isProcessing = false;

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
        title: const Text('문의 취소', style: TextStyle(fontWeight: FontWeight.bold, color: deepChocolate)),
        content: const Text('취소한 문의는 다시 되돌릴 수 없어요.\n정말 취소하시겠어요?', style: TextStyle(color: deepChocolate)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('닫기', style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('문의 취소', style: TextStyle(color: pointCoralRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      await InquiryRepository.instance.cancelInquiry(widget.inquiryId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('문의가 취소되었습니다.', style: TextStyle(color: creamyIvory)), backgroundColor: deepChocolate),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('문의 취소에 실패했습니다: $e', style: TextStyle(color: creamyIvory)), backgroundColor: pointCoralRed),
      );
    }
  }

  // 🌟 문의 종료 처리
  Future<void> _onCloseInquiry() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('문의 종료', style: TextStyle(fontWeight: FontWeight.bold, color: deepChocolate)),
        content: const Text('답변에 만족하셨나요?\n문의를 종료 상태로 변경합니다.', style: TextStyle(color: deepChocolate)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소', style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('문의 종료', style: TextStyle(color: pointCoralRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      await InquiryRepository.instance.closeInquiry(widget.inquiryId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('문의가 종료되었습니다.', style: TextStyle(color: creamyIvory)), backgroundColor: deepChocolate),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('문의 종료에 실패했습니다: $e', style: TextStyle(color: creamyIvory)), backgroundColor: pointCoralRed),
      );
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('yyyy.MM.dd. HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamyIvory,
      appBar: AppBar(
        backgroundColor: creamyIvory,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: deepChocolate, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '문의상세',
          style: TextStyle(color: deepChocolate, fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('inquiry').doc(widget.inquiryId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: deepChocolate));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('존재하지 않거나 삭제된 문의입니다.', style: TextStyle(color: subTextColor)));
          }

          final inquiry = InquiryModel.fromFirestore(snapshot.data!);
          final bool isAnswered = inquiry.status == 'answered';
          final bool isCanceled = inquiry.status == 'canceled';
          final bool isClosed = inquiry.status == 'closed';

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

          Color statusColor = deepChocolate;
          if (inquiry.status == 'pending') {
            statusColor = pointCoralRed;
          } else if (isCanceled || isClosed) {
            statusColor = subTextColor;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inquiry.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: deepChocolate, height: 1.3),
                ),
                const SizedBox(height: 12),

                Text(
                  '문의번호: ${inquiry.id}  |  ${_formatDate(inquiry.createdAt)}',
                  style: const TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      displayStatusText,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    if ((isAnswered || isClosed) && inquiry.answeredAt != null) ...[
                      const Text('  |  ', style: TextStyle(color: subTextColor, fontSize: 12)),
                      Text(
                        _formatDate(inquiry.answeredAt),
                        style: const TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // 🌟 본문 영역
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: deepChocolate.withOpacity(0.08)),
                    boxShadow: [
                      BoxShadow(color: deepChocolate.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Text(
                    inquiry.content,
                    style: TextStyle(color: deepChocolate.withOpacity(0.9), height: 1.6, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 16),

                // 🌟 다중 이미지 썸네일 미리보기 영역
                if (inquiry.imageUrl != null && inquiry.imageUrl!.isNotEmpty) ...[
                  Builder(
                    builder: (context) {
                      // 콤마(,)로 구분된 다중 이미지 URL 처리 (단일 URL이어도 정상 동작)
                      final List<String> imageUrls = inquiry.imageUrl!
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();

                      return Wrap(
                        spacing: 12, // 이미지 간 가로 간격
                        runSpacing: 12, // 이미지 간 세로 간격
                        children: imageUrls.map((url) {
                          return GestureDetector(
                            onTap: () {
                              // 썸네일 터치 시 원본 크기로 볼 수 있는 팝업 띄우기
                              showDialog(
                                context: context,
                                builder: (_) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  insetPadding: const EdgeInsets.all(16),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      InteractiveViewer(
                                        child: Image.network(url, fit: BoxFit.contain),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: IconButton(
                                          icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                          onPressed: () => Navigator.pop(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 100, // 썸네일 가로 크기
                              height: 100, // 썸네일 세로 크기
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: deepChocolate.withOpacity(0.1)),
                                boxShadow: [
                                  BoxShadow(color: deepChocolate.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  url,
                                  fit: BoxFit.cover, // 정사각형 썸네일 안에 가득 차게 자름
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(
                                      child: SizedBox(
                                        width: 20, height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: deepChocolate),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) => const Center(
                                    child: Icon(Icons.broken_image, color: subTextColor),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // 🌟 버튼 영역 (수정 / 문의 취소)
                if (inquiry.status == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _onEdit(inquiry),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: deepChocolate.withOpacity(0.3)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('수정', style: TextStyle(color: deepChocolate, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isProcessing ? null : _onCancel,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: deepChocolate.withOpacity(0.3)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: deepChocolate),
                          )
                              : const Text('문의 취소', style: TextStyle(color: deepChocolate, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),

                // 🌟 답변 영역 및 문의 종료 버튼
                if ((isAnswered || isClosed) && inquiry.adminMemo != null) ...[
                  const SizedBox(height: 32),
                  const Text('답변', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: deepChocolate)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: pointCoralRed.withOpacity(0.3)), // 관리자 답변은 테두리 색상으로 포인트
                      boxShadow: [
                        BoxShadow(color: pointCoralRed.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Text(
                      inquiry.adminMemo!,
                      style: TextStyle(color: deepChocolate.withOpacity(0.9), height: 1.6, fontSize: 14),
                    ),
                  ),

                  if (isAnswered) ...[
                    const SizedBox(height: 32),
                    const Center(
                      child: Text(
                        '답변이 만족스러우셨다면 문의 종료를 눌러주시기 바랍니다.',
                        style: TextStyle(fontSize: 12, color: subTextColor, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _onCloseInquiry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pointCoralRed,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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