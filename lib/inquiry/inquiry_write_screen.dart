import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'app_colors.dart';
import 'inquiry.dart';
import 'inquiry_repository.dart';
import 'inquiry_success_screen.dart';

/// 문의하기 화면.
/// [editTarget]이 null이면 "신규 등록", 값이 있으면 "수정" 모드로 동작한다.
class InquiryWriteScreen extends StatefulWidget {
  final Inquiry? editTarget;

  const InquiryWriteScreen({super.key, this.editTarget});

  bool get isEditMode => editTarget != null;

  @override
  State<InquiryWriteScreen> createState() => _InquiryWriteScreenState();
}

class _InquiryWriteScreenState extends State<InquiryWriteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _emailController = TextEditingController();

  InquiryType _selectedType = InquiryType.general;
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
        Navigator.of(context).pop(true); // true = 변경됨을 알림
      } else {
        final created = await repo.add(
          type: _selectedType,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          contactEmail: _emailController.text.trim(),
          imagePath: _imagePath,
        );
        if (!mounted) return;
        setState(() => _submitting = false);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => InquirySuccessScreen(inquiry: created),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isEdit ? '문의 수정하기' : '문의하기',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
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
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? '제목을 입력해주세요' : null,
            ),
            const SizedBox(height: 24),
            _buildLabel('내용'),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _contentController,
              hint: '문의하실 내용을 자세히 작성해주세요',
              maxLines: 6,
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? '내용을 입력해주세요' : null,
            ),
            const SizedBox(height: 24),
            _buildLabel('답변받을 이메일'),
            const SizedBox(height: 10),
            _buildTextField(
              controller: _emailController,
              hint: 'yamyamroad@email.com',
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '이메일을 입력해주세요';
                final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
                return ok ? null : '올바른 이메일 형식이 아니에요';
              },
            ),
            const SizedBox(height: 24),
            _buildLabel('이미지 첨부 (선택)'),
            const SizedBox(height: 10),
            _buildImagePicker(),
            const SizedBox(height: 36),
            _buildSubmitButton(isEdit),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
  );

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(child: _typeChip(InquiryType.general)),
        const SizedBox(width: 10),
        Expanded(child: _typeChip(InquiryType.partnership)),
      ],
    );
  }

  Widget _typeChip(InquiryType type) {
    final selected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          type.label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.hint),
        filled: true,
        fillColor: AppColors.cardBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    // 🌟 수정 모드에서 기존 이미지가 URL(http)일 수도, 새로 고른 로컬 파일일 수도 있습니다.
    final isNetworkImage = _imagePath != null && _imagePath!.startsWith('http');

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
        ),
        child: _imagePath == null
            ? const Icon(Icons.camera_alt_outlined, color: AppColors.textSecondary)
            : ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              isNetworkImage
                  ? Image.network(_imagePath!, fit: BoxFit.cover)
                  : Image.file(File(_imagePath!), fit: BoxFit.cover),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () => setState(() => _imagePath = null),
                  child: const CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, size: 12, color: Colors.white),
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
          backgroundColor: AppColors.primary,
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}