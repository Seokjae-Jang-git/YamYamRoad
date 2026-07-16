import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../common/user_data.dart';
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
  final TextEditingController _contentController = TextEditingController();
  final List<String> _imageUrls = []; // TODO: 실제 이미지 업로드(Firebase Storage) 연동 필요

  final List<String> _regionOptions = ['성수동', '가로수길', '직접입력'];
  final List<String> _categoryOptions = ['빵', '떡', '음료', '유행상품'];

  String _selectedRegion = '성수동';
  String _selectedCategory = '빵';
  bool _isSubmitting = false;

  bool get _isEditMode => widget.existingPost != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final post = widget.existingPost!;
      _contentController.text = post.content;
      _selectedRegion = post.region;
      _selectedCategory = post.category;
      _imageUrls.addAll(post.imageUrls);
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
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
      if (_isEditMode) {
        // 🌟 기존 글 수정
        await FirebaseFirestore.instance
            .collection('community_posts')
            .doc(widget.existingPost!.id)
            .update({
          'content': _contentController.text.trim(),
          'region': _selectedRegion,
          'category': _selectedCategory,
          'imageUrls': _imageUrls,
        });
      } else {
        // 🌟 새 글 등록
        final post = CommunityPost(
          id: '',
          authorId: UserData.uid,
          authorNickname: UserData.nickname,
          authorProfileImage: UserData.profileImagePath,
          region: _selectedRegion,
          category: _selectedCategory,
          content: _contentController.text.trim(),
          imageUrls: _imageUrls,
          createdAt: DateTime.now(),
        );
        await FirebaseFirestore.instance
            .collection('community_posts')
            .add(post.toMap());
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      print('글 등록/수정 중 오류 발생: $e');
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
          onPressed: () => Navigator.pop(context),
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
      body: SingleChildScrollView(
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
    );
  }

  Widget _buildImagePicker() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            // TODO: 이미지 선택 + Firebase Storage 업로드 연동
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('이미지 업로드는 준비중입니다.')),
            );
          },
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.camera_alt_outlined, color: Colors.grey),
          ),
        ),
        const SizedBox(width: 8),
        Text('${_imageUrls.length}/5', style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
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
