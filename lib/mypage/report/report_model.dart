import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String targetType; // post / comment / user
  final String targetId;
  final String userId; // 신고자 uid
  final String reason;
  final String? detail;
  final String status; // pending / resolved / rejected
  final DateTime? createdAt;

  ReportModel({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.userId,
    required this.reason,
    this.detail,
    this.status = 'pending',
    this.createdAt,
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      targetType: data['targetType'] ?? '',
      targetId: data['targetId'] ?? '',
      userId: data['userId'] ?? '',
      reason: data['reason'] ?? '',
      detail: data['detail'],
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}