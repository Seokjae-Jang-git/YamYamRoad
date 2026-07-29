import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../common/user_data.dart';
import 'report_model.dart';

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({Key? key}) : super(key: key);

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  String get _currentUserId => AuthService.currentUser?.uid ?? UserData.uid ?? 'unknown_uid';

  // 필터 및 정렬 상태 관리
  String _selectedStatusFilter = 'ALL'; // ALL / pending / completed (DB 값과 매칭)
  String _selectedSortType = 'CREATED_DESC'; // CREATED_DESC / RESOLVED_DESC / ID_ASC

  // targetId 기반 닉네임 캐시
  final Map<String, String> _reportedNicknameCache = {};

  // targetId를 이용해 posts(또는 users, comments) 컬렉션에서 피신고자 닉네임 조회
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

    // 🌟 정렬 기준: DB 스키마에 맞춰 'resolved_at'으로 수정
    if (_selectedSortType == 'CREATED_DESC') {
      query = query.orderBy('createdAt', descending: true);
    } else if (_selectedSortType == 'RESOLVED_DESC') {
      query = query.orderBy('resolved_at', descending: true);
    } else if (_selectedSortType == 'ID_ASC') {
      query = query.orderBy(FieldPath.documentId, descending: false);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('신고', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      body: Column(
        children: [
          // 상단 필터 및 정렬 영역
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 좌측: 상태 필터 (🌟 DB 값과 완벽히 매칭되도록 소문자로 변경)
                  Row(
                    children: [
                      _filterChip('전체', 'ALL'),
                      const SizedBox(width: 6),
                      _filterChip('접수 완료', 'pending'),
                      const SizedBox(width: 6),
                      _filterChip('처리 중', 'in_review'), // 🌟 새로 추가된 탭
                      const SizedBox(width: 6),
                      _filterChip('처리 완료', 'completed'),
                    ],
                  ),

                  const SizedBox(width: 40),

                  // 우측: 정렬
                  Row(
                    children: [
                      _buildRecentSortDropdown(),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // 신고 내역 리스트
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.orange));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('신고 내역이 없습니다.', style: TextStyle(color: Colors.grey)));
                }

                List<ReportModel> reports = snapshot.data!.docs
                    .map((d) => ReportModel.fromFirestore(d))
                    .toList();

                // 🌟 필터링 적용 (대소문자 일치)
                if (_selectedStatusFilter != 'ALL') {
                  reports = reports.where((r) => r.status == _selectedStatusFilter).toList();
                }

                if (reports.isEmpty) {
                  return const Center(child: Text('해당하는 신고 내역이 없습니다.', style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final r = reports[index];
                    return _buildReportCard(r);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 최신순 드롭다운 버튼
  Widget _buildRecentSortDropdown() {
    final isRecentActive = _selectedSortType == 'CREATED_DESC' || _selectedSortType == 'RESOLVED_DESC';

    String displayLabel = '접수 최신순';
    if (_selectedSortType == 'RESOLVED_DESC') {
      displayLabel = '처리 최신순';
    }

    return PopupMenuButton<String>(
      onSelected: (String value) {
        setState(() {
          _selectedSortType = value;
        });
      },
      offset: const Offset(0, 32),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: const Color(0xFFF3EEF8),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'CREATED_DESC',
          height: 40,
          child: Text('접수 최신순', style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500)),
        ),
        const PopupMenuItem<String>(
          value: 'RESOLVED_DESC', // 🌟 명칭 동기화
          height: 40,
          child: Text('처리 최신순', style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500)),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isRecentActive ? Colors.black : Colors.white,
          border: isRecentActive ? null : Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayLabel,
              style: TextStyle(
                fontSize: 11,
                color: isRecentActive ? Colors.white : Colors.black87,
                fontWeight: isRecentActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              color: isRecentActive ? Colors.white : Colors.black87,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // 상태 영문 -> 한글 변환 (공백 제거 및 디버그 프린트 추가)
  String _getDisplayStatus(String status) {

    // 🌟 2. 양옆 공백을 완전히 제거(.trim())한 후 소문자로 비교합니다.
    switch (status.trim().toLowerCase()) {
      case 'pending':
        return '접수 완료';
      case 'in_review':
        return '처리 중';
      case 'completed':
        return '처리 완료';
      default:
      // 지정되지 않은 값일 경우 원본을 그대로 보여주어 문제 확인이 가능하게 함
        return status;
    }
  }

  // 처리 결과 영문 -> 한글 변환
  String _getDisplayResolution(String? resolution) {
    if (resolution == null || resolution.isEmpty) return '-';

    switch (resolution.toLowerCase()) {
      case 'content_deleted':
        return '게시물 삭제';
      case 'dismissed':
        return '반려';
      case 'user_suspended':
        return '계정 정지';
      default:
        return resolution;
    }
  }

  // 신고 내역 카드
  Widget _buildReportCard(ReportModel r) {
    String displayStatus = _getDisplayStatus(r.status);
    String displayResolution = _getDisplayResolution(r.resolution);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 왼쪽 컬럼
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('신고번호', r.id),
                const SizedBox(height: 4),
                _infoRow('신고사유', r.reason),
                const SizedBox(height: 4),
                _infoRow('신고일시', r.formattedCreatedAt),
                const SizedBox(height: 4),
                _infoRow('처리일시', r.formattedResolvedAt),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 오른쪽 컬럼
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('타입', r.targetTypeLabel),
                const SizedBox(height: 4),

                FutureBuilder<String>(
                  future: _getReportedNickname(r.targetType, r.targetId),
                  builder: (context, snapshot) {
                    final nickname = snapshot.data ?? '로딩 중...';
                    return _infoRow('닉네임', nickname);
                  },
                ),
                const SizedBox(height: 4),

                _infoRow('상태', displayStatus, isHighlight: true),
                const SizedBox(height: 4),
                _infoRow('처리결과', displayResolution),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 텍스트 줄바꿈 허용 처리 추가
  Widget _infoRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• $label: ',
          style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              // 🌟 '처리 완료'와 정확히 매칭되어 오렌지색으로 표시됨
              color: isHighlight && value == '처리 완료' ? Colors.orange : Colors.black87,
            ),
            softWrap: true,
          ),
        ),
      ],
    );
  }

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
}