import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'colors/stamp_colors.dart';
import 'models/stamp_verification_models.dart';
import 'stamp_verification_complete_page.dart';
import 'widgets/place_info_card.dart';
import 'widgets/receipt_capture_area.dart';
import 'widgets/star_rating_card.dart';
import 'widgets/visit_note_input.dart';

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
          backgroundColor: YamYamStampColors.creamyIvory,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            '스탬프 인증 불가',
            style: TextStyle(
              color: YamYamStampColors.deepChocolate,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            result.message ?? '현재 기기에서는 스탬프 인증을 진행할 수 없습니다.',
            style: const TextStyle(color: YamYamStampColors.subTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                '확인',
                style: TextStyle(
                  color: YamYamStampColors.coralRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
          backgroundColor: YamYamStampColors.creamyIvory,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: YamYamStampColors.deepChocolate,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(color: YamYamStampColors.subTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                '확인',
                style: TextStyle(
                  color: YamYamStampColors.coralRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YamYamStampColors.creamyIvory,
      appBar: AppBar(
        backgroundColor: YamYamStampColors.creamyIvory,
        foregroundColor: YamYamStampColors.deepChocolate,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '영수증 스탬프 인증',
          style: TextStyle(
            color: YamYamStampColors.deepChocolate,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            if (_entryCheckComplete) _buildVerificationForm(),
            if (!_entryCheckComplete || _isSubmitting)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.white.withOpacity(0.7),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: YamYamStampColors.coralRed,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationForm() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        // 1. 매장 카드
        PlaceInfoCard(
          placeId: widget.placeId,
          placeName: widget.placeName,
        ),
        const SizedBox(height: 20),

        // 2. 별점 평가 세그먼트 카드
        StarRatingCard(
          rating: _rating,
          onRatingChanged: (newRating) {
            setState(() {
              _rating = newRating;
            });
          },
        ),

        const SizedBox(height: 20),

        // 3. 영수증 첨부 헤더 및 메인 캡처 영역
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            '영수증 사진',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: YamYamStampColors.deepChocolate,
            ),
          ),
        ),
        ReceiptCaptureArea(
          imagePath: _receiptImage?.path,
          onTap: _takeReceiptPhoto,
        ),

        if (widget.allowGallerySelection) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _pickReceiptFromGallery,
            style: OutlinedButton.styleFrom(
              foregroundColor: YamYamStampColors.deepChocolate,
              side: const BorderSide(color: YamYamStampColors.borderPink),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.photo_library_outlined, size: 20),
            label: const Text('개발용: 갤러리에서 선택'),
          ),
        ],

        const SizedBox(height: 20),

        // 4. 메모 입력창
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            '나만의 방문 메모',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: YamYamStampColors.deepChocolate,
            ),
          ),
        ),
        VisitNoteInput(
          controller: _noteController,
        ),

        const SizedBox(height: 24),

        // 5. 스탬프 발급 실행 버튼
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: YamYamStampColors.coralRed,
              foregroundColor: Colors.white,
              elevation: 3,
              shadowColor: YamYamStampColors.coralRed.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              '인증 제출하고 스탬프 받기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}