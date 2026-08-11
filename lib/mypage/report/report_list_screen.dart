import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../common/user_data.dart';
import 'report_detail_screen.dart';
import 'report_model.dart';

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({Key? key}) : super(key: key);

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color creamyIvory = Color(0xFFFFFDF9);
  static const Color subTextColor = Color(0xFF7A6B63);

  String get _currentUserId => AuthService.currentUser?.uid ?? UserData.uid ?? 'unknown_uid';

  String _selectedStatusFilter = 'ALL';
  String _selectedSortType = 'CREATED_DESC';

  final Map<String, String> _reportedNicknameCache = {};

  // 스크롤 컨트롤러 및 최상단 이동 버튼 상태
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTopButton = false;

  @override
  void initState() {
    super.initState();
    // 스크롤이 400픽셀 이상 내려가면 위로가기 버튼 표시
    _scrollController.addListener(() {
      if (_scrollController.offset >= 400 && !_showBackToTopButton) {
        setState(() => _showBackToTopButton = true);
      } else if (_scrollController.offset < 400 && _showBackToTopButton) {
        setState(() => _showBackToTopButton = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 최상단으로 부드럽게 이동
  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  // 당겨서 새로고침
  Future<void> _onRefresh() async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<String> _getReportedNickname(String targetType, String targetId) async {
    if (targetId.isEmpty) return '알 수 없음';

    final cacheKey = '${targetType}_$targetId';
    if (_reportedNicknameCache.containsKey(cacheKey)) {
      return _reportedNicknameCache[cacheKey]!;
    }

    try {
      final type = targetType.toLowerCase();

      if (type == 'post' || type == 'feed') {
        final doc = await FirebaseFirestore.instance.collection('posts').doc(targetId).get();
        if (doc.exists && doc.data() != null) {
          final nickname = doc.data()!['nickname'] ?? doc.data()!['authorNickname'] ?? '익명';
          _reportedNicknameCache[cacheKey] = nickname;
          return nickname;
        }
      } else if (type == 'user') {
        final doc = await FirebaseFirestore.instance.collection('users').doc(targetId).get();
        if (doc.exists && doc.data() != null) {
          final nickname = doc.data()!['nickname'] ?? doc.data()!['name'] ?? '익명';
          _reportedNicknameCache[cacheKey] = nickname;
          return nickname;
        }
      } else if (type == 'comment') {
        final doc = await FirebaseFirestore.instance.collection('comments').doc(targetId).get();
        if (doc.exists && doc.data() != null) {
          final nickname = doc.data()!['nickname'] ?? '익명';
          _reportedNicknameCache[cacheKey] = nickname;
          return nickname;
        }
      }
    } catch (e) {
      debugPrint('피신고자 닉네임 로드 실패: $e');
    }
    return '알 수 없음';
  }

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('reports')
        .where('userId', isEqualTo: _currentUserId);

    if (_selectedSortType == 'CREATED_DESC') {
      query = query.orderBy('createdAt', descending: true);
    } else if (_selectedSortType == 'RESOLVED_DESC') {
      query = query.orderBy('resolved_at', descending: true);
    } else if (_selectedSortType == 'ID_ASC') {
      query = query.orderBy(FieldPath.documentId, descending: false);
    }

    return Scaffold(
      backgroundColor: creamyIvory,
      appBar: AppBar(
        backgroundColor: creamyIvory,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: deepChocolate, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: _scrollToTop, // 타이틀 터치 시 최상단 이동
          child: const Text(
              '신고 내역',
              style: TextStyle(color: deepChocolate, fontWeight: FontWeight.bold, fontSize: 22)
          ),
        ),
      ),
      // 최상단 이동 플로팅 버튼
      floatingActionButton: _showBackToTopButton
          ? FloatingActionButton(
        backgroundColor: pointCoralRed,
        elevation: 3,
        onPressed: _scrollToTop,
        child: const Icon(Icons.arrow_upward, color: Colors.white),
      )
          : null,
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
                        _filterChip('접수 완료', 'pending'),
                        const SizedBox(width: 8),
                        _filterChip('처리 중', 'in_review'),
                        const SizedBox(width: 8),
                        _filterChip('처리 완료', 'completed'),
                        const SizedBox(width: 8),
                        _filterChip('신고 취소', 'canceled'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildRecentSortDropdown(),
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

                // 데이터가 없을 때도 당겨서 새로고침 유지
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return RefreshIndicator(
                    color: pointCoralRed,
                    backgroundColor: Colors.white,
                    onRefresh: _onRefresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: const Center(
                              child: Text('신고 내역이 없습니다.', style: TextStyle(color: subTextColor))
                          ),
                        ),
                      ],
                    ),
                  );
                }

                List<ReportModel> reports = snapshot.data!.docs
                    .map((d) => ReportModel.fromFirestore(d))
                    .toList();

                if (_selectedStatusFilter != 'ALL') {
                  reports = reports.where((r) => r.status == _selectedStatusFilter).toList();
                }

                if (reports.isEmpty) {
                  return RefreshIndicator(
                    color: pointCoralRed,
                    backgroundColor: Colors.white,
                    onRefresh: _onRefresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: const Center(
                              child: Text('해당하는 신고 내역이 없습니다.', style: TextStyle(color: subTextColor))
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: pointCoralRed,
                  backgroundColor: Colors.white,
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    controller: _scrollController, // 컨트롤러 연결
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final r = reports[index];
                      return _buildReportCard(r);
                    },
                  ),
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

  Widget _buildRecentSortDropdown() {
    String displayLabel = '접수 최신순';
    if (_selectedSortType == 'RESOLVED_DESC') {
      displayLabel = '처리 최신순';
    } else if (_selectedSortType == 'ID_ASC') {
      displayLabel = '번호순';
    }

    return PopupMenuButton<String>(
      onSelected: (String value) {
        setState(() {
          _selectedSortType = value;
        });
      },
      offset: const Offset(0, 40),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'CREATED_DESC',
          height: 40,
          child: Text('접수 최신순', style: TextStyle(fontSize: 13, color: deepChocolate, fontWeight: _selectedSortType == 'CREATED_DESC' ? FontWeight.bold : FontWeight.w500)),
        ),
        PopupMenuItem<String>(
          value: 'RESOLVED_DESC',
          height: 40,
          child: Text('처리 최신순', style: TextStyle(fontSize: 13, color: deepChocolate, fontWeight: _selectedSortType == 'RESOLVED_DESC' ? FontWeight.bold : FontWeight.w500)),
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

  String _getDisplayStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'pending': return '접수 완료';
      case 'in_review': return '처리 중';
      case 'completed': return '처리 완료';
      case 'canceled': return '신고 취소';
      default: return status;
    }
  }

  String _getDisplayResolution(String? resolution) {
    if (resolution == null || resolution.isEmpty) return '-';

    switch (resolution.toLowerCase()) {
      case 'content_deleted': return '게시물 삭제';
      case 'dismissed': return '반려';
      case 'user_suspended': return '계정 정지';
      default: return resolution;
    }
  }

  Widget _buildReportCard(ReportModel r) {
    String displayStatus = _getDisplayStatus(r.status);
    String displayResolution = _getDisplayResolution(r.resolution);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReportDetailScreen(reportId: r.id),
          ),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow('신고번호', r.id),
                  _infoRow('신고사유', r.reason),
                  _infoRow('신고일시', r.formattedCreatedAt),
                  _infoRow('처리일시', r.formattedResolvedAt),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow('타   입', r.targetTypeLabel),
                  FutureBuilder<String>(
                    future: _getReportedNickname(r.targetType, r.targetId),
                    builder: (context, snapshot) {
                      final nickname = snapshot.data ?? '로딩 중...';
                      return _infoRow('닉네임', nickname);
                    },
                  ),
                  _infoRow('상   태', displayStatus, isHighlight: true),
                  _infoRow('결   과', displayResolution),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $label: ',
            style: const TextStyle(fontSize: 13, color: subTextColor, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                color: isHighlight && value == '처리 완료' ? pointCoralRed : deepChocolate,
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}