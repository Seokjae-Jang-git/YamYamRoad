import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../common/user_data.dart';
import 'report_model.dart';


class ReportListScreen extends StatelessWidget {
  const ReportListScreen({Key? key}) : super(key: key);

  String get _currentUserId => AuthService.currentUser?.uid ?? UserData.uid ?? 'unknown_uid';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('신고 내역', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .where('userId', isEqualTo: _currentUserId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }
          final reports = snapshot.data!.docs.map((d) => ReportModel.fromFirestore(d)).toList();

          if (reports.isEmpty) {
            return const Center(
              child: Text('신고 내역이 없어요.', style: TextStyle(color: Colors.grey, fontSize: 13)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            separatorBuilder: (_, __) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final r = reports[index];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_targetTypeLabel(r.targetType),
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(r.reason, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        if (r.detail != null && r.detail!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(r.detail!, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                        ],
                        if (r.createdAt != null) ...[
                          const SizedBox(height: 4),
                          Text('${r.createdAt!.year}.${r.createdAt!.month}.${r.createdAt!.day}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ],
                    ),
                  ),
                  _buildStatusChip(r.status),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _targetTypeLabel(String type) {
    switch (type) {
      case 'post': return '게시글 신고';
      case 'comment': return '댓글 신고';
      case 'user': return '사용자 신고';
      default: return '신고';
    }
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'resolved':
        color = Colors.green;
        label = '처리완료';
        break;
      case 'rejected':
        color = Colors.grey;
        label = '반려됨';
        break;
      default:
        color = const Color(0xFFFF8A3D);
        label = '처리중';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
    );
  }
}