import 'dart:io';
import 'package:image_picker/image_picker.dart';
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
  // 공통 색상 팔레트
  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color creamyIvory = Color(0xFFFFFDF9);
  static const Color subTextColor = Color(0xFF7A6B63);

  // 텍스트 필드 컨트롤러
  late final TextEditingController _nicknameController;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _socialController;
  late final TextEditingController _uidController;

  // 상태 관리 변수
  late bool _isDefaultImage;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: UserData.nickname);
    _nameController = TextEditingController(text: UserData.name);
    _phoneController = TextEditingController(text: UserData.phone);
    _socialController = TextEditingController(text: UserData.provider);
    _uidController = TextEditingController(text: UserData.uid ?? '알 수 없음');
    _isDefaultImage = UserData.isDefaultProfileImage;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _socialController.dispose();
    _uidController.dispose();
    super.dispose();
  }

  // 앨범에서 사진 선택
  Future<void> _pickImageFromGallery() async {
    Navigator.pop(context);
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _isDefaultImage = false;
      });
    }
  }

  // 프로필 이미지 수정 팝업
  void _showImageEditPopup() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: creamyIvory,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('프로필 사진 변경', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: deepChocolate)),
                const SizedBox(height: 24),
                _buildPopupButton('사진 앨범에서 선택', Icons.photo_library, _pickImageFromGallery),
                const SizedBox(height: 12),
                _buildPopupButton('기본 이미지 사용', Icons.account_circle, () {
                  setState(() {
                    _isDefaultImage = true;
                    _selectedImage = null;
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

  Widget _buildPopupButton(String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: deepChocolate, size: 20),
        label: Text(text, style: const TextStyle(color: deepChocolate, fontSize: 15, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: Colors.white,
          side: BorderSide(color: deepChocolate.withOpacity(0.15)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 1. 이름 수정 가능 여부 체크 (카카오 또는 네이버일 경우 true)
    final bool isNameEditable = (UserData.uid != null &&
        (UserData.uid!.startsWith('kakao:') || UserData.uid!.startsWith('naver:'))) ||
        UserData.provider == 'kakao' ||
        UserData.provider == 'naver';

    return Scaffold(
      backgroundColor: creamyIvory,
      appBar: AppBar(
        title: const Text(
          '내 정보 수정',
          style: TextStyle(color: deepChocolate, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: creamyIvory,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: deepChocolate, size: 28),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 프로필 이미지 영역
              Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: deepChocolate.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                        child: _selectedImage != null
                            ? ClipOval(
                          child: Image.file(
                            _selectedImage!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        )
                            : (!_isDefaultImage && UserData.profileImagePath != null)
                            ? ClipOval(
                          child: Image.network(
                            UserData.profileImagePath!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.person, size: 60, color: Colors.grey.shade400);
                            },
                          ),
                        )
                            : Icon(Icons.person, size: 60, color: Colors.grey.shade400),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showImageEditPopup,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: deepChocolate,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // 2. 입력 폼 영역
              _buildInputField(
                '사용자 ID',
                _uidController,
                readOnly: true,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.copy, size: 20, color: subTextColor),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _uidController.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('사용자 ID가 복사되었습니다.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),

              // 🌟 2. 이름 수정 불가능한 상태(구글 등)일 때만 읽기 전용으로 설정
              _buildInputField('이름', _nameController, readOnly: !isNameEditable),

              _buildInputField('닉네임', _nicknameController),

              _buildInputField(
                '휴대폰번호',
                _phoneController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  PhoneNumberFormatter(),
                ],
              ),

              _buildInputField('소셜로그인', _socialController, readOnly: true),

              const SizedBox(height: 32),

              // 3. 저장 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(child: CircularProgressIndicator(color: deepChocolate)),
                    );

                    String? downloadUrl;

                    try {
                      if (_selectedImage != null) {
                        String fileName = 'profile_${UserData.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

                        downloadUrl = await StorageService.uploadImage(
                          imageFile: _selectedImage!,
                          folderName: 'profile_img',
                          fileName: fileName,
                        );
                      }

                      final userDocRef = FirebaseFirestore.instance.collection('users').doc(UserData.uid);

                      final String newNickname = _nicknameController.text;
                      final bool nicknameChanged = newNickname != UserData.nickname;

                      // 🌟 3-1. updateData 맵을 명시적 타입과 함께 올바르게 선언
                      final Map<String, dynamic> updateData = {
                        'nickname': newNickname,
                        'phone': _phoneController.text,
                        'profileImageUrl': _isDefaultImage ? null : (downloadUrl ?? UserData.profileImagePath),
                      };

                      // 🌟 3-2. 카카오나 네이버 로그인일 경우 사용자가 입력한 '이름'도 업데이트 목록에 추가
                      if (isNameEditable) {
                        updateData['name'] = _nameController.text;
                      }

                      // Firestore 문서 업데이트 실행
                      await userDocRef.update(updateData);

                      // 닉네임 변경 시 연관 데이터 업데이트
                      if (nicknameChanged) {
                        try {
                          final postsSnapshot = await FirebaseFirestore.instance
                              .collection('posts')
                              .where('userId', isEqualTo: UserData.uid)
                              .get();

                          if (postsSnapshot.docs.isNotEmpty) {
                            const chunkSize = 500;
                            final docs = postsSnapshot.docs;
                            for (var i = 0; i < docs.length; i += chunkSize) {
                              final batch = FirebaseFirestore.instance.batch();
                              final end = (i + chunkSize < docs.length) ? i + chunkSize : docs.length;
                              for (final doc in docs.sublist(i, end)) {
                                batch.update(doc.reference, {'nickname': newNickname});
                              }
                              await batch.commit();
                            }
                          }
                        } catch (e) {
                          debugPrint('posts 동기화 실패: $e');
                          rethrow;
                        }

                        try {
                          final commentsSnapshot = await FirebaseFirestore.instance
                              .collectionGroup('comments')
                              .where('userId', isEqualTo: UserData.uid)
                              .get();

                          if (commentsSnapshot.docs.isNotEmpty) {
                            const chunkSize = 500;
                            final commentDocs = commentsSnapshot.docs;
                            for (var i = 0; i < commentDocs.length; i += chunkSize) {
                              final batch = FirebaseFirestore.instance.batch();
                              final end = (i + chunkSize < commentDocs.length) ? i + chunkSize : commentDocs.length;
                              for (final doc in commentDocs.sublist(i, end)) {
                                batch.update(doc.reference, {'nickname': newNickname});
                              }
                              await batch.commit();
                            }
                          }
                        } catch (e) {
                          debugPrint('comments 동기화 실패: $e');
                          rethrow;
                        }
                      }

                      UserData.nickname = _nicknameController.text;
                      UserData.phone = _phoneController.text;

                      // 🌟 3-3. 로컬 UserData에도 이름 반영
                      if (isNameEditable) {
                        UserData.name = _nameController.text;
                      }

                      UserData.isDefaultProfileImage = _isDefaultImage;
                      if (_isDefaultImage) {
                        UserData.profileImagePath = null;
                      } else if (downloadUrl != null) {
                        UserData.profileImagePath = downloadUrl;
                      }

                      Navigator.pop(context); // 로딩 닫기
                      Navigator.pop(context); // 화면 닫기

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('정보가 성공적으로 저장되었습니다.')),
                      );

                    } catch (e) {
                      Navigator.pop(context);
                      debugPrint("DB 및 스토리지 저장 오류: $e");
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('저장 실패: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deepChocolate,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('저장', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 폼 입력 필드 (위-아래 레이아웃으로 변경하여 디자인 개선)
  Widget _buildInputField(
      String label,
      TextEditingController controller, {
        bool readOnly = false,
        TextInputType? keyboardType,
        List<TextInputFormatter>? inputFormatters,
        Widget? suffixIcon,
      }
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: subTextColor)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: TextStyle(
                color: readOnly ? subTextColor : deepChocolate,
                fontSize: 15,
                fontWeight: FontWeight.w500
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: suffixIcon,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: deepChocolate.withOpacity(0.15)),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: deepChocolate, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: readOnly ? deepChocolate.withOpacity(0.04) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// 전화번호 자동 포맷터
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    text = text.replaceAll(RegExp(r'\D'), '');

    if (text.length > 11) {
      text = text.substring(0, 11);
    }

    var buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;

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