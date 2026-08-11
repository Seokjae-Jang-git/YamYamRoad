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
  // 🌟 얌얌로드 공식 컬러 팔레트
  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color creamyIvory = Color(0xFFFFFDF9);
  static const Color subTextColor = Color(0xFF7A6B63);

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _emailController = TextEditingController();

  String _selectedType = 'general';
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
        const SnackBar(content: Text('이미지를 불러오지 못했습니다.', style: TextStyle(color: creamyIvory)), backgroundColor: deepChocolate),
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
        Navigator.of(context).pop(true);
      } else {
        final inquiryId = await repo.add(
          type: _selectedType,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          contactEmail: _emailController.text.trim(),
          imagePath: _imagePath,
        );
        if (!mounted) return;
        setState(() => _submitting = false);

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
        SnackBar(content: Text('문의 처리에 실패했습니다: $e', style: const TextStyle(color: creamyIvory)), backgroundColor: pointCoralRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.isEditMode;

    return Scaffold(
      backgroundColor: creamyIvory,
      appBar: AppBar(
        backgroundColor: creamyIvory,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: deepChocolate, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isEdit ? '문의 수정' : '문의하기',
          style: const TextStyle(color: deepChocolate, fontWeight: FontWeight.bold, fontSize: 22),
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
            // 🌟 실시간 글자수 카운팅 적용 텍스트 필드
            TextFormField(
              controller: _contentController,
              maxLength: 150,
              maxLines: 6,
              style: const TextStyle(color: deepChocolate, fontSize: 14),
              validator: (v) => (v == null || v.trim().isEmpty) ? '내용을 입력해주세요' : null,
              decoration: InputDecoration(
                hintText: '문의 하실 내용을 자세히 작성해주세요',
                hintStyle: const TextStyle(color: subTextColor, fontSize: 14),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: deepChocolate.withOpacity(0.15)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: deepChocolate.withOpacity(0.15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: pointCoralRed, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: pointCoralRed),
                ),
              ),
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                return Text(
                  '$currentLength/${maxLength}자',
                  style: const TextStyle(color: subTextColor, fontSize: 12),
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: deepChocolate),
  );

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(child: _typeChip('general', '일반')),
        const SizedBox(width: 12),
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
          color: selected ? deepChocolate : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? deepChocolate : deepChocolate.withOpacity(0.15)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : subTextColor,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
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
      style: const TextStyle(color: deepChocolate, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: subTextColor, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: deepChocolate.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: deepChocolate.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: pointCoralRed, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: pointCoralRed),
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: deepChocolate.withOpacity(0.15)),
        ),
        child: _imagePath == null
            ? Icon(Icons.add_photo_alternate_outlined, color: subTextColor.withOpacity(0.5), size: 32)
            : ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              isNetworkImage
                  ? Image.network(_imagePath!, fit: BoxFit.cover)
                  : Image.file(File(_imagePath!), fit: BoxFit.cover),
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () => setState(() => _imagePath = null),
                  child: const CircleAvatar(
                    radius: 12,
                    backgroundColor: pointCoralRed,
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
      child: ElevatedButton(
        onPressed: _submitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: pointCoralRed,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _submitting
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        )
            : Text(
          isEdit ? '수정 완료' : '문의 등록',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}