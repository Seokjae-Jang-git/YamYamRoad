import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'inquiry.dart';
import 'inquiry_detail_screen.dart';
import 'inquiry_repository.dart';
import 'inquiry_write_screen.dart';

/// 문의 내역 리스트 화면.
class InquiryListScreen extends StatefulWidget {
  const InquiryListScreen({super.key});

  @override
  State<InquiryListScreen> createState() => _InquiryListScreenState();
}

class _InquiryListScreenState extends State<InquiryListScreen> {
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
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final items = _repo.inquiries;

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
          '문의 내역',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const InquiryWriteScreen()),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('문의하기', style: TextStyle(color: Colors.white)),
      ),
      body: items.isEmpty ? _buildEmpty() : _buildList(items),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text(
        '등록된 문의가 없어요',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildList(List<Inquiry> items) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _InquiryCard(inquiry: items[index]),
    );
  }
}

class _InquiryCard extends StatelessWidget {
  final Inquiry inquiry;

  const _InquiryCard({required this.inquiry});

  @override
  Widget build(BuildContext context) {
    final answered = inquiry.status == InquiryStatus.answered;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => InquiryDetailScreen(inquiryId: inquiry.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _typeBadge(inquiry.type.label),
                const SizedBox(width: 8),
                _statusBadge(answered),
                const Spacer(),
                Text(
                  inquiry.receiptNumber,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              inquiry.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              inquiry.content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Text(
              _formatDate(inquiry.createdAt),
              style: const TextStyle(fontSize: 12, color: AppColors.hint),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _statusBadge(bool answered) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: answered ? AppColors.statusAnsweredBg : AppColors.statusPendingBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        answered ? '답변완료' : '답변대기',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: answered ? AppColors.statusAnsweredText : AppColors.statusPendingText,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
