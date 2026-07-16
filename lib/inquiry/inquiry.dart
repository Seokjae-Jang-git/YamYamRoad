/// 문의 유형
enum InquiryType {
  general, // 일반문의
  adPartnership, // 광고·제휴
}

extension InquiryTypeX on InquiryType {
  String get label {
    switch (this) {
      case InquiryType.general:
        return '일반문의';
      case InquiryType.adPartnership:
        return '광고·제휴';
    }
  }
}

/// 문의 답변 상태
enum InquiryStatus {
  pending, // 답변대기
  answered, // 답변완료
}

extension InquiryStatusX on InquiryStatus {
  String get label => this == InquiryStatus.pending ? '답변대기' : '답변완료';
}

class Inquiry {
  final String id;
  InquiryType type;
  String title;
  String content;
  String email;
  String? imagePath;
  final String receiptNumber;
  final DateTime createdAt;
  InquiryStatus status;
  String? answer;

  Inquiry({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.email,
    this.imagePath,
    required this.receiptNumber,
    required this.createdAt,
    this.status = InquiryStatus.pending,
    this.answer,
  });

  Inquiry copyWith({
    InquiryType? type,
    String? title,
    String? content,
    String? email,
    String? imagePath,
    InquiryStatus? status,
    String? answer,
  }) {
    return Inquiry(
      id: id,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      email: email ?? this.email,
      imagePath: imagePath ?? this.imagePath,
      receiptNumber: receiptNumber,
      createdAt: createdAt,
      status: status ?? this.status,
      answer: answer ?? this.answer,
    );
  }
}
