import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'models/stamp_verification_models.dart';

class StampVerificationPage extends StatefulWidget {
  final String placeId;
  final String placeName;
  final StampEntryChecker runEntryCheck;
  final StampVerificationSubmitter submitVerification;
  final bool allowGallerySelection;

  const StampVerificationPage({
    super.key,
    required this.placeId,
    required this.placeName,
    required this.runEntryCheck,
    required this.submitVerification,
    this.allowGallerySelection = false,
  });

  @override
  State<StampVerificationPage> createState() => _StampVerificationPageState();
}

class _StampVerificationPageState extends State<StampVerificationPage> {
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _noteController = TextEditingController();

  XFile? _receiptImage;
  int _rating = 0;
  bool _entryCheckComplete = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _runEntryCheck();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _runEntryCheck() async {
    StampEntryCheckResult result;

    try {
      result = await widget.runEntryCheck();
    } catch (_) {
      result = const StampEntryCheckResult.blocked(
        reason: StampEntryBlockReason.integrityCheckFailed,
        message: '보안 상태를 확인하지 못했습니다. 잠시 후 다시 시도해 주세요.',
      );
    }

    if (!mounted) return;

    if (result.isAllowed) {
      setState(() {
        _entryCheckComplete = true;
      });
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('스탬프 인증 불가'),
          content: Text(result.message ?? '현재 기기에서는 스탬프 인증을 진행할 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );

    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _takeReceiptPhoto() async {
    await _pickReceipt(ImageSource.camera);
  }

  Future<void> _pickReceiptFromGallery() async {
    await _pickReceipt(ImageSource.gallery);
  }

  Future<void> _pickReceipt(ImageSource source) async {
    final image = await _imagePicker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 90,
    );

    if (!mounted || image == null) return;

    setState(() {
      _receiptImage = image;
    });
  }

  Future<void> _submit() async {
    if (_receiptImage == null) {
      await _showMessage(title: '영수증 사진 필요', message: '영수증을 촬영한 후 다시 시도해 주세요.');
      return;
    }

    if (_rating == 0) {
      await _showMessage(title: '별점 선택', message: '업체 별점을 선택해 주세요.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    StampVerificationResult result;
    try {
      result = await widget.submitVerification(
        StampVerificationRequest(
          placeId: widget.placeId,
          receiptImagePath: _receiptImage!.path,
          rating: _rating,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        ),
      );
    } catch (_) {
      result = const StampVerificationResult.rejected(
        message: '인증 중 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.',
      );
    }

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    switch (result.status) {
      case StampVerificationStatus.approved:
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => StampVerificationCompletePage(
              placeName: widget.placeName,
              receiptImagePath: _receiptImage!.path,
              rating: _rating,
              note: _noteController.text.trim(),
              awardedPoints: result.awardedPoints,
            ),
          ),
        );
      case StampVerificationStatus.ocrFailed:
        await _showMessage(
          title: '영수증 인식 실패',
          message: result.message ?? '영수증 인식에 실패했습니다. 다시 촬영해 주세요.',
        );
        if (mounted) {
          setState(() {
            _receiptImage = null;
          });
        }
      case StampVerificationStatus.rejected:
        await _showMessage(
          title: '스탬프 인증 실패',
          message: result.message ?? '인증 조건을 충족하지 못했습니다.',
        );
    }
  }

  Future<void> _showMessage({required String title, required String message}) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF504D46),
        elevation: 0,
        title: const Text(
          '스탬프 인증',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            if (_entryCheckComplete) _buildVerificationForm(),
            if (!_entryCheckComplete || _isSubmitting)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x99FFFFFF),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationForm() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _PlaceCard(placeId: widget.placeId, placeName: widget.placeName),
        const SizedBox(height: 20),
        const Text(
          '별점',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final value = index + 1;
            return IconButton(
              tooltip: '$value점',
              onPressed: () {
                setState(() {
                  _rating = value;
                });
              },
              icon: Icon(
                value <= _rating
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: const Color(0xFFFFB74D),
                size: 36,
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        const Text(
          '영수증',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        _ReceiptCaptureArea(
          imagePath: _receiptImage?.path,
          onTap: _takeReceiptPhoto,
        ),
        if (widget.allowGallerySelection) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _pickReceiptFromGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('개발용: 갤러리에서 영수증 선택'),
          ),
        ],
        const SizedBox(height: 20),
        TextField(
          controller: _noteController,
          maxLength: 100,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: '나만의 메모',
            hintText: '이곳에서의 기억을 한 줄로 남겨보세요.',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF75BDF5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              '인증하기',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final String placeId;
  final String placeName;

  const _PlaceCard({required this.placeId, required this.placeName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFFFE4E2),
            child: Text('🍰'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  placeName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  placeId,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptCaptureArea extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onTap;

  const _ReceiptCaptureArea({required this.imagePath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E2E2)),
        ),
        child: imagePath == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 54,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    '눌러서 영수증 촬영',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '상호명과 결제 시간이 잘 보이게 찍어주세요.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.file(
                  File(imagePath!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, _, _) =>
                      const Center(child: Text('사진을 불러오지 못했습니다. 다시 촬영해 주세요.')),
                ),
              ),
      ),
    );
  }
}

class StampVerificationCompletePage extends StatelessWidget {
  final String placeName;
  final String receiptImagePath;
  final int rating;
  final String note;
  final int awardedPoints;

  const StampVerificationCompletePage({
    super.key,
    required this.placeName,
    required this.receiptImagePath,
    required this.rating,
    required this.note,
    required this.awardedPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF504D46),
        elevation: 0,
        title: const Text(
          '스탬프 인증 완료',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF9CE3D4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text('🍒', style: TextStyle(fontSize: 58)),
                  const SizedBox(height: 10),
                  Text(
                    placeName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    awardedPoints > 0
                        ? '스탬프와 $awardedPoints 포인트를 받았습니다.'
                        : '스탬프를 받았습니다.',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(receiptImagePath),
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: const Color(0xFFFFB74D),
                ),
              ),
            ),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(note),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF75BDF5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  '돌아가기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
