import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // 🌟 Clipboard 사용을 위해 필요

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
  late final TextEditingController _uidController; // 🌟 사용자 ID 표시용 컨트롤러 추가

  // 상태 관리 변수들
  late bool _isDefaultImage;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: UserData.nickname);
    _nameController = TextEditingController(text: UserData.name);
    _phoneController = TextEditingController(text: UserData.phone);
    // 🌟 사용자 ID 초기화 (값이 없을 경우 대비)
    _uidController = TextEditingController(text: UserData.uid ?? '알 수 없음');
    _isDefaultImage = UserData.isDefaultProfileImage;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _socialController.dispose();
    _uidController.dispose(); // 🌟 컨트롤러 해제 추가
    super.dispose();
  }

  // 앨범에서 사진을 고르는 비동기 함수
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
                _buildPopupButton('사진 앨범에서 선택', _pickImageFromGallery),
                const SizedBox(height: 16),
                _buildPopupButton('기본 이미지 사용', () {
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
                            return const Icon(Icons.person, size: 80, color: Colors.grey);
                          },
                        ),
                      )
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
              _buildInputField(
                '사용자 ID',
                _uidController,
                readOnly: true,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.copy, size: 18, color: Colors.grey),
                  onPressed: () {
                    // 클립보드에 사용자 ID 복사
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
              const SizedBox(height: 16),

              _buildInputField('이름', _nameController, readOnly: true),
              const SizedBox(height: 16),

              _buildInputField('닉네임', _nicknameController),
              const SizedBox(height: 16),

              _buildInputField(
                '휴대폰번호',
                _phoneController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  PhoneNumberFormatter(),
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
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(child: CircularProgressIndicator()),
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

                      // 🌟 이름(name) 필드는 더 이상 화면에서 수정되지 않으므로 업데이트 항목에서 제외하거나 기존 값을 그대로 넘깁니다.
                      await userDocRef.update({
                        'nickname': newNickname,
                        'phone': _phoneController.text,
                        'profileImageUrl': _isDefaultImage ? null : (downloadUrl ?? UserData.profileImagePath),
                      });

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
                          debugPrint('🔴 posts 동기화 실패: $e');
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
                          debugPrint('🔴 comments 동기화 실패: $e');
                          rethrow;
                        }
                      }

                      UserData.nickname = _nicknameController.text;
                      UserData.phone = _phoneController.text;
                      UserData.isDefaultProfileImage = _isDefaultImage;
                      if (_isDefaultImage) {
                        UserData.profileImagePath = null;
                      } else if (downloadUrl != null) {
                        UserData.profileImagePath = downloadUrl;
                      }

                      Navigator.pop(context);
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('정보가 성공적으로 저장되었습니다.')),
                      );

                    } catch (e) {
                      Navigator.pop(context);
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
        Widget? suffixIcon, // 🌟 아이콘을 받을 수 있도록 파라미터 추가
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
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textAlign: TextAlign.center,
            style: TextStyle(color: readOnly ? Colors.grey : Colors.black, fontSize: 14),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              suffixIcon: suffixIcon, // 🌟 우측 복사 아이콘 추가 반영
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.zero,
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