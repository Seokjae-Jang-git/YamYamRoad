class UserData {
  // 🌟 [수정] 하드코딩된 'test_user_01'을 완전히 지우고 String? (nullable)로 변경합니다.
  // 앱이 처음 켜졌을 때는 아무것도 없는 null 상태가 됩니다.
  static String? uid;

  static String? nickname;
  static String? name;
  static String? phone;

  // 프로필 이미지가 기본 이미지인지 구분하는 상태값
  static bool isDefaultProfileImage = true;

  static String? profileImagePath;

  // 💡 [추가하면 좋은 꿀팁] 로그아웃 시 전역 데이터를 깨끗이 비워주는 함수
  static void clear() {
    uid = null;
    nickname = null;
    name = null;
    phone = null;
    isDefaultProfileImage = true;
    profileImagePath = null;
  }
}