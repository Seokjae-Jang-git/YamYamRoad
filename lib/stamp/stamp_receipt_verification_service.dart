import 'receipt_ocr_checker.dart';
import 'stamp_verification_models.dart';

typedef ApprovedReceiptHandler =
    Future<int> Function({
      required StampVerificationRequest request,
      required ReceiptOcrValidationResult ocrResult,
    });

/// OCR 결과를 화면에서 사용하는 인증 결과로 변환하고, 승인된 경우에만
/// 서버 저장 콜백을 실행한다. 콜백 반환값은 지급 포인트다.
class StampReceiptVerificationService {
  final String expectedStoreName;
  final ReceiptOcrChecker ocrChecker;
  final ApprovedReceiptHandler onApproved;

  const StampReceiptVerificationService({
    required this.expectedStoreName,
    required this.ocrChecker,
    required this.onApproved,
  });

  Future<StampVerificationResult> call(StampVerificationRequest request) async {
    final ocrResult = await ocrChecker.check(
      imagePath: request.receiptImagePath,
      expectedStoreName: expectedStoreName,
    );

    switch (ocrResult.decision) {
      case ReceiptOcrDecision.retryRequired:
        return StampVerificationResult.ocrFailed(message: ocrResult.message);
      case ReceiptOcrDecision.rejected:
        return StampVerificationResult.rejected(message: ocrResult.message);
      case ReceiptOcrDecision.approved:
        final awardedPoints = await onApproved(
          request: request,
          ocrResult: ocrResult,
        );
        return StampVerificationResult.approved(awardedPoints: awardedPoints);
    }
  }
}
