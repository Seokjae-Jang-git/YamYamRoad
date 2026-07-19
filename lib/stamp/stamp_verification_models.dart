enum StampEntryBlockReason {
  rootedDevice,
  riskyBackgroundApp,
  integrityCheckFailed,
}

class StampEntryCheckResult {
  final bool isAllowed;
  final StampEntryBlockReason? blockReason;
  final String? message;

  const StampEntryCheckResult._({
    required this.isAllowed,
    this.blockReason,
    this.message,
  });

  const StampEntryCheckResult.allowed() : this._(isAllowed: true);

  const StampEntryCheckResult.blocked({
    required StampEntryBlockReason reason,
    required String message,
  }) : this._(isAllowed: false, blockReason: reason, message: message);
}

class StampVerificationRequest {
  final String placeId;
  final String receiptImagePath;
  final int rating;
  final String? note;

  const StampVerificationRequest({
    required this.placeId,
    required this.receiptImagePath,
    required this.rating,
    this.note,
  });
}

enum StampVerificationStatus { approved, ocrFailed, rejected }

class StampVerificationResult {
  final StampVerificationStatus status;
  final String? message;
  final int awardedPoints;

  const StampVerificationResult._({
    required this.status,
    this.message,
    this.awardedPoints = 0,
  });

  const StampVerificationResult.approved({int awardedPoints = 0})
    : this._(
        status: StampVerificationStatus.approved,
        awardedPoints: awardedPoints,
      );

  const StampVerificationResult.ocrFailed({
    String message = '영수증 인식에 실패했습니다. 다시 촬영해 주세요.',
  }) : this._(status: StampVerificationStatus.ocrFailed, message: message);

  const StampVerificationResult.rejected({required String message})
    : this._(status: StampVerificationStatus.rejected, message: message);
}

typedef StampEntryChecker = Future<StampEntryCheckResult> Function();

typedef StampVerificationSubmitter =
    Future<StampVerificationResult> Function(StampVerificationRequest request);
