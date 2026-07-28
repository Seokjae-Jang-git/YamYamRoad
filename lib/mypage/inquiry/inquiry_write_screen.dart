import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'inquiry_model.dart';
import 'inquiry_repository.dart';
import 'inquiry_success_screen.dart';

class InquiryWriteScreen extends StatefulWidget {
  final InquiryModel? editTarget;

  const InquiryWriteScreen({Key? key, this.editTarget}) : super(key: key);

  bool get isEditMode => editTarget != null;

  @override
  State<InquiryWriteScreen> createState() => _InquiryWriteScreenState();
}

class _InquiryWriteScreenState extends State<InquiryWriteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _emailController = TextEditingController();

  String _selectedType = 'general'; // 'general' 또는 'partnership'
  String? _imagePath;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final target = widget.editTarget;
    if (target != null) {
      _selectedType = target.type;
      _titleController.text = target.title;
      _contentController.text = target.content;
      _emailController.text = target.contactEmail ?? '';
      _imagePath = target.imageUrl;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // 🌟 이미지 첨부
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() => _imagePath = picked.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지를 불러오지 못했습니다.')),
      );
    }
  }

  // 🌟 등록/수정 제출
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final repo = InquiryRepository.instance;

    try {
      if (widget.isEditMode) {
        // 수정 모드
        await repo.update(
          id: widget.editTarget!.id,
          type: _selectedType,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          contactEmail: _emailController.text.trim(),
          imagePath: _imagePath,
        );
        if (!mounted) return;
        setState(() => _submitting = false);
        Navigator.of(context).pop(true); // 수정 성공 신호 전달
      } else {
        // 신규 등록 모드 (Repository에서 INQ- 문의번호 반환)
        final inquiryId = await repo.add(
          type: _selectedType,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          contactEmail: _emailController.text.trim(),
          imagePath: _imagePath,
        );
        if (!mounted) return;
        setState(() => _submitting = false);

        // 작성 완료 시 성공 화면으로 이동 (생성된 ID와 데이터 전달)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => InquirySuccessScreen(
              inquiryId: inquiryId,
              title: _titleController.text.trim(),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('문의 처리에 실패했습니다: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.isEditMode;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isEdit ? '문의 수정' : '문의하기',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildLabel('문의 유형'),
            const SizedBox(height: 10),
            _buildTypeSelector(),
            const SizedBox(height: 24),

            _buildLabel('제목'),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _titleController,
              hint: '문의 제목을 입력해주세요',
              validator: (v) => (v == null || v.trim().isEmpty) ? '제목을 입력해주세요' : null,
            ),
            const SizedBox(height: 24),

            _buildLabel('내용'),
            const SizedBox(height: 10),
            // 🌟 실시간 글자수 카운팅 (0/150자) 텍스트 필드
            TextFormField(
              controller: _contentController,
              maxLength: 150,
              maxLines: 6,
              style: const TextStyle(color: Colors.black87),
              validator: (v) => (v == null || v.trim().isEmpty) ? '내용을 입력해주세요' : null,
              decoration: InputDecoration(
                hintText: '문의 하실 내용을 자세히 작성해주세요',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black),
                ),
              ),
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                return Text(
                  '$currentLength/${maxLength}자',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                );
              },
            ),
            const SizedBox(height: 16),

            _buildLabel('답변받을 이메일'),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _emailController,
              hint: '이메일 주소를 입력해주세요',
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '이메일을 입력해주세요';
                final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
                return ok ? null : '올바른 이메일 형식이 아닙니다';
              },
            ),
            const SizedBox(height: 24),

            _buildLabel('이미지 첨부 (선택)'),
            const SizedBox(height: 10),
            _buildImagePicker(),
            const SizedBox(height: 40),

            _buildSubmitButton(isEdit),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
  );

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(child: _typeChip('general', '일반')),
        const SizedBox(width: 10),
        Expanded(child: _typeChip('partnership', '광고/제휴')),
      ],
    );
  }

  Widget _typeChip(String typeValue, String label) {
    final selected = _selectedType == typeValue;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = typeValue),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? Colors.black : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.black),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    final isNetworkImage = _imagePath != null && _imagePath!.startsWith('http');

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: _imagePath == null
            ? const Icon(Icons.add_photo_alternate_outlined, color: Colors.grey, size: 30)
            : ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              isNetworkImage
                  ? Image.network(_imagePath!, fit: BoxFit.cover)
                  : Image.file(File(_imagePath!), fit: BoxFit.cover),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => setState(() => _imagePath = null),
                  child: const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isEdit) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _submitting ? null : _submit,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade400),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _submitting
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
        )
            : Text(
          isEdit ? '수정 완료' : '문의 등록',
          style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}