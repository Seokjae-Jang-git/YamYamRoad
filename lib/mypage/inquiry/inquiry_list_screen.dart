import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../services/auth_service.dart';
import '../../common/user_data.dart';

import 'inquiry_model.dart';
import 'inquiry_detail_screen.dart';
import 'inquiry_write_screen.dart';

class InquiryListScreen extends StatefulWidget {
  const InquiryListScreen({Key? key}) : super(key: key);

  @override
  State<InquiryListScreen> createState() => _InquiryListScreenState();
}

class _InquiryListScreenState extends State<InquiryListScreen> {
  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color creamyIvory = Color(0xFFFFFDF9);
  static const Color subTextColor = Color(0xFF7A6B63);

  String get _currentUserId => AuthService.currentUser?.uid ?? UserData.uid ?? 'unknown_uid';

  String _selectedStatusFilter = 'ALL';
  String _selectedSortType = 'CREATED_DESC';

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('inquiry')
        .where('userId', isEqualTo: _currentUserId);

    if (_selectedSortType == 'CREATED_DESC') {
      query = query.orderBy('createdAt', descending: true);
    } else if (_selectedSortType == 'ANSWERED_DESC') {
      query = query.orderBy('answeredAt', descending: true);
    }

    return Scaffold(
      backgroundColor: creamyIvory,
      appBar: AppBar(
        backgroundColor: creamyIvory,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: deepChocolate, size: 28),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        title: const Text(
          '문의 내역',
          style: TextStyle(color: deepChocolate, fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: pointCoralRed,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const InquiryWriteScreen()),
          );
        },
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip('전체', 'ALL'),
                        const SizedBox(width: 8),
                        _filterChip('답변 대기', 'pending'),
                        const SizedBox(width: 8),
                        _filterChip('답변 완료', 'answered'),
                        const SizedBox(width: 8),
                        _filterChip('문의 취소', 'cancelled'),
                        const SizedBox(width: 8),
                        _filterChip('문의 종료', 'closed'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildSortDropdown(),
              ],
            ),
          ),

          Divider(height: 1, color: deepChocolate.withOpacity(0.08)),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: deepChocolate));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('등록된 문의가 없어요', style: TextStyle(color: subTextColor)),
                  );
                }

                List<InquiryModel> inquiries = snapshot.data!.docs
                    .map((d) => InquiryModel.fromFirestore(d))
                    .toList();

                if (_selectedStatusFilter != 'ALL') {
                  inquiries = inquiries.where((r) => r.status == _selectedStatusFilter).toList();
                }

                if (inquiries.isEmpty) {
                  return const Center(
                    child: Text('해당하는 문의 내역이 없습니다.', style: TextStyle(color: subTextColor)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: inquiries.length,
                  itemBuilder: (context, index) {
                    final inquiry = inquiries[index];
                    return _buildInquiryCard(inquiry);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _selectedStatusFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedStatusFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? deepChocolate : Colors.white,
          border: Border.all(color: isSelected ? deepChocolate : deepChocolate.withOpacity(0.15)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : subTextColor,
            )
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    String displayLabel = _selectedSortType == 'CREATED_DESC' ? '문의 최신순' : '답변 최신순';

    return PopupMenuButton<String>(
      onSelected: (String value) {
        setState(() => _selectedSortType = value);
      },
      offset: const Offset(0, 40),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'CREATED_DESC',
          height: 40,
          child: Text('문의 최신순', style: TextStyle(fontSize: 13, color: deepChocolate, fontWeight: _selectedSortType == 'CREATED_DESC' ? FontWeight.bold : FontWeight.w500)),
        ),
        PopupMenuItem<String>(
          value: 'ANSWERED_DESC',
          height: 40,
          child: Text('답변 최신순', style: TextStyle(fontSize: 13, color: deepChocolate, fontWeight: _selectedSortType == 'ANSWERED_DESC' ? FontWeight.bold : FontWeight.w500)),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: deepChocolate.withOpacity(0.15)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(displayLabel, style: const TextStyle(fontSize: 12, color: subTextColor, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, color: subTextColor, size: 16),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('yyyy.MM.dd. HH:mm').format(date);
  }

  Widget _buildInquiryCard(InquiryModel r) {
    String statusLabel = r.displayStatus;
    if (r.status == 'cancelled') {
      statusLabel = '문의 취소';
    } else if (r.status == 'pending') {
      statusLabel = '답변 대기';
    } else if (r.status == 'answered') {
      statusLabel = '답변 완료';
    } else if (r.status == 'closed') {
      statusLabel = '문의 종료';
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => InquiryDetailScreen(inquiryId: r.id)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: deepChocolate.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: deepChocolate.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _twoItemRow(
              leftLabel: '문의번호', leftValue: r.id,
              rightLabel: '문의유형', rightValue: r.displayType,
            ),
            _twoItemRow(
              leftLabel: '문의일시', leftValue: _formatDate(r.createdAt),
              rightLabel: '상       태', rightValue: statusLabel,
              isRightHighlight: true,
            ),

            if (r.answeredAt != null)
              _singleItemRow('답변일시', _formatDate(r.answeredAt)),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: Color(0xFFF0EAE3)),
            ),

            _singleItemRow('제    목', r.title, maxLines: 1),
            _singleItemRow('내    용', r.content, maxLines: 1, isContent: true),
          ],
        ),
      ),
    );
  }

  Widget _singleItemRow(String label, String value, {int? maxLines, bool isContent = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '• $label: ',
              style: const TextStyle(fontSize: 13, color: subTextColor, fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                  fontSize: 14,
                  color: isContent ? deepChocolate.withOpacity(0.8) : deepChocolate,
                  fontWeight: isContent ? FontWeight.normal : FontWeight.w600
              ),
            ),
          ],
        ),
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
      ),
    );
  }

  Widget _twoItemRow({
    required String leftLabel,
    required String leftValue,
    required String rightLabel,
    required String rightValue,
    bool isRightHighlight = false,
  }) {
    Color getStatusColor(String statusText) {
      if (!isRightHighlight) return deepChocolate;
      if (statusText == '답변 대기') return pointCoralRed;
      if (statusText == '문의 취소' || statusText == '문의 종료') return subTextColor;
      return deepChocolate;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '• $leftLabel: ',
                    style: const TextStyle(fontSize: 13, color: subTextColor, fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: leftValue,
                    style: const TextStyle(fontSize: 13, color: deepChocolate, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 4,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '• $rightLabel: ',
                    style: const TextStyle(fontSize: 13, color: subTextColor, fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: rightValue,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isRightHighlight ? FontWeight.bold : FontWeight.w500,
                      color: getStatusColor(rightValue),
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}