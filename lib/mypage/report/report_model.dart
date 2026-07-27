import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String userId; // 신고자 ID
  final String targetType;
  final String targetId;
  final String reason;
  final String status;
  final String? resolution;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  ReportModel({
    required this.id,
    required this.userId,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.status,
    this.resolution,
    this.createdAt,
    this.resolvedAt,
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // 🌟 [핵심 수정] 이분법(PENDING/COMPLETED) 및 대문자 변환 로직을 제거하고,
    // DB에 있는 값 그대로(소문자) 안전하게 가져옵니다.
    final status = (data['status'] ?? 'pending').toString().toLowerCase();

    return ReportModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      targetType: data['targetType'] ?? data['target_type'] ?? 'post',
      targetId: data['targetId'] ?? '',
      reason: data['reason'] ?? '일반 신고',
      status: status, // 🌟 DB 원본 값 그대로 저장 ('pending', 'in_review', 'completed')
      resolution: data['resolution'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      resolvedAt: ((data['resolvedAt'] ?? data['resolved_at']) as Timestamp?)?.toDate(),
    );
  }

  String get targetTypeLabel {
    switch (targetType.toLowerCase()) {
      case 'post':
      case 'feed':
        return '피드';
      case 'comment':
        return '댓글';
      case 'user':
        return '사용자';
      default:
        return targetType;
    }
  }

  // 🌟 (선택) ReportListScreen에서 _getDisplayStatus로 처리하고 있어서 필수는 아니지만,
  // 모델 내부의 getter도 새 DB 구조에 맞게 최신화해 두었습니다.
  String get statusLabel {
    switch (status) {
      case 'pending': return '접수 완료';
      case 'in_review': return '처리 중';
      case 'completed': return '처리 완료';
      default: return status;
    }
  }

  // 🌟 처리 결과 getter 역시 스키마 정의서에 맞게 정리했습니다.
  String get resolutionLabel {
    if (resolution == null || resolution!.isEmpty) return '-';
    switch (resolution!.toLowerCase()) {
      case 'content_deleted':
        return '게시물 삭제';
      case 'dismissed':
        return '반려';
      case 'user_suspended':
        return '계정 정지';
      default:
        return resolution!;
    }
  }

  // 신고일자: 년.월.일 시:분
  String get formattedCreatedAt {
    if (createdAt == null) return '-';
    final y = createdAt!.year;
    final m = createdAt!.month.toString().padLeft(2, '0');
    final d = createdAt!.day.toString().padLeft(2, '0');
    final hh = createdAt!.hour.toString().padLeft(2, '0');
    final mm = createdAt!.minute.toString().padLeft(2, '0');
    return '$y. $m. $d $hh:$mm';
  }

  // 처리일자: 년.월.일 시:분 (시간, 분 반영 완료!)
  String get formattedResolvedAt {
    if (resolvedAt == null) return '-';
    final y = resolvedAt!.year;
    final m = resolvedAt!.month.toString().padLeft(2, '0');
    final d = resolvedAt!.day.toString().padLeft(2, '0');
    final hh = resolvedAt!.hour.toString().padLeft(2, '0');
    final mm = resolvedAt!.minute.toString().padLeft(2, '0');
    return '$y. $m. $d $hh:$mm';
  }
}