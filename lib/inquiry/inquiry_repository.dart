import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/auth_service.dart';
import 'inquiry.dart';

/// 문의 데이터를 관리하는 Repository (Firestore 연동).
/// 컬렉션명: inquiry (단수)
class InquiryRepository extends ChangeNotifier {
  InquiryRepository._internal() {
    // 🌟 앱 시작 시점의 로그인 상태로 최초 1회 구독
    _listenToFirestore();

    // 🌟 로그인/로그아웃/계정 전환이 일어날 때마다 자동으로 재구독합니다.
    //    (로그인 화면이나 로그아웃 로직에서 refreshSubscription()을
    //     따로 호출해줄 필요가 없어져서, 호출 누락으로 인한
    //     "이전 계정 문의가 계속 보이는" 버그를 방지합니다.)
    _authSub = AuthService.authStateChanges.listen((user) {
      final newUid = user?.uid;
      if (newUid == _lastUid) return; // 동일 유저면 재구독 불필요
      _lastUid = newUid;
      _listenToFirestore();
    });
  }

  static final InquiryRepository instance = InquiryRepository._internal();

  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('inquiry');

  List<Inquiry> _inquiries = [];
  List<Inquiry> get inquiries => List.unmodifiable(_inquiries);

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  StreamSubscription<dynamic>? _authSub;
  String? _lastUid;

  void _listenToFirestore() {
    final uid = AuthService.currentUser?.uid;
    _lastUid = uid;

    // 🌟 이전 유저(또는 이전 세션)의 구독을 반드시 먼저 해제합니다.
    //    해제하지 않으면 계정을 전환했을 때 이전 구독의 콜백이 뒤늦게
    //    도착해 새 유저의 목록을 덮어써버리는 경합 상태가 생길 수 있습니다.
    _sub?.cancel();

    if (uid == null) {
      _inquiries = [];
      notifyListeners();
      return;
    }

    _sub = _collection
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final List<Inquiry> parsed = [];

      // 🌟 문서 하나가 파싱 실패해도 나머지는 정상 반영되도록 개별 try-catch 처리
      for (final doc in snapshot.docs) {
        try {
          parsed.add(Inquiry.fromDoc(doc));
        } catch (e) {
          debugPrint('🔴 [InquiryRepository] 문서 파싱 실패 (id=${doc.id}): $e');
          debugPrint('🔴 문제 데이터: ${doc.data()}');
        }
      }

      _inquiries = parsed;
      debugPrint('🟢 [InquiryRepository] 목록 갱신됨. 총 ${_inquiries.length}건 (uid=$uid)');
      notifyListeners();
    }, onError: (e, stackTrace) {
      debugPrint('🔴 [InquiryRepository] 구독 자체 실패: $e');
    });
  }

  /// 로그아웃/로그인으로 유저가 바뀌었을 때 수동으로 다시 구독하고 싶을 때
  /// 호출할 수 있습니다. (authStateChanges 리스너가 이미 자동으로 처리하므로
  /// 보통은 호출할 필요가 없지만, 예외적인 상황을 위해 남겨둡니다.)
  void refreshSubscription() {
    _listenToFirestore();
  }

  Future<String?> _uploadImageIfNeeded(String? imagePath) async {
    if (imagePath == null) return null;
    if (imagePath.startsWith('http')) return imagePath; // 이미 업로드된 URL(수정 시 유지)

    final uid = AuthService.currentUser?.uid ?? 'unknown';
    final fileName = '${DateTime.now().microsecondsSinceEpoch}.jpg';
    final ref = _storage.ref('inquiry_images/$uid/$fileName');

    await ref.putFile(File(imagePath));
    return await ref.getDownloadURL();
  }

  /// 문의 등록. 생성된 Inquiry를 반환한다.
  Future<Inquiry> add({
    required InquiryType type,
    required String title,
    required String content,
    String? contactEmail,
    String? imagePath,
  }) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) {
      throw StateError('로그인이 필요합니다.');
    }

    final imageUrl = await _uploadImageIfNeeded(imagePath);

    final docRef = await _collection.add({
      'userId': uid,
      'type': type.name,
      'title': title,
      'content': content,
      'contactEmail': contactEmail,
      'imageUrl': imageUrl,
      'status': InquiryStatus.pending.name,
      'adminMemo': null,
      'createdAt': FieldValue.serverTimestamp(),
      'answeredAt': null,
    });

    // 🌟 서버 타임스탬프는 즉시 값을 알 수 없어 클라이언트 시각으로 임시 표시합니다.
    //    (실시간 구독이 곧이어 서버 값으로 목록을 갱신합니다.)
    return Inquiry(
      id: docRef.id,
      userId: uid,
      type: type,
      title: title,
      content: content,
      contactEmail: contactEmail,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
      status: InquiryStatus.pending,
    );
  }

  /// 문의 수정 (제목/내용/이메일/유형/이미지만 수정 가능)
  Future<void> update({
    required String id,
    required InquiryType type,
    required String title,
    required String content,
    String? contactEmail,
    String? imagePath,
  }) async {
    final imageUrl = await _uploadImageIfNeeded(imagePath);

    await _collection.doc(id).update({
      'type': type.name,
      'title': title,
      'content': content,
      'contactEmail': contactEmail,
      'imageUrl': imageUrl,
    });
  }

  /// 문의 삭제
  Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }

  Inquiry? findById(String id) {
    try {
      return _inquiries.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}