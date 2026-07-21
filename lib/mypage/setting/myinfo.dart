import 'dart:io'; // 🌟 File 객체를 사용하기 위한 임포트
import 'package:image_picker/image_picker.dart'; // 🌟 앨범 접근용 패키지 임포트
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import '../../common/storage_service.dart';
import '../../common/user_data.dart';


class MyInfoScreen extends StatefulWidget {
  const MyInfoScreen({super.key});

  @override
  State<MyInfoScreen> createState() => _MyInfoScreenState();
}

class _MyInfoScreenState extends State<MyInfoScreen> {
  // 텍스트 필드 컨트롤러
  late final TextEditingController _nicknameController;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  final TextEditingController _socialController = TextEditingController(text: 'Google');

  // 상태 관리 변수들
  late bool _isDefaultImage;
  File? _selectedImage; // 🌟 갤러리에서 선택한 사진 파일을 담을 변수
  final ImagePicker _picker = ImagePicker(); // 🌟 이미지 픽커 도구

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: UserData.nickname);
    _nameController = TextEditingController(text: UserData.name);
    _phoneController = TextEditingController(text: UserData.phone);
    _isDefaultImage = UserData.isDefaultProfileImage;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _socialController.dispose();
    super.dispose();
  }

  // 🌟 앨범에서 사진을 고르는 비동기 함수
  Future<void> _pickImageFromGallery() async {
    // 1. 열려있는 팝업창(Dialog)을 먼저 닫습니다.
    Navigator.pop(context);

    // 2. 갤러리를 띄워서 사용자가 사진을 고를 때까지 기다립니다.
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    // 3. 사진을 정상적으로 골랐다면 화면 상태를 업데이트합니다.
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _isDefaultImage = false; // 기본 이미지 상태 해제
      });
    }
  }

  // 프로필 이미지 수정 팝업 띄우기
  void _showImageEditPopup() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🌟 버튼 클릭 시 사진 고르기 함수 연결
                _buildPopupButton('사진 앨범에서 선택', _pickImageFromGallery),
                const SizedBox(height: 16),
                _buildPopupButton('기본 이미지 사용', () {
                  setState(() {
                    _isDefaultImage = true;
                    _selectedImage = null; // 기본 이미지로 돌아가면 선택된 이미지도 초기화
                  });
                  Navigator.pop(dialogContext);
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPopupButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.grey),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        ),
        child: Text(text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '내 정보 수정',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // 1. 프로필 이미지 영역
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: const Color(0xFFF5F5F5),
                      child: _selectedImage != null
                      // 1. 사용자가 방금 갤러리에서 새로운 사진을 선택한 경우 (로컬 파일 표시)
                          ? ClipOval(
                        child: Image.file(
                          _selectedImage!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      )
                      // 2. 새로운 사진은 안 골랐지만, 기존에 저장된 클라우드 프로필 이미지(URL)가 있는 경우 (인터넷 이미지 표시)
                          : (!_isDefaultImage && UserData.profileImagePath != null)
                          ? ClipOval(
                        child: Image.network(
                          UserData.profileImagePath!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.person, size: 80, color: Colors.grey);
                          },
                        ),
                      )
                      // 3. 기본 이미지 상태이거나 프로필 이미지가 없는 경우 (기본 아이콘 표시)
                          : const Icon(Icons.person, size: 80, color: Colors.grey),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showImageEditPopup,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: const Text('수정', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // 2. 입력 폼 영역
              _buildInputField('닉네임', _nicknameController),
              const SizedBox(height: 16),
              _buildInputField('이름', _nameController),
              const SizedBox(height: 16),
              _buildInputField(
                '휴대폰번호',
                _phoneController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  PhoneNumberFormatter(), // 파일 맨 아래에 추가했던 클래스
                ],
              ),
              const SizedBox(height: 16),
              _buildInputField('소셜로그인', _socialController, readOnly: true),

              const SizedBox(height: 40),

              // 3. 저장 버튼
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    // 1) 화면에 로딩 인디케이터(빙글빙글 도는 창)를 띄워 유저의 중복 클릭을 막습니다.
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(child: CircularProgressIndicator()),
                    );

                    String? downloadUrl;

                    try {
                      // 2) 만약 사용자가 사진을 새로 선택했다면, 먼저 Firebase Storage에 업로드합니다.
                      if (_selectedImage != null) {
                        // 파일명이 겹치지 않게 타임스탬프를 붙여 고유하게 만들어 줍니다.
                        // 🌟 파일명에도 현재 접속 중인 유저의 UID가 동적으로 들어가도록 수정합니다.
                        String fileName = 'profile_${UserData.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

                        // 아까 만들어둔 공통 스토리지 서비스 호출 (profile_img 폴더로 분류)
                        downloadUrl = await StorageService.uploadImage(
                          imageFile: _selectedImage!,
                          folderName: 'profile_img',
                          fileName: fileName,
                        );
                      }

                      final userDocRef = FirebaseFirestore.instance.collection('users').doc(UserData.uid);

                      await userDocRef.update({
                        'nickname': _nicknameController.text,
                        'name': _nameController.text, // 만약 users 정의서 필드에 name이 없다면 생략 가능합니다.
                        'phone': _phoneController.text, // 정의서 필드 구조에 맞춰서 조율 가능합니다.
                        // 🌟 이미지가 새로 업로드되어 URL이 생성되었다면 DB에 저장하고, 기본 이미지로 돌렸다면 null을 꽂아줍니다.
                        'profileImageUrl': _isDefaultImage ? null : (downloadUrl ?? UserData.profileImagePath),
                      });

                      // 4) 로컬 전역 변수(UserData)도 현재 수정한 값으로 동기화합니다.
                      UserData.nickname = _nicknameController.text;
                      UserData.name = _nameController.text;
                      UserData.phone = _phoneController.text;
                      UserData.isDefaultProfileImage = _isDefaultImage;
                      if (_isDefaultImage) {
                        UserData.profileImagePath = null;
                      } else if (downloadUrl != null) {
                        UserData.profileImagePath = downloadUrl; // 로컬 경로 대신 스토리지 웹 URL을 저장!
                      }

                      // 5) 정상적으로 처리가 완료되면 로딩 창을 닫고 이전 화면(마이페이지 메인)으로 돌아갑니다.
                      Navigator.pop(context); // 로딩 다이얼로그 닫기
                      Navigator.pop(context); // 내 정보 수정 화면 닫기

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('정보가 클라우드에 성공적으로 저장되었습니다.')),
                      );

                    } catch (e) {
                      Navigator.pop(context); // 에러 발생 시 로딩 다이얼로그는 닫아줍니다.
                      print("DB 및 스토리지 저장 오류: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('저장 실패: $e')),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                  ),
                  child: const Text('저장'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 폼 입력 필드 생성 헬퍼 위젯
  Widget _buildInputField(
      String label,
      TextEditingController controller, {
        bool readOnly = false,
        TextInputType? keyboardType,
        List<TextInputFormatter>? inputFormatters,
      }
      ) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            readOnly: readOnly,

            // 🌟 추가된 부분: 위에서 전달받은 키보드 타입과 포맷터를 TextField에 연결!
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,

            textAlign: TextAlign.center,
            style: TextStyle(color: readOnly ? Colors.grey : Colors.black, fontSize: 14),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.zero, // 깔끔한 플랫 디자인
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
                borderRadius: BorderRadius.zero,
              ),
              filled: readOnly,
              fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;

    // 1. 숫자만 남기고 나머지 기호(기존 하이픈 등)는 전부 제거합니다.
    text = text.replaceAll(RegExp(r'\D'), '');

    // 2. 최대 11자리(01012345678)까지만 입력되도록 제한합니다.
    if (text.length > 11) {
      text = text.substring(0, 11);
    }

    var buffer = StringBuffer();

    // 3. 숫자 길이에 따라 자동으로 하이픈을 결합합니다.
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;

      // 010-xxxx-xxxx 패턴 대응
      if (nonZeroIndex == 3 && text.length > 3) {
        buffer.write('-');
      } else if (nonZeroIndex == 7 && text.length > 7) {
        buffer.write('-');
      }
    }

    var string = buffer.toString();

    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}