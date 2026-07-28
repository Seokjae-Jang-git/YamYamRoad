import 'package:flutter/material.dart';

import '../stamp_verification_page.dart';
import 'mlkit_receipt_text_recognizer.dart';
import 'receipt_ocr_checker.dart';
import 'safe_device_integrity_probe.dart';
import 'stamp_integrity_checker.dart';
import 'stamp_location_evidence_collector.dart';
import 'stamp_receipt_verification_service.dart';
import 'stamp_verification_api_client.dart';

class StampVerificationNavigator {
  const StampVerificationNavigator._();

  static Future<void> open({
    required BuildContext context,
    required String placeId,
    required String placeName,
  }) async {
    final normalizedPlaceId = placeId.trim();
    final normalizedPlaceName = placeName.trim();
    if (normalizedPlaceId.isEmpty || normalizedPlaceName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('업체 정보를 확인하지 못했습니다.')));
      return;
    }

    final apiClient = StampVerificationApiClient();
    const integrityChecker = StampIntegrityChecker(
      probe: SafeDeviceIntegrityProbe(),
    );
    const locationCollector = StampLocationEvidenceCollector();
    final verificationService = StampReceiptVerificationService(
      expectedStoreName: normalizedPlaceName,
      ocrChecker: const ReceiptOcrChecker(
        recognizer: MlKitReceiptTextRecognizer(),
      ),
      onApproved: ({required request, required ocrResult}) async {
        final location = await locationCollector.collect();
        return apiClient.issueStamp(
          verificationRequest: request,
          ocrResult: ocrResult,
          userLat: location.latitude,
          userLng: location.longitude,
          isMockLocation: location.isMockLocation,
        );
      },
    );

    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StampVerificationPage(
          placeId: normalizedPlaceId,
          placeName: normalizedPlaceName,
          runEntryCheck: integrityChecker.call,
          submitVerification: verificationService.call,
        ),
      ),
    );
  }
}
