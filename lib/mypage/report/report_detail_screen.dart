import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'report_model.dart';

class ReportDetailScreen extends StatefulWidget {
  final String reportId;

  const ReportDetailScreen({Key? key, required this.reportId}) : super(key: key);

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  // 공통 색상 팔레트
  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color creamyIvory = Color(0xFFFFFDF9);
  static const Color subTextColor = Color(0xFF7A6B63);

  bool _isCanceling = false;

  // 원본 대상(게시글/댓글/유저) 데이터 로드
  Future<Map<String, dynamic>> _fetchTargetData(String targetType, String targetId) async {
    if (targetId.isEmpty) {
      return {'nickname': '알 수 없음', 'content': '내용이 없습니다.', 'imageUrls': <String>[], 'emoticonUrl': null};
    }

    try {
      final type = targetType.toLowerCase();

      if (type == 'post' || type == 'feed') {
        final doc = await FirebaseFirestore.instance.collection('posts').doc(targetId).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;

          List<String> parsedImages = [];
          if (data['imageUrls'] != null) {
            parsedImages = List<String>.from(data['imageUrls']);
          }

          return {
            'nickname': data['nickname'] ?? data['authorNickname'] ?? '익명',
            'content': data['content'] ?? '내용이 없습니다.',
            'imageUrls': parsedImages,
            'emoticonUrl': data['emoticonUrl'],
          };
        }
      } else if (type == 'comment') {
        final doc = await FirebaseFirestore.instance.collection('comments').doc(targetId).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          return {
            'nickname': data['nickname'] ?? '익명',
            'content': data['content'] ?? '내용이 없습니다.',
            'imageUrls': <String>[],
            'emoticonUrl': data['emoticonUrl'],
          };
        }
      }
    } catch (e) {
      debugPrint('원본 콘텐츠 로드 실패: $e');
    }
    return {'nickname': '알 수 없음(삭제됨)', 'content': '삭제되었거나 찾을 수 없는 콘텐츠입니다.', 'imageUrls': <String>[], 'emoticonUrl': null};
  }

  // 신고 취소 처리
  Future<void> _onCancelReport() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: creamyIvory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('신고 취소', style: TextStyle(color: deepChocolate, fontWeight: FontWeight.bold)),
        content: const Text('접수하신 신고를 취소하시겠습니까?', style: TextStyle(color: deepChocolate)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('닫기', style: TextStyle(color: subTextColor)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('신고 취소', style: TextStyle(color: pointCoralRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCanceling = true);

    try {
      await FirebaseFirestore.instance.collection('reports').doc(widget.reportId).update({
        'status': 'canceled'
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('신고가 취소되었습니다.')));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCanceling = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('신고 취소에 실패했습니다: $e')));
    }
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
          '신고 상세',
          style: TextStyle(color: deepChocolate, fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('reports').doc(widget.reportId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: deepChocolate));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('존재하지 않거나 삭제된 신고입니다.', style: TextStyle(color: subTextColor)));
          }

          final report = ReportModel.fromFirestore(snapshot.data! as DocumentSnapshot<Map<String, dynamic>>);
          final bool isPending = report.status.toLowerCase() == 'pending';
          final bool isCompleted = report.status.toLowerCase() == 'completed';

          return FutureBuilder<Map<String, dynamic>>(
              future: _fetchTargetData(report.targetType, report.targetId),
              builder: (context, targetSnapshot) {
                if (targetSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: deepChocolate));
                }

                final targetData = targetSnapshot.data ?? {};
                final nickname = targetData['nickname'] ?? '알 수 없음';
                final content = targetData['content'] ?? '내용이 없습니다.';
                final List<String> imageUrls = (targetData['imageUrls'] as List<dynamic>?)?.cast<String>() ?? [];
                final emoticonUrl = targetData['emoticonUrl'];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. 신고 상세 정보 카드
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: _cardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow('신고번호', report.id),
                            _infoRow('신고사유', report.reason),
                            _infoRow('신고일시', report.formattedCreatedAt),
                            _infoRow('상    태', _getDisplayStatus(report.status), isHighlight: true),

                            if (isCompleted) ...[
                              _infoRow('처리결과', _getDisplayResolution(report.resolution)),
                              _infoRow('처리일시', report.formattedResolvedAt),
                            ],

                            _infoRow('타    입', report.targetTypeLabel),
                            _infoRow('닉네임', nickname),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 2. 본문 내용 카드
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 8),
                        child: Text('• 원본 내용', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: subTextColor)),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: _cardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(content, style: const TextStyle(fontSize: 15, color: deepChocolate, height: 1.5)),

                            if (emoticonUrl != null) ...[
                              const SizedBox(height: 16),
                              Image.network(emoticonUrl, height: 100, fit: BoxFit.contain),
                            ]
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 3. 첨부 이미지 리스트 미리보기
                      if (imageUrls.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 8),
                          child: Text('• 첨부 이미지', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: subTextColor)),
                        ),
                        ...imageUrls.map((url) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            width: double.infinity,
                            decoration: _cardDecoration(),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                url,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const Padding(
                                    padding: EdgeInsets.all(40.0),
                                    child: Center(child: CircularProgressIndicator(color: deepChocolate)),
                                  );
                                },
                              ),
                            ),
                          ),
                        )).toList(),
                        const SizedBox(height: 24),
                      ],

                      // 4. 신고 취소 버튼
                      if (isPending)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _isCanceling ? null : _onCancelReport,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.white,
                              side: BorderSide(color: deepChocolate.withOpacity(0.15)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isCanceling
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: subTextColor),
                            )
                                : const Text('신고 취소', style: TextStyle(fontSize: 16, color: subTextColor, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                );
              }
          );
        },
      ),
    );
  }

  // 공통 카드 데코레이션
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
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
    );
  }

  // 리스트 UI와 통일된 Row 스타일
  Widget _infoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• $label: ', style: const TextStyle(fontSize: 14, color: subTextColor, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
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