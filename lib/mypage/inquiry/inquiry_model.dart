import 'package:cloud_firestore/cloud_firestore.dart';

class InquiryModel {
  final String id; // INQ-YYYYMMDD-XXXX 포맷의 문서 ID
  final String? userId; // 비회원 문의 허용 시 nullable
  final String type; // 'general', 'partnership'
  final String title;
  final String content;
  final String? contactEmail;
  final String? imageUrl; // 🌟 팀원 코드 참고하여 첨부 이미지 필드 추가
  final String status; // 'pending', 'answered', 'closed'
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
      case 'closed':
        return '종료';
      default:
        return status;
    }
  }

  /// 새로운 문의를 작성하여 DB에 저장할 때 사용하는 Map 변환 함수
  Map<String, dynamic> toCreateMap() {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'content': content,
      'contactEmail': contactEmail,
      'imageUrl': imageUrl,
      'status': 'pending', // 새 문의는 무조건 답변 대기 상태
      'adminMemo': null,
      'createdAt': FieldValue.serverTimestamp(),
      'answeredAt': null,
    };
  }
}