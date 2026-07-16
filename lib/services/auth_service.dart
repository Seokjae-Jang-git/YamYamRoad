import 'package:cloud_firestore/cloud_firestore.dart';

/// Spark(무료) 요금제용 인증 서비스.
///
/// Firebase Auth 세션을 만들지 않고, Firestore의 users 컬렉션에
/// `{provider}_{socialId}` 형태의 uid로 문서를 직접 저장/조회합니다.
///
/// ⚠️ Firebase Auth가 없으므로 Firestore 보안 규칙에서 request.auth를
///    사용할 수 없습니다. 개발/포트폴리오 단계에서만 이 방식을 쓰고,
///    실서비스 전환 시 Cloud Functions + Custom Token 방식으로
///    바꾸는 것을 권장합니다.
///
/// [pubspec.yaml]에 필요한 패키지:
///   firebase_core: ^4.11.0
///   cloud_firestore: ^6.6.0
class AuthService {
  AuthService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 현재 로그인한 uid를 앱 메모리에 들고 있음 (로그아웃 시 초기화)
  /// 앱을 재시작하면 사라지므로, 자동 로그인이 필요하면
  /// shared_preferences 등에 uid를 별도로 저장해서 앱 시작 시 복원하세요.
  static String? _currentUid;
  static String? _profileImageUrl;

  static bool get isLoggedIn => _currentUid != null;
  static String? get currentUid => _currentUid;
  static String? get profileImageUrl => _profileImageUrl;

  /// 카카오 로그인
  static Future<UserModel> loginWithKakao({
    required String socialId,
    String? nickname,
    String? profileImageUrl,
  }) {
    return _loginWithProvider(
      provider: 'kakao',
      socialId: socialId,
      nickname: nickname,
      profileImageUrl: profileImageUrl,
    );
  }

  /// 네이버 로그인
  static Future<UserModel> loginWithNaver({
    required String socialId,
    String? name,
    String? nickname,
    String? phone,
    String? profileImageUrl,
  }) {
    return _loginWithProvider(
      provider: 'naver',
      socialId: socialId,
      name: name,
      nickname: nickname,
      phone: phone,
      profileImageUrl: profileImageUrl,
    );
  }

  /// 구글 로그인
  static Future<UserModel> loginWithGoogle({
    required String socialId,
    String? name,
    String? profileImageUrl,
  }) {
    return _loginWithProvider(
      provider: 'google',
      socialId: socialId,
      name: name,
      nickname: name,
      profileImageUrl: profileImageUrl,
    );
  }

  static Future<UserModel> _loginWithProvider({
    required String provider,
    required String socialId,
    String? name,
    String? nickname,
    String? phone,
    String? profileImageUrl,
  }) async {
    final uid = '${provider}_$socialId';
    final docRef = _firestore.collection('users').doc(uid);
    final snapshot = await docRef.get();

    UserModel result;

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
      result = UserModel(
        uid: uid,
        isNewUser: true,
        provider: provider,
        nickname: nickname,
        profileImageUrl: profileImageUrl,
      );
    } else {
      await docRef.update({
        'updatedAt': FieldValue.serverTimestamp(),
        if (nickname != null) 'nickname': nickname,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      });
      final data = snapshot.data() ?? {};
      result = UserModel(
        uid: uid,
        isNewUser: false,
        provider: provider,
        nickname: nickname ?? data['nickname'] as String?,
        profileImageUrl: profileImageUrl ?? data['profileImageUrl'] as String?,
      );
    }

    _currentUid = uid; // 로그인 상태를 메모리에 저장
    _profileImageUrl = result.profileImageUrl; // ← 추가: 프로필 이미지도 같이 저장
    return result;
  }

  static void logout() {
    _currentUid = null;
    _profileImageUrl = null; // ← 추가
  }
}

class UserModel {
  final String uid;
  final bool isNewUser;
  final String provider;
  final String? nickname;
  final String? profileImageUrl;

  UserModel({
    required this.uid,
    required this.isNewUser,
    required this.provider,
    this.nickname,
    this.profileImageUrl,
  });
}