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
  // 🌟 사진+영상 합쳐서 최대 5개까지만 첨부 가능
  static const int _maxMedia = 5;
  static const int _maxTags = 5;
  static const int _maxTagLength = 10;

  // 🌟 용량 제한: 사진 10MB / 영상 50MB
  static const int _maxImageBytes = 10 * 1024 * 1024;
  static const int _maxVideoBytes = 50 * 1024 * 1024;

  // 🌟 이모티콘 토큰을 실제 이미지로 인라인 렌더링하는 컨트롤러
  final EmoticonTextEditingController _contentController =
  EmoticonTextEditingController();

  // 🌟 태그 입력용 컨트롤러
  final TextEditingController _tagInputController = TextEditingController();

  // 🌟 이미 업로드되어 있는 미디어 (수정 모드에서 넘어온 기존 URL)
  final List<String> _existingImageUrls = [];
  final List<String> _existingVideoUrls = [];
  // 🌟 이번에 새로 선택했지만 아직 업로드하지 않은 로컬 미디어
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
      // 🌟 저장돼 있던 원문(토큰 포함)을 편집용 플레이스홀더 텍스트로 변환하고,
      // 이모티콘 이미지도 함께 조회해서 채워줍니다.
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

  // 🌟 이모티콘 피커에서 고른 토큰을 커서 위치에 삽입
  void _insertEmoticon(String token, String imageUrl) {
    _contentController.insertEmoticon(token, imageUrl);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // -------------------- 태그 --------------------

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

  // -------------------- 사진 + 영상 (같은 입력창) --------------------

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
      // 🌟 사진과 영상을 하나의 입력창(갤러리)에서 함께 선택합니다.
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

  // 🌟 새로 선택한 이미지들을 Firebase Storage에 업로드하고 다운로드 URL 리스트를 반환합니다.
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

  // 🌟 새로 선택한 영상들을 Firebase Storage에 업로드하고 다운로드 URL 리스트를 반환합니다.
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

    setState(() => _isSubmitting = true);

    try {
      final uploadedImageUrls = await _uploadNewImages();
      final uploadedVideoUrls = await _uploadNewVideos();
      final finalImageUrls = [..._existingImageUrls, ...uploadedImageUrls];
      final finalVideoUrls = [..._existingVideoUrls, ...uploadedVideoUrls];
      // 🌟 저장은 항상 플레이스홀더가 아니라 실제 토큰 문자열로 변환해서 씁니다.
      final storageContent = _contentController.toStorageText().trim();

      if (_isEditMode) {
        // 🌟 기존 글 수정
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
        // 🌟 새 글 등록
        // 🌟 region/category는 더 이상 입력받지 않지만, 모델/다른 화면과의 호환을
        // 위해 기본값('전체')으로 채워둡니다.
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
                // 🌟 이모티콘 토큰이 실제 이미지로 바로 보이는 입력창
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
                // 🌟 이모티콘 삽입 버튼 + 태그 입력(# )을 같은 줄에 배치
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

  // 🌟 이모티콘 아이콘 옆에 붙는 인라인 태그 입력창 ("#" 접두어로 표시)
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
          // 🌟 이미 업로드된 이미지 (수정 모드)
          for (var i = 0; i < _existingImageUrls.length; i++)
            _buildImageThumb(
              key: ValueKey('existing_img_$i'),
              image: Image.network(_existingImageUrls[i], fit: BoxFit.cover),
              onRemove: () => _removeExistingImage(i),
            ),
          // 🌟 새로 선택했지만 아직 업로드되지 않은 이미지
          for (var i = 0; i < _newImages.length; i++)
            _buildImageThumb(
              key: ValueKey('new_img_${_newImages[i].path}'),
              image: Image.file(File(_newImages[i].path), fit: BoxFit.cover),
              onRemove: () => _removeNewImage(i),
            ),
          // 🌟 이미 업로드된 영상 (수정 모드)
          for (var i = 0; i < _existingVideoUrls.length; i++)
            _buildVideoThumb(
              key: ValueKey('existing_video_$i'),
              onRemove: () => _removeExistingVideo(i),
            ),
          // 🌟 새로 선택했지만 아직 업로드되지 않은 영상
          for (var i = 0; i < _newVideos.length; i++)
            _buildVideoThumb(
              key: ValueKey('new_video_${_newVideos[i].path}'),
              onRemove: () => _removeNewVideo(i),
            ),
          // 🌟 사진/영상을 한 번에 고르는 단일 입력 버튼
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

  // 🌟 영상은 썸네일 프레임 대신 재생 아이콘이 있는 플레이스홀더로 표시합니다.
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