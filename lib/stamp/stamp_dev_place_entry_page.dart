import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'mlkit_receipt_text_recognizer.dart';
import 'receipt_ocr_checker.dart';
import 'stamp_receipt_verification_service.dart';
import 'stamp_verification_api_client.dart';
import 'stamp_verification_models.dart';
import 'stamp_verification_page.dart';

class StampDevPlaceEntryPage extends StatefulWidget {
  const StampDevPlaceEntryPage({super.key});

  @override
  State<StampDevPlaceEntryPage> createState() =>
      _StampDevPlaceEntryPageState();
}

class _StampDevPlaceEntryPageState extends State<StampDevPlaceEntryPage> {
  final TextEditingController _placeIdController = TextEditingController();
  final StampVerificationApiClient _apiClient = StampVerificationApiClient();
  bool _isLoading = false;

  @override
  void dispose() {
    _placeIdController.dispose();
    super.dispose();
  }

  Future<void> _openVerification() async {
    final placeId = _placeIdController.text.trim();
    if (placeId.isEmpty) {
      _showMessage('placeId를 입력해 주세요.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final placeSnapshot = await FirebaseFirestore.instance
          .collection('place')
          .doc(placeId)
          .get();

      if (!placeSnapshot.exists) {
        _showMessage('place/$placeId 문서를 찾지 못했습니다.');
        return;
      }

      final placeName = placeSnapshot.data()?['name']?.toString().trim() ?? '';
      if (placeName.isEmpty) {
        _showMessage('해당 업체 문서에 name 값이 없습니다.');
        return;
      }
      final placeLat = _asDouble(placeSnapshot.data()?['lat']);
      final placeLng = _asDouble(placeSnapshot.data()?['lng']);
      if (placeLat == null || placeLng == null) {
        _showMessage('해당 업체 문서에 lat/lng 값이 없습니다.');
        return;
      }

      if (!mounted) return;

      final verificationService = StampReceiptVerificationService(
        expectedStoreName: placeName,
        ocrChecker: const ReceiptOcrChecker(
          recognizer: MlKitReceiptTextRecognizer(),
        ),
        onApproved: ({required request, required ocrResult}) async {
          return _apiClient.issueStamp(
            verificationRequest: request,
            ocrResult: ocrResult,
            userLat: placeLat,
            userLng: placeLng,
          );
        },
      );

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => StampVerificationPage(
            placeId: placeId,
            placeName: placeName,
            runEntryCheck: () async => const StampEntryCheckResult.allowed(),
            submitVerification: verificationService.call,
            allowGallerySelection: true,
          ),
        ),
      );
    } on FirebaseException catch (error) {
      _showMessage('업체 조회 실패: ${error.code}');
    } catch (_) {
      _showMessage('업체 정보를 불러오지 못했습니다.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  double? _asDouble(Object? value) {
    return value is num ? value.toDouble() : double.tryParse('$value');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('스탬프 개발 테스트')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4D6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '개발 전용 화면입니다. 기기 무결성 검사를 건너뛰며, '
                  'GPS 대신 업체 좌표를 사용합니다. OCR과 서버 검증이 성공하면 '
                  'verification·stamp·별점이 실제 DB에 저장됩니다.',
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _placeIdController,
                enabled: !_isLoading,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _openVerification(),
                decoration: const InputDecoration(
                  labelText: 'placeId',
                  hintText: 'Firestore place 문서 ID 입력',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _isLoading ? null : _openVerification,
                  child: _isLoading
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('인증 화면 열기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
