import 'dart:io';
import 'package:flutter/material.dart';
import 'inquiry.dart';
import 'inquiry_repository.dart';
import 'app_colors.dart';
import 'inquiry_repository.dart';
import 'inquiry_write_screen.dart';

/// 문의 상세 화면. 수정하기 / 삭제하기 버튼 제공.
class InquiryDetailScreen extends StatefulWidget {
  final String inquiryId;

  const InquiryDetailScreen({super.key, required this.inquiryId});

  @override
  State<InquiryDetailScreen> createState() => _InquiryDetailScreenState();
}

class _InquiryDetailScreenState extends State<InquiryDetailScreen> {
  final _repo = InquiryRepository.instance;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onChanged);
  }

  @override
  void dispose() {
    _repo.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    // 삭제되면 findById가 null을 반환하므로 화면을 닫는다.
    if (mounted && _repo.findById(widget.inquiryId) == null) {
      Navigator.of(context).pop();
    } else if (mounted) {
      setState(() {});
    }
  }

  Future<void> _onEdit(Inquiry inquiry) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InquiryWriteScreen(editTarget: inquiry),
      ),
    );
  }

  Future<void> _onDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('문의를 삭제할까요?'),
        content: const Text('삭제한 문의는 다시 볼 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('삭제', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _repo.delete(widget.inquiryId);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('문의가 삭제되었습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inquiry = _repo.findById(widget.inquiryId);

    if (inquiry == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final answered = inquiry.status == InquiryStatus.answered;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '문의 상세',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onSelected: (value) {
              if (value == 'edit') _onEdit(inquiry);
              if (value == 'delete') _onDelete();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('수정하기')),
              PopupMenuItem(value: 'delete', child: Text('삭제하기')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Row(
            children: [
              _badge(inquiry.type.label, AppColors.primaryLight, AppColors.primary),
              const SizedBox(width: 8),
              _badge(
                answered ? '답변완료' : '답변대기',
                answered ? AppColors.statusAnsweredBg : AppColors.statusPendingBg,
                answered ? AppColors.statusAnsweredText : AppColors.statusPendingText,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            inquiry.title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '접수 번호 ${inquiry.receiptNumber}  ·  ${_formatDate(inquiry.createdAt)}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              inquiry.content,
              style: const TextStyle(color: AppColors.textPrimary, height: 1.5),
            ),
          ),
          if (inquiry.imagePath != null) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(inquiry.imagePath!), height: 180, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            '답변받을 이메일  ${inquiry.email}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          if (answered && inquiry.answer != null) ...[
            const SizedBox(height: 24),
            const Text(
              '답변',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                inquiry.answer!,
                style: const TextStyle(color: AppColors.textPrimary, height: 1.5),
              ),
            ),
          ],
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _onEdit(inquiry),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('수정하기',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _onDelete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('삭제하기',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
