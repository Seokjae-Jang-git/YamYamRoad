import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../common/user_data.dart';
import '../noti/logic/noti_device_service.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions =
  FirebaseFunctions.instanceFor(region: 'asia-northeast3');

  /// 현재 로그인 여부 - Firebase Auth 세션 기준 (재시작해도 유지됨)
  static bool get isLoggedIn => _auth.currentUser != null;

  /// 현재 로그인한 Firebase User (없으면 null)
  static User? get currentUser => _auth.currentUser;

  /// 로그인 상태 변화를 실시간으로 감지하는 스트림.
  /// main.dart에서 앱 시작 화면(홈/스플래시)을 분기할 때 사용하세요.
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 현재 로그인된 사용자의 Firestore 프로필 정보를 조회하여 UserData 전역 객체에 저장합니다.
  static Future<void> loadUserProfileToUserData() async {
    final String? currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return;

    // 이미 유저 데이터가 올바르게 세팅되어 있는 경우 불필요한 Firestore 조회 방지
    if (UserData.uid == currentUid && UserData.nickname != null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(currentUid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        UserData.uid = currentUid;
        UserData.nickname = data['nickname'] as String? ?? '이름없음';
        UserData.name = data['name'] as String? ?? '';
        UserData.phone = data['phone'] as String? ?? '';
        UserData.provider = data['provider'] as String? ?? '';
        UserData.profileImagePath = data['profileImageUrl'] as String?;
        UserData.isDefaultProfileImage =
        (data['profileImageUrl'] == null || data['profileImageUrl'].toString().isEmpty);
      }
    } catch (e) {
      // ignore: avoid_print
      print('🔴 프로필 데이터 로드 실패: $e');
    }
  }

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
      print('🔴 신규 유저 서브컬렉션 초기화 실패 (uid=$uid): $e');
    }
  }

  /// 로그아웃 및 전역 UserData 초기화
  static Future<void> logout() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      try {
        await NotiDeviceService().unregisterCurrentDevice(uid);
      } catch (error) {
        debugPrint('FCM 기기 해제 실패: $error');
      }
    }
    await _auth.signOut();

    // 전역 유저 메모리 데이터 즉시 초기화
    UserData.uid = null;
    UserData.nickname = null;
    UserData.name = null;
    UserData.phone = null;
    UserData.profileImagePath = null;
    UserData.isDefaultProfileImage = true;
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