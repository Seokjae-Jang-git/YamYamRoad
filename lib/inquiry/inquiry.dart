import 'package:cloud_firestore/cloud_firestore.dart';

enum InquiryType {
  general('일반문의'),
  partnership('광고·제휴');

  final String label;
  const InquiryType(this.label);

  static InquiryType fromName(String name) {
    return InquiryType.values.firstWhere(
          (e) => e.name == name,
      orElse: () => InquiryType.general,
    );
  }
}

enum InquiryStatus {
  pending,
  answered,
  closed;

  static InquiryStatus fromName(String name) {
    return InquiryStatus.values.firstWhere(
          (e) => e.name == name,
      orElse: () => InquiryStatus.pending,
    );
  }
}

class Inquiry {
  final String id;
  final String? userId; // 🌟 비회원 문의 허용 시 null 가능
  final InquiryType type;
  final String title;
  final String content;
  final String? contactEmail;
  final String? imageUrl;
  final DateTime createdAt;
  final InquiryStatus status;
  final String? adminMemo; // 🌟 관리자 답변/메모
  final DateTime? answeredAt;

  const Inquiry({
    required this.id,
    this.userId,
    required this.type,
    required this.title,
    required this.content,
    this.contactEmail,
    this.imageUrl,
    required this.createdAt,
    this.status = InquiryStatus.pending,
    this.adminMemo,
    this.answeredAt,
  });

  /// 스키마에 별도 접수번호 필드가 없어서, 문서 ID/생성일 기준으로 표시용 접수번호를 만듭니다.
  String get receiptNumber {
    final datePart =
        '${createdAt.year}${createdAt.month.toString().padLeft(2, '0')}${createdAt.day.toString().padLeft(2, '0')}';
    final shortId = id.length >= 6 ? id.substring(0, 6).toUpperCase() : id.toUpperCase();
    return '#$datePart-$shortId';
  }

  bool get isAnswered => status == InquiryStatus.answered;

  Inquiry copyWith({
    InquiryType? type,
    String? title,
    String? content,
    String? contactEmail,
    String? imageUrl,
    InquiryStatus? status,
    String? adminMemo,
    DateTime? answeredAt,
  }) {
    return Inquiry(
      id: id,
      userId: userId,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      contactEmail: contactEmail ?? this.contactEmail,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt,
      status: status ?? this.status,
      adminMemo: adminMemo ?? this.adminMemo,
      answeredAt: answeredAt ?? this.answeredAt,
    );
  }

  factory Inquiry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Inquiry(
      id: doc.id,
      userId: data['userId'] as String?,
      type: InquiryType.fromName(data['type'] as String? ?? 'general'),
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      contactEmail: data['contactEmail'] as String?,
      imageUrl: data['imageUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: InquiryStatus.fromName(data['status'] as String? ?? 'pending'),
      adminMemo: data['adminMemo'] as String?,
      answeredAt: (data['answeredAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'content': content,
      'contactEmail': contactEmail,
      'imageUrl': imageUrl,
      'status': InquiryStatus.pending.name,
      'adminMemo': null,
      'createdAt': FieldValue.serverTimestamp(),
      'answeredAt': null,
    };
  }
}