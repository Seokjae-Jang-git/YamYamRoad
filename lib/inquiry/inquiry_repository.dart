import 'package:flutter/foundation.dart';
import 'inquiry.dart';

/// 문의 데이터를 관리하는 Repository.
/// 지금은 인메모리(Mock) 데이터로 동작하지만, 실제 서버 연동 시
/// add/update/delete 내부 구현만 API 호출로 바꾸면 화면 코드는 그대로 재사용 가능.
class InquiryRepository extends ChangeNotifier {
  InquiryRepository._internal() {
    _seedMockData();
  }

  static final InquiryRepository instance = InquiryRepository._internal();

  final List<Inquiry> _inquiries = [];

  List<Inquiry> get inquiries => List.unmodifiable(
    _inquiries..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
  );

  void _seedMockData() {
    _inquiries.add(
      Inquiry(
        id: 'seed-1',
        type: InquiryType.general,
        title: '스탬프가 적립이 안 돼요',
        content: '매장에서 결제 후 스탬프 적립을 눌렀는데 반영이 되지 않습니다. 확인 부탁드립니다.',
        email: 'example@email.com',
        receiptNumber: '#20260713-042',
        createdAt: DateTime(2026, 7, 13),
        status: InquiryStatus.pending,
      ),
    );
  }

  String _generateReceiptNumber() {
    final now = DateTime.now();
    final datePart =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final seq = (_inquiries.length + 1).toString().padLeft(3, '0');
    return '#$datePart-$seq';
  }

  /// 문의 등록. 생성된 Inquiry를 반환한다 (접수번호 표시용).
  Inquiry add({
    required InquiryType type,
    required String title,
    required String content,
    required String email,
    String? imagePath,
  }) {
    final inquiry = Inquiry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      title: title,
      content: content,
      email: email,
      imagePath: imagePath,
      receiptNumber: _generateReceiptNumber(),
      createdAt: DateTime.now(),
    );
    _inquiries.add(inquiry);
    notifyListeners();
    return inquiry;
  }

  /// 문의 수정 (제목/내용/이메일/유형/이미지만 수정 가능, 접수번호·작성일은 유지)
  void update({
    required String id,
    required InquiryType type,
    required String title,
    required String content,
    required String email,
    String? imagePath,
  }) {
    final index = _inquiries.indexWhere((e) => e.id == id);
    if (index == -1) return;
    _inquiries[index] = _inquiries[index].copyWith(
      type: type,
      title: title,
      content: content,
      email: email,
      imagePath: imagePath,
    );
    notifyListeners();
  }

  /// 문의 삭제
  void delete(String id) {
    _inquiries.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Inquiry? findById(String id) {
    try {
      return _inquiries.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}
