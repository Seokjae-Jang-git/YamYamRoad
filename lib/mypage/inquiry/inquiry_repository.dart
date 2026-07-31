import 'dart:io';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../services/auth_service.dart';

/// 문의 데이터를 생성, 수정, 삭제하고 이미지를 업로드하는 순수 Repository
class InquiryRepository {
  InquiryRepository._internal();
  static final InquiryRepository instance = InquiryRepository._internal();

  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  // 🌟 컬렉션명 (리스트/상세 화면과 동일하게 'inquiries' 사용)
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('inquiry');

  // 🌟 팀원이 작성해둔 훌륭한 이미지 업로드 로직 (그대로 활용!)
  Future<String?> _uploadImageIfNeeded(String? imagePath) async {
    if (imagePath == null) return null;
    if (imagePath.startsWith('http')) return imagePath; // 이미 업로드된 URL이면 패스

    final uid = AuthService.currentUser?.uid ?? 'unknown';
    final fileName = '${DateTime.now().microsecondsSinceEpoch}.jpg';
    final ref = _storage.ref('inquiry_images/$uid/$fileName');

    await ref.putFile(File(imagePath));
    return await ref.getDownloadURL();
  }

  // 🌟 커스텀 문의번호 (INQ-YYYYMMDD-XXXX) 100% 중복 없는 채번 로직
  Future<String> _generateUniqueInquiryId() async {
    final String dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    String inquiryId;
    bool isDuplicate = true;

    do {
      final randomCode = List.generate(4, (index) => chars[random.nextInt(chars.length)]).join();
      inquiryId = 'INQ-$dateStr-$randomCode';
      try {
        final doc = await _collection.doc(inquiryId).get();
        isDuplicate = doc.exists;
      } catch (_) {
        isDuplicate = false;
      }
    } while (isDuplicate);

    return inquiryId;
  }

  /// 문의 등록 (저장된 문의번호 ID를 반환합니다)
  Future<String> add({
    required String type, // 'general' 또는 'partnership'
    required String title,
    required String content,
    String? contactEmail,
    String? imagePath,
  }) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) {
      throw StateError('로그인이 필요합니다.');
    }

    // 1. 이미지가 있다면 Storage에 먼저 업로드
    final imageUrl = await _uploadImageIfNeeded(imagePath);

    // 2. INQ- 문의번호 생성
    final inquiryId = await _generateUniqueInquiryId();

    // 3. Firestore 문서 ID를 지정하여 저장 (.set 활용)
    await _collection.doc(inquiryId).set({
      'userId': uid,
      'type': type,
      'title': title,
      'content': content,
      'contactEmail': contactEmail,
      'imageUrl': imageUrl,
      'status': 'pending', // 새 문의는 무조건 답변 대기
      'adminMemo': null,
      'createdAt': FieldValue.serverTimestamp(),
      'answeredAt': null,
    });

    return inquiryId; // 성공 화면에 전달하기 위해 생성된 ID 반환
  }

  /// 문의 수정 (제목/내용/이메일/유형/이미지만 수정 가능)
  Future<void> update({
    required String id,
    required String type,
    required String title,
    required String content,
    String? contactEmail,
    String? imagePath,
  }) async {
    final imageUrl = await _uploadImageIfNeeded(imagePath);

    await _collection.doc(id).update({
      'type': type,
      'title': title,
      'content': content,
      'contactEmail': contactEmail,
      'imageUrl': imageUrl,
    });
  }

  // 🌟 기존 delete 메서드를 대체하는 문의 취소 메서드
  Future<void> cancelInquiry(String id) async {
    await _collection.doc(id).update({
      'status': 'cancelled', // 상태값을 cancelled로 변경 (소프트 딜리트)
    });
  }

  /// 🌟 문의 종료 (답변 완료된 문의를 사용자가 종료 처리)
  Future<void> closeInquiry(String id) async {
    await _collection.doc(id).update({
      'status': 'closed',
    });
  }

}