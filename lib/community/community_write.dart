import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../common/user_data.dart';
import '../../services/auth_service.dart';
import 'community_post.dart';

// 🌟 새 글 작성 + 기존 글 수정을 모두 담당하는 화면
// existingPost 가 넘어오면 '수정 모드'로 동작합니다.
class CommunityWriteScreen extends StatefulWidget {
  final CommunityPost? existingPost;

  const CommunityWriteScreen({Key? key, this.existingPost}) : super(key: key);

  @override
  State<CommunityWriteScreen> createState() => _CommunityWriteScreenState();
}

class _CommunityWriteScreenState extends State<CommunityWriteScreen> {
  static const int _maxImages = 5;

  final TextEditingController _contentController = TextEditingController();

  // 🌟 이미 업로드되어 있는 이미지 (수정 모드에서 넘어온 기존 URL)
  final List<String> _existingImageUrls = [];
  // 🌟 이번에 새로 선택했지만 아직 업로드하지 않은 로컬 이미지
  final List<XFile> _newImages = [];

  final List<String> _regionOptions = ['성수동', '가로수길', '직접입력'];
  final List<String> _categoryOptions = ['빵', '떡', '음료', '유행상품'];

  String _selectedRegion = '성수동';
  String _selectedCategory = '빵';
  bool _isSubmitting = false;

  String get _currentUid => AuthService.currentUser?.uid ?? UserData.uid ?? 'unknown_uid';

  bool get _isEditMode => widget.existingPost != null;

  int get _totalImageCount => _existingImageUrls.length + _newImages.length;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final post = widget.existingPost!;
      _contentController.text = post.content;
      _selectedRegion = post.region;
      _selectedCategory = post.category;
      _existingImageUrls.addAll(post.imageUrls);
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final remaining = _maxImages - _totalImageCount;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사진은 최대 5장까지 첨부할 수 있어요.')),
      );
      return;
    }

    try {
      final picker = ImagePicker();
      final picked = await picker.pickMultiImage(imageQuality: 85, limit: remaining);
      if (picked.isEmpty) return;

      setState(() {
        _newImages.addAll(picked);
      });
    } catch (e) {
      debugPrint('이미지 선택 중 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지를 불러오지 못했어요.')),
        );
      }
    }
  }

  void _removeExistingImage(int index) {
    setState(() => _existingImageUrls.removeAt(index));
  }

  void _removeNewImage(int index) {
    setState(() => _newImages.removeAt(index));
  }

  // 🌟 새로 선택한 이미지들을 Firebase Storage에 업로드하고 다운로드 URL 리스트를 반환합니다.
  Future<List<String>> _uploadNewImages() async {
    final urls = <String>[];
    for (var i = 0; i < _newImages.length; i++) {
      final file = File(_newImages[i].path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('community_posts')
          .child(_currentUid)
          .child(fileName);

      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  Future<void> _submit() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('내용을 입력해주세요.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final uploadedUrls = await _uploadNewImages();
      final finalImageUrls = [..._existingImageUrls, ...uploadedUrls];

      if (_isEditMode) {
        // 🌟 기존 글 수정
        await FirebaseFirestore.instance
            .collection('community_posts')
            .doc(widget.existingPost!.id)
            .update({
          'content': _contentController.text.trim(),
          'region': _selectedRegion,
          'category': _selectedCategory,
          'imageUrls': finalImageUrls,
        });
      } else {
        // 🌟 새 글 등록
        final post = CommunityPost(
          id: '',
          userId: _currentUid, // 🌟 authorId → userId
          authorNickname: UserData.nickname ?? '이름없음',
          authorProfileImage: UserData.profileImagePath,
          region: _selectedRegion,
          category: _selectedCategory,
          content: _contentController.text.trim(),
          imageUrls: finalImageUrls,
          createdAt: DateTime.now(),
        );

        await FirebaseFirestore.instance
            .collection('community_posts')
            .add(post.toMap());
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('글 등록/수정 중 오류 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장에 실패했어요. 다시 시도해주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
        ),
        title: Text(_isEditMode ? '글 수정' : '글쓰기',
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: Text(
              _isEditMode ? '수정' : '등록',
              style: TextStyle(
                color: _isSubmitting ? Colors.grey : const Color(0xFFFF8A3D),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImagePicker(),
                const SizedBox(height: 16),
                TextField(
                  controller: _contentController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: '오늘 다녀온 빵집, 발견한 메뉴를 자유롭게 공유해보세요',
                    border: InputBorder.none,
                  ),
                ),
                const Divider(),
                const SizedBox(height: 16),
                const Text('지역', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                _buildChoiceRow(_regionOptions, _selectedRegion,
                        (val) => setState(() => _selectedRegion = val)),
                const SizedBox(height: 20),
                const Text('카테고리', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                _buildChoiceRow(_categoryOptions, _selectedCategory,
                        (val) => setState(() => _selectedCategory = val)),
              ],
            ),
          ),
          if (_isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.15),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFFF8A3D)),
                    SizedBox(height: 12),
                    Text('이미지 업로드 중입니다...',
                        style: TextStyle(color: Colors.black87, fontSize: 13)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return SizedBox(
      height: 72,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // 🌟 이미 업로드된 이미지 (수정 모드)
          for (var i = 0; i < _existingImageUrls.length; i++)
            _buildImageThumb(
              key: ValueKey('existing_$i'),
              image: Image.network(_existingImageUrls[i], fit: BoxFit.cover),
              onRemove: () => _removeExistingImage(i),
            ),
          // 🌟 새로 선택했지만 아직 업로드되지 않은 이미지
          for (var i = 0; i < _newImages.length; i++)
            _buildImageThumb(
              key: ValueKey('new_${_newImages[i].path}'),
              image: Image.file(File(_newImages[i].path), fit: BoxFit.cover),
              onRemove: () => _removeNewImage(i),
            ),
          // 🌟 추가 버튼
          if (_totalImageCount < _maxImages)
            GestureDetector(
              onTap: _isSubmitting ? null : _pickImages,
              child: Container(
                width: 64,
                height: 64,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_outlined, color: Colors.grey),
                    Text('$_totalImageCount/$_maxImages',
                        style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageThumb({
    required Key key,
    required Widget image,
    required VoidCallback onRemove,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(width: 64, height: 64, child: image),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: _isSubmitting ? null : onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceRow(List<String> options, String selected, ValueChanged<String> onSelect) {
    return Wrap(
      spacing: 8,
      children: options.map((opt) {
        final bool isSelected = opt == selected;
        return ChoiceChip(
          label: Text(opt),
          selected: isSelected,
          selectedColor: const Color(0xFFFF8A3D),
          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 13),
          backgroundColor: const Color(0xFFF5F5F5),
          onSelected: (_) => onSelect(opt),
        );
      }).toList(),
    );
  }
}
