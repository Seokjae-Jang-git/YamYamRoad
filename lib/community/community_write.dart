import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../common/user_data.dart';
import '../../services/auth_service.dart';
import 'community_post.dart';
import '../../features/emoticon/emoticon_picker_sheet.dart';
import '../../features/emoticon/emoticon_text_controller.dart';

// 🌟 새 글 작성 + 기존 글 수정을 모두 담당하는 화면
// existingPost 가 넘어오면 '수정 모드'로 동작합니다.
class CommunityWriteScreen extends StatefulWidget {
  final CommunityPost? existingPost;

  const CommunityWriteScreen({Key? key, this.existingPost}) : super(key: key);

  @override
  State<CommunityWriteScreen> createState() => _CommunityWriteScreenState();
}

class _CommunityWriteScreenState extends State<CommunityWriteScreen> {
  static const int _maxMedia = 5;
  static const int _maxTags = 5;
  static const int _maxTagLength = 10;

  static const int _maxImageBytes = 10 * 1024 * 1024;
  static const int _maxVideoBytes = 50 * 1024 * 1024;

  final EmoticonTextEditingController _contentController =
  EmoticonTextEditingController();

  final TextEditingController _tagInputController = TextEditingController();

  final List<String> _existingImageUrls = [];
  final List<String> _existingVideoUrls = [];
  final List<XFile> _newImages = [];
  final List<XFile> _newVideos = [];

  final List<String> _tags = [];

  bool _isSubmitting = false;

  String get _currentUid => AuthService.currentUser?.uid ?? UserData.uid ?? 'unknown_uid';

  bool get _isEditMode => widget.existingPost != null;

  int get _totalMediaCount =>
      _existingImageUrls.length + _existingVideoUrls.length + _newImages.length + _newVideos.length;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final post = widget.existingPost!;
      _contentController.loadStoredContent(post.content).then((_) {
        if (mounted) setState(() {});
      });
      _existingImageUrls.addAll(post.imageUrls);
      _existingVideoUrls.addAll(post.videoUrls);
      _tags.addAll(post.tags);
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  void _insertEmoticon(String token, String imageUrl) {
    _contentController.insertEmoticon(token, imageUrl);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _addTag(String raw) {
    final value = raw.trim();
    _tagInputController.clear();
    if (value.isEmpty) return;

    if (_tags.length >= _maxTags) {
      _showMessage('태그는 최대 $_maxTags개까지 추가할 수 있어요.');
      return;
    }
    if (value.length > _maxTagLength) {
      _showMessage('태그는 최대 $_maxTagLength자까지 입력할 수 있어요.');
      return;
    }
    if (_tags.contains(value)) {
      _showMessage('이미 추가한 태그예요.');
      return;
    }

    setState(() => _tags.add(value));
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  static const Set<String> _videoExtensions = {
    '.mp4', '.mov', '.avi', '.mkv', '.webm', '.3gp', '.m4v',
  };

  bool _isVideoFile(String path) {
    final lower = path.toLowerCase();
    return _videoExtensions.any((ext) => lower.endsWith(ext));
  }

  Future<void> _pickMedia() async {
    final remaining = _maxMedia - _totalMediaCount;
    if (remaining <= 0) {
      _showMessage('사진/영상은 합쳐서 최대 $_maxMedia개까지 첨부할 수 있어요.');
      return;
    }

    try {
      final picker = ImagePicker();
      final picked = await picker.pickMultipleMedia(imageQuality: 85, limit: remaining);
      if (picked.isEmpty) return;

      final acceptedImages = <XFile>[];
      final acceptedVideos = <XFile>[];

      for (final file in picked) {
        final size = await File(file.path).length();
        if (_isVideoFile(file.path)) {
          if (size > _maxVideoBytes) {
            _showMessage('${file.name}: 영상 용량은 최대 50MB까지 업로드할 수 있어요.');
            continue;
          }
          acceptedVideos.add(file);
        } else {
          if (size > _maxImageBytes) {
            _showMessage('${file.name}: 사진 용량은 최대 10MB까지 업로드할 수 있어요.');
            continue;
          }
          acceptedImages.add(file);
        }
      }

      if (acceptedImages.isEmpty && acceptedVideos.isEmpty) return;

      setState(() {
        _newImages.addAll(acceptedImages);
        _newVideos.addAll(acceptedVideos);
      });
    } catch (e) {
      debugPrint('미디어 선택 중 오류: $e');
      _showMessage('사진/영상을 불러오지 못했어요.');
    }
  }

  void _removeExistingImage(int index) {
    setState(() => _existingImageUrls.removeAt(index));
  }

  void _removeNewImage(int index) {
    setState(() => _newImages.removeAt(index));
  }

  void _removeExistingVideo(int index) {
    setState(() => _existingVideoUrls.removeAt(index));
  }

  void _removeNewVideo(int index) {
    setState(() => _newVideos.removeAt(index));
  }

  Future<List<String>> _uploadNewImages() async {
    final urls = <String>[];
    for (var i = 0; i < _newImages.length; i++) {
      final file = File(_newImages[i].path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('posts')
          .child(_currentUid)
          .child(fileName);

      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  Future<List<String>> _uploadNewVideos() async {
    final urls = <String>[];
    for (var i = 0; i < _newVideos.length; i++) {
      final file = File(_newVideos[i].path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_video_$i.mp4';
      final ref = FirebaseStorage.instance
          .ref()
          .child('posts')
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
      _showMessage('내용을 입력해주세요.');
      return;
    }

    // 🌟 태그 입력창에 글자를 써놓고 Enter를 안 누른 채 바로 등록/수정을 누르는
    // 경우가 많아서, 제출 직전에 남아있는 텍스트를 태그로 자동 커밋합니다.
    final pendingTag = _tagInputController.text.trim();
    if (pendingTag.isNotEmpty) {
      _addTag(pendingTag);
    }

    setState(() => _isSubmitting = true);

    try {
      final uploadedImageUrls = await _uploadNewImages();
      final uploadedVideoUrls = await _uploadNewVideos();
      final finalImageUrls = [..._existingImageUrls, ...uploadedImageUrls];
      final finalVideoUrls = [..._existingVideoUrls, ...uploadedVideoUrls];
      final storageContent = _contentController.toStorageText().trim();

      if (_isEditMode) {
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.existingPost!.id)
            .update({
          'content': storageContent,
          'imageUrls': finalImageUrls,
          'videoUrls': finalVideoUrls,
          'tags': _tags,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final post = CommunityPost(
          id: '',
          userId: _currentUid,
          nickname: UserData.nickname ?? '이름없음',
          profileImage: UserData.profileImagePath,
          region: '전체',
          category: '전체',
          content: storageContent,
          imageUrls: finalImageUrls,
          videoUrls: finalVideoUrls,
          tags: _tags,
          createdAt: DateTime.now(),
        );

        await FirebaseFirestore.instance
            .collection('posts')
            .add(post.toMap());
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('글 등록/수정 중 오류 발생: $e');
      _showMessage('저장에 실패했어요. 다시 시도해주세요.');
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
                _buildMediaPicker(),
                const SizedBox(height: 4),
                Text(
                  '사진 최대 10MB, 영상 최대 50MB · 사진/영상 합쳐서 최대 $_maxMedia개',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _contentController,
                  maxLines: 5,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: '오늘 다녀온 빵집, 발견한 메뉴를 자유롭게 공유해보세요',
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
                      tooltip: '이모티콘',
                      onPressed: _isSubmitting
                          ? null
                          : () => EmoticonPickerSheet.show(
                        context,
                        uid: _currentUid,
                        onSelect: (token, imageUrl) {
                          _insertEmoticon(token, imageUrl);
                          setState(() {});
                        },
                      ),
                    ),
                    Expanded(child: _buildTagInput()),
                  ],
                ),
                if (_tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: _buildTagChips(),
                  ),
                ],
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 52),
                  child: Text('태그는 최대 $_maxTags개까지 추가할 수 있어요.',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ),
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
                    Text('업로드 중입니다...',
                        style: TextStyle(color: Colors.black87, fontSize: 13)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTagInput() {
    final bool reachedLimit = _tags.length >= _maxTags;
    return TextField(
      controller: _tagInputController,
      enabled: !_isSubmitting && !reachedLimit,
      maxLength: _maxTagLength,
      textInputAction: TextInputAction.done,
      onSubmitted: _addTag,
      decoration: InputDecoration(
        prefixText: '# ',
        prefixStyle: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
        hintText: reachedLimit ? '태그를 최대 $_maxTags개까지 추가했어요' : '태그 입력 후 Enter',
        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        isDense: true,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      style: const TextStyle(fontSize: 13),
    );
  }

  Widget _buildTagChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _tags.map((tag) {
        return Chip(
          label: Text('#$tag', style: const TextStyle(fontSize: 12)),
          backgroundColor: const Color(0xFFF5F5F5),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: _isSubmitting ? null : () => _removeTag(tag),
        );
      }).toList(),
    );
  }

  Widget _buildMediaPicker() {
    return SizedBox(
      height: 72,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < _existingImageUrls.length; i++)
            _buildImageThumb(
              key: ValueKey('existing_img_$i'),
              image: Image.network(_existingImageUrls[i], fit: BoxFit.cover),
              onRemove: () => _removeExistingImage(i),
            ),
          for (var i = 0; i < _newImages.length; i++)
            _buildImageThumb(
              key: ValueKey('new_img_${_newImages[i].path}'),
              image: Image.file(File(_newImages[i].path), fit: BoxFit.cover),
              onRemove: () => _removeNewImage(i),
            ),
          for (var i = 0; i < _existingVideoUrls.length; i++)
            _buildVideoThumb(
              key: ValueKey('existing_video_$i'),
              onRemove: () => _removeExistingVideo(i),
            ),
          for (var i = 0; i < _newVideos.length; i++)
            _buildVideoThumb(
              key: ValueKey('new_video_${_newVideos[i].path}'),
              onRemove: () => _removeNewVideo(i),
            ),
          if (_totalMediaCount < _maxMedia)
            GestureDetector(
              onTap: _isSubmitting ? null : _pickMedia,
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
                    const Icon(Icons.add_photo_alternate_outlined, color: Colors.grey),
                    Text('$_totalMediaCount/$_maxMedia',
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

  Widget _buildVideoThumb({
    required Key key,
    required VoidCallback onRemove,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.play_circle_outline, color: Colors.white),
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
}
