import 'package:cloud_firestore/cloud_firestore.dart';

class InquiryModel {
  final String id;
  final String? userId;
  final String type;
  final String title;
  final String content;
  final String? contactEmail;
  final String? imageUrl;
  final String status;
  final String? adminMemo;
  final DateTime? createdAt;
  final DateTime? answeredAt;

  InquiryModel({
    required this.id,
    this.userId,
    required this.type,
    required this.title,
    required this.content,
    this.contactEmail,
    this.imageUrl,
    required this.status,
    this.adminMemo,
    this.createdAt,
    this.answeredAt,
  });

  /// Firestore 문서에서 데이터를 읽어와 모델로 변환하는 팩토리 생성자
  factory InquiryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return InquiryModel(
      id: doc.id,
      userId: data['userId'] as String?,
      type: data['type'] as String? ?? 'general',
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      contactEmail: data['contactEmail'] as String?,
      imageUrl: data['imageUrl'] as String?,
      status: data['status'] as String? ?? 'pending',
      adminMemo: data['adminMemo'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      answeredAt: (data['answeredAt'] as Timestamp?)?.toDate(),
    );
  }

  /// 🌟 UI 화면에 보여줄 때 사용할 한글 변환 Getter (설계안 기준)
  String get displayType => type == 'partnership' ? '광고/제휴' : '일반';

  String get displayStatus {
    switch (status) {
      case 'pending':
        return '답변 대기';
      case 'answered':
        return '답변 완료';
      case 'cancelled':
        return '문의 취소';
      case 'closed':
        return '문의 종료';
      default:
        return status;
    }
  }
}