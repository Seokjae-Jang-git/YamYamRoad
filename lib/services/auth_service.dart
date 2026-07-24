import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Blaze 요금제 기반 인증 서비스.
///
/// - 구글: firebase_auth의 GoogleAuthProvider로 직접 로그인 (Cloud Function 불필요)
/// - 카카오/네이버: Cloud Function(socialLogin, onCall)에서 토큰 검증 후
///   Custom Token을 받아 signInWithCustomToken으로 Firebase Auth 로그인
///
/// 카카오/네이버 모두 동일하게 FirebaseFunctions.httpsCallable로 호출합니다.
/// (onCall 콜러블 함수는 반드시 이 방식으로 호출해야 요청/응답 포맷이 맞습니다.
///  raw http.post로 직접 호출하면 안 됩니다.)
///
/// Firebase Auth 세션은 기기에 자동으로 안전하게 저장되므로,
/// 앱을 껐다 켜도 FirebaseAuth.instance.currentUser로 로그인 상태가 그대로 유지됩니다.
/// (별도의 로컬 저장 로직이 필요 없습니다.)

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // socialLogin 함수가 asia-northeast3(서울) 리전에 배포되어 있으므로
  // 반드시 instanceFor로 리전을 명시해야 합니다. instance만 쓰면
  // 기본값인 us-central1을 호출해서 NOT_FOUND 에러가 납니다.
  static final FirebaseFunctions _functions =
  FirebaseFunctions.instanceFor(region: 'asia-northeast3');

  /// 현재 로그인 여부 - Firebase Auth 세션 기준 (재시작해도 유지됨)
  static bool get isLoggedIn => _auth.currentUser != null;

  /// 현재 로그인한 Firebase User (없으면 null)
  static User? get currentUser => _auth.currentUser;

  /// 로그인 상태 변화를 실시간으로 감지하는 스트림.
  /// main.dart에서 앱 시작 화면(홈/스플래시)을 분기할 때 사용하세요.
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 현재 로그인한 사용자의 Firestore 프로필까지 포함한 정보를 가져옵니다.
  /// 비로그인 상태면 null을 반환합니다.
  /// (main_home_screen, home_content_view 등에서 닉네임/프로필 이미지 표시할 때 사용)
  static Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
    final data = doc.data() ?? {};

    return UserModel(
      uid: firebaseUser.uid,
      isNewUser: false,
      provider: data['provider'] as String? ?? '',
      nickname: data['nickname'] as String? ?? firebaseUser.displayName,
      profileImageUrl: data['profileImageUrl'] as String? ?? firebaseUser.photoURL,
      isWithdrawn: data['status'] == 'withdrawn',
      withdrawnAt: (data['withdrawnAt'] as Timestamp?)?.toDate(),
    );
  }

  /// 카카오 로그인 (kakao_flutter_sdk의 OAuthToken.accessToken을 전달)
  static Future<UserModel> loginWithKakao(String accessToken) {
    return _loginViaCloudFunction(provider: 'kakao', accessToken: accessToken);
  }

  /// 네이버 로그인 (flutter_naver_login의 accessToken을 전달)
  static Future<UserModel> loginWithNaver(String accessToken) {
    return _loginViaCloudFunction(provider: 'naver', accessToken: accessToken);
  }

  /// 구글 로그인 - Firebase Auth가 기본 지원하므로 Cloud Function 불필요
  static Future<UserModel> loginWithGoogle({
    required String? idToken,
    String? accessToken,
  }) async {
    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: accessToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final firebaseUser = userCredential.user;
    if (firebaseUser == null) {
      throw AuthException('구글 로그인에 실패했습니다.');
    }

    return _upsertUserDoc(
      uid: firebaseUser.uid,
      provider: 'google',
      name: firebaseUser.displayName,
      nickname: firebaseUser.displayName,
      profileImageUrl: firebaseUser.photoURL,
      phone: firebaseUser.phoneNumber,
    );
  }

  /// 카카오/네이버 공통: Cloud Function(onCall) 호출 → Custom Token 로그인
  /// → Firestore 문서 upsert
  ///
  /// Cloud Function(socialLogin)은 { customToken, profile } 형태로
  /// 응답해야 합니다. profile은 { name, nickname, profileImageUrl, phone }
  /// 형태의 Map(없는 값은 생략 가능)입니다.
  static Future<UserModel> _loginViaCloudFunction({
    required String provider,
    required String accessToken,
  }) async {
    final callable = _functions.httpsCallable('socialLogin');

    late final HttpsCallableResult result;
    try {
      result = await callable.call(<String, dynamic>{
        'provider': provider,
        'accessToken': accessToken,
      });
    } on FirebaseFunctionsException catch (e) {
      throw AuthException('로그인 실패: ${e.message ?? e.code}');
    } catch (e) {
      throw AuthException('서버 연결에 실패했습니다: $e');
    }

    final data = Map<String, dynamic>.from(result.data as Map);
    final customToken = data['customToken'] as String?;
    if (customToken == null) {
      throw AuthException('서버 응답에 토큰이 없습니다.');
    }

    final userCredential = await _auth.signInWithCustomToken(customToken);
    final firebaseUser = userCredential.user;
    if (firebaseUser == null) {
      throw AuthException('Firebase 로그인에 실패했습니다.');
    }

    final profile = (data['profile'] as Map?)?.cast<String, dynamic>() ?? {};

    return _upsertUserDoc(
      uid: firebaseUser.uid,
      provider: provider,
      name: profile['name'] as String?,
      nickname: profile['nickname'] as String?,
      profileImageUrl: profile['profileImageUrl'] as String?,
      phone: profile['phone'] as String?,
    );
  }

  /// Firestore users/{uid} 문서가 없으면 새로 생성, 있으면 최신 프로필로 갱신
  ///
  /// 🌟 기존 유저가 탈퇴(status == 'withdrawn') 상태여도 여기서는 강제로
  /// 되돌리지 않습니다. 대신 UserModel에 isWithdrawn/withdrawnAt을 실어
  /// 반환하니, 화면(login_screen 등)에서 복구 팝업을 띄우고
  /// handleWithdrawnRecovery()로 실제 복구 처리를 하도록 합니다.
  static Future<UserModel> _upsertUserDoc({
    required String uid,
    required String provider,
    String? name,
    String? nickname,
    String? profileImageUrl,
    String? phone,
  }) async {
    final docRef = _firestore.collection('users').doc(uid);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      final newUser = {
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'freePointBalance': 0, // TODO: 가입 축하 포인트 정책이 있다면 조정
        'paidPointBalance': 0,
        'lastLocation': null,
        'name': name,
        'nickname': nickname,
        'phone': phone,
        'profileImageUrl': profileImageUrl,
        'provider': provider,
        'selectedBadgeIds': null,
        'status': 'active',
        'withdrawnAt': null,
      };
      await docRef.set(newUser);

      // 🌟 가입 직후 서브컬렉션 초기화
      // (users_badge/users_purchase는 실제 뱃지 획득·구매가 일어나기 전까지는
      //  Firestore 특성상 문서가 없으면 컬렉션 자체가 보이지 않아 자연스러운 상태입니다.
      //  여기서는 "가입 시점에 실제로 발생하는 이벤트"인 환영 알림과
      //  포인트 잔액 0원 개설 내역만 심어둡니다.)
      await _seedNewUserSubcollections(uid: uid, nickname: nickname);

      return UserModel(
        uid: uid,
        isNewUser: true,
        provider: provider,
        nickname: nickname,
        profileImageUrl: profileImageUrl,
        isWithdrawn: false,
        withdrawnAt: null,
      );
    } else {
      final data = snapshot.data() ?? {};
      final bool isWithdrawn = data['status'] == 'withdrawn';

      await docRef.update({
        'updatedAt': FieldValue.serverTimestamp(),
        if (nickname != null) 'nickname': nickname,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      });

      return UserModel(
        uid: uid,
        isNewUser: false,
        provider: provider,
        nickname: nickname ?? data['nickname'] as String?,
        profileImageUrl: profileImageUrl ?? data['profileImageUrl'] as String?,
        isWithdrawn: isWithdrawn,
        withdrawnAt: (data['withdrawnAt'] as Timestamp?)?.toDate(),
      );
    }
  }

  /// 🌟 신규 유저 가입 직후 서브컬렉션 초기 데이터 생성
  /// - users_notification: 환영 알림 1건
  /// - users_point_transaction: 포인트 잔액 0원으로 개설되었다는 내역 1건
  ///
  /// users_badge / users_purchase는 실제 획득·구매 이벤트가 있을 때
  /// (BadgeService.checkAndGrantBadges, 포인트 구매 로직 등에서) 자연스럽게
  /// 첫 문서가 생기면서 컬렉션이 생성되므로 여기서는 건드리지 않습니다.
  static Future<void> _seedNewUserSubcollections({
    required String uid,
    String? nickname,
  }) async {
    final userRef = _firestore.collection('users').doc(uid);
    final batch = _firestore.batch();

    final notificationRef = userRef.collection('users_notification').doc();
    batch.set(notificationRef, {
      'type': 'welcome',
      'title': '얌얌로드에 오신 걸 환영해요!',
      'message': '${nickname ?? '회원'}님, 가입을 축하드려요. 첫 스탬프를 찍고 뱃지를 모아보세요 🎉',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final pointTransactionRef = userRef.collection('users_point_transaction').doc();
    batch.set(pointTransactionRef, {
      'type': 'signup',
      'amount': 0,
      'balanceAfter': 0,
      'description': '회원가입으로 포인트 계정이 개설되었습니다.',
      'createdAt': FieldValue.serverTimestamp(),
    });

    try {
      await batch.commit();
    } catch (e) {
      // 서브컬렉션 초기화 실패는 가입 자체를 막을 이유가 아니므로 로그만 남깁니다.
      // (users 문서는 이미 생성된 상태)
      // ignore: avoid_print
      print('🔴 신규 유저 서브컬렉션 초기화 실패 (uid=$uid): $e');
    }
  }

  /// 로그아웃
  static Future<void> logout() async {
    await _auth.signOut();
  }
}

/// 로그인 성공 시 반환되는 사용자 정보
class UserModel {
  final String uid;
  final bool isNewUser;
  final String provider;
  final String? nickname;
  final String? profileImageUrl;
  final bool isWithdrawn;
  final DateTime? withdrawnAt;

  UserModel({
    required this.uid,
    required this.isNewUser,
    required this.provider,
    this.nickname,
    this.profileImageUrl,
    this.isWithdrawn = false,
    this.withdrawnAt,
  });
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}