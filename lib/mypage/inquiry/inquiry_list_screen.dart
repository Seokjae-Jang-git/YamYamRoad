import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// 🌟 서비스 및 공통 유저 데이터 (프로젝트 경로에 맞게 자동 임포트/확인해주세요)
import '../../services/auth_service.dart';
import '../../common/user_data.dart';

// 🌟 문의 모델 및 연동 화면들
import 'inquiry_model.dart';
import 'inquiry_detail_screen.dart';
import 'inquiry_write_screen.dart';

class InquiryListScreen extends StatefulWidget {
  const InquiryListScreen({Key? key}) : super(key: key);

  @override
  State<InquiryListScreen> createState() => _InquiryListScreenState();
}

class _InquiryListScreenState extends State<InquiryListScreen> {
  String get _currentUserId => AuthService.currentUser?.uid ?? UserData.uid ?? 'unknown_uid';

  // 필터 및 정렬 상태
  String _selectedStatusFilter = 'ALL'; // ALL / pending / answered
  String _selectedSortType = 'CREATED_DESC'; // CREATED_DESC / ANSWERED_DESC

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('inquiry')
        .where('userId', isEqualTo: _currentUserId);

    // 정렬 조건 적용 (문의 최신순 / 답변 최신순)
    if (_selectedSortType == 'CREATED_DESC') {
      query = query.orderBy('createdAt', descending: true);
    } else if (_selectedSortType == 'ANSWERED_DESC') {
      query = query.orderBy('answeredAt', descending: true);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        title: const Text(
          '문의 내역',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      // 설계안 기준: 둥근 흰색 + 플러스 버튼
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        shape: CircleBorder(side: BorderSide(color: Colors.grey.shade300)),
        elevation: 2,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const InquiryWriteScreen()),
          );
        },
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: Column(
        children: [
          // 상단 필터 및 정렬 영역
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 좌측: 상태 필터 (전체 / 답변 대기 / 답변 완료)
                Row(
                  children: [
                    _filterChip('전체', 'ALL'),
                    const SizedBox(width: 6),
                    _filterChip('답변 대기', 'pending'),
                    const SizedBox(width: 6),
                    _filterChip('답변 완료', 'answered'),
                  ],
                ),

                // 우측: 정렬 드롭다운
                _buildSortDropdown(),
              ],
            ),
          ),
          const Divider(height: 1),

          // 실시간 문의 내역 목록
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.black));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('등록된 문의가 없어요', style: TextStyle(color: Colors.grey)),
                  );
                }

                List<InquiryModel> inquiries = snapshot.data!.docs
                    .map((d) => InquiryModel.fromFirestore(d))
                    .toList();

                // 상태 필터링 적용
                if (_selectedStatusFilter != 'ALL') {
                  inquiries = inquiries.where((r) => r.status == _selectedStatusFilter).toList();
                }

                if (inquiries.isEmpty) {
                  return const Center(
                    child: Text('해당하는 문의 내역이 없습니다.', style: TextStyle(color: Colors.grey)),
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

  // 필터 칩 버튼
  Widget _filterChip(String label, String value) {
    final isSelected = _selectedStatusFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedStatusFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade200 : Colors.white,
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.black87)),
      ),
    );
  }

  // 정렬 드롭다운 (문의 최신순 / 답변 최신순)
  Widget _buildSortDropdown() {
    String displayLabel = _selectedSortType == 'CREATED_DESC' ? '문의 최신순' : '답변 최신순';

    return PopupMenuButton<String>(
      onSelected: (String value) {
        setState(() => _selectedSortType = value);
      },
      offset: const Offset(0, 32),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFFF3EEF8),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'CREATED_DESC',
          height: 40,
          child: Text('문의 최신순', style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500)),
        ),
        const PopupMenuItem<String>(
          value: 'ANSWERED_DESC',
          height: 40,
          child: Text('답변 최신순', style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500)),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(displayLabel, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  // 날짜 포맷팅 (설계안: 2026.07.27. 15:59)
  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('yyyy.MM.dd. HH:mm').format(date);
  }

  // 설계안 2열 카드 레이아웃
  // 🌟 설계안에 맞춘 최종 카드 레이아웃
  Widget _buildInquiryCard(InquiryModel r) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => InquiryDetailScreen(inquiryId: r.id)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 문의번호 / 문의유형
            _twoItemRow(
              leftLabel: '문의번호', leftValue: r.id,
              rightLabel: '문의유형', rightValue: r.displayType,
            ),

            // 2. 문의일시 / 상태
            _twoItemRow(
              leftLabel: '문의일시', leftValue: _formatDate(r.createdAt),
              rightLabel: '상태', rightValue: r.displayStatus,
              isRightHighlight: true,
            ),

            // 3. 답변일시 (답변이 있는 경우만)
            if (r.answeredAt != null)
              _singleItemRow('답변일시', _formatDate(r.answeredAt)),

            // 4. 제목
            _singleItemRow('제목', r.title, maxLines: 1),

            // 5. 내용
            _singleItemRow('내용', r.content, maxLines: 1),
          ],
        ),
      ),
    );
  }

  // 한 줄을 다 쓰는 항목 (답변일시, 제목, 내용)
  Widget _singleItemRow(String label, String value, {int? maxLines}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6), // 줄 간격을 살짝 넓혀 편안하게
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '• $label: ',
              style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
      ),
    );
  }

  // 두 개로 나뉘는 항목 (문의번호-유형, 문의일시-상태)
  Widget _twoItemRow({
    required String leftLabel,
    required String leftValue,
    required String rightLabel,
    required String rightValue,
    bool isRightHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          // 좌측: 화면의 60%를 차지
          Expanded(
            flex: 6,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '• $leftLabel: ',
                    style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: leftValue,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 우측: 화면의 40%를 차지 (시작점이 60% 지점으로 고정되어 세로줄이 완벽하게 맞음)
          Expanded(
            flex: 4,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '• $rightLabel: ',
                    style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: rightValue,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isRightHighlight ? FontWeight.bold : FontWeight.normal,
                      color: isRightHighlight && rightValue == '답변 대기' ? Colors.orange : Colors.black87,
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

  Widget _infoRow(String label, String value, {bool isHighlight = false, int? maxLines}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $label: ',
            style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: maxLines,
              overflow: maxLines != null ? TextOverflow.ellipsis : null,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                color: isHighlight && value == '답변 대기' ? Colors.orange : Colors.black87,
              ),
              softWrap: maxLines == null,
            ),
          ),
        ],
      ),
    );
  }
}