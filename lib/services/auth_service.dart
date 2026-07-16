import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/user_data.dart';

class AuthService {
  AuthService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
        'freePointBalance': 0,
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

    _currentUid = uid;
    _profileImageUrl = result.profileImageUrl;
    _syncUserData(result); // 🆕 UserData 동기화

    return result;
  }

  /// 🆕 현재 로그인 상태를 UserModel로 반환 (비로그인이면 null)
  /// 앱을 껐다 켜면 _currentUid가 초기화되므로 자동 로그인은 유지되지 않습니다.
  /// (자동 로그인이 필요하면 shared_preferences에 uid 저장 후 복원 로직 추가 필요)
  static Future<UserModel?> getCurrentUser() async {
    if (_currentUid == null) return null;

    final docRef = _firestore.collection('users').doc(_currentUid);
    final snapshot = await docRef.get();

    if (!snapshot.exists) return null;

    final data = snapshot.data() ?? {};
    final user = UserModel(
      uid: _currentUid!,
      isNewUser: false,
      provider: data['provider'] as String? ?? '',
      nickname: data['nickname'] as String?,
      profileImageUrl: data['profileImageUrl'] as String? ?? _profileImageUrl,
    );

    _syncUserData(user); // 🆕 앱 재진입 시에도 UserData 최신화
    return user;
  }

  /// 🆕 UserModel → UserData 정적 필드로 반영하는 헬퍼
  static void _syncUserData(UserModel user) {
    UserData.nickname = user.nickname ?? UserData.nickname;
    UserData.profileImagePath = user.profileImageUrl;
    UserData.isDefaultProfileImage = user.profileImageUrl == null;
  }

  static void logout() {
    _currentUid = null;
    _profileImageUrl = null;

    // 🆕 로그아웃 시 UserData 초기화
    UserData.nickname = '디저트킬러';
    UserData.profileImagePath = null;
    UserData.isDefaultProfileImage = true;
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