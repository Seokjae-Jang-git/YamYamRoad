class UserData {
  // 자바의 static 변수처럼 선언하여 앱 어디서든 UserData.nickname 으로 접근 가능하게 합니다.
  static String uid = 'test_user_01';
  static String? nickname;
  static String? name;
  static String? phone;

  // 프로필 이미지가 기본 이미지인지, 사용자가 업로드한 앨범 이미지인지 구분하는 상태값
  static bool isDefaultProfileImage = true;

  static String? profileImagePath;
}