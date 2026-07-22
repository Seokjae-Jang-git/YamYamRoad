enum ReceiptOcrDecision { approved, retryRequired, rejected }

enum ReceiptOcrFailureReason {
  emptyText,
  storeNameNotFound,
  storeNameMismatch,
  purchaseDateTimeNotFound,
  invalidPurchaseDateTime,
  receiptExpired,
  futureDatedReceipt,
  recognitionError,
}

class ReceiptOcrValidationResult {
  final ReceiptOcrDecision decision;
  final ReceiptOcrFailureReason? failureReason;
  final String message;
  final String? storeName;
  final DateTime? purchasedAt;
  final int? amount;
  final double storeNameSimilarity;

  const ReceiptOcrValidationResult._({
    required this.decision,
    required this.message,
    this.failureReason,
    this.storeName,
    this.purchasedAt,
    this.amount,
    this.storeNameSimilarity = 0,
  });

  const ReceiptOcrValidationResult.approved({
    required String storeName,
    required DateTime purchasedAt,
    required double storeNameSimilarity,
    int? amount,
  }) : this._(
         decision: ReceiptOcrDecision.approved,
         message: '영수증 인증에 성공했습니다.',
         storeName: storeName,
         purchasedAt: purchasedAt,
         amount: amount,
         storeNameSimilarity: storeNameSimilarity,
       );

  const ReceiptOcrValidationResult.retry({
    required ReceiptOcrFailureReason reason,
    required String message,
  }) : this._(
         decision: ReceiptOcrDecision.retryRequired,
         failureReason: reason,
         message: message,
       );

  const ReceiptOcrValidationResult.rejected({
    required ReceiptOcrFailureReason reason,
    required String message,
    String? storeName,
    DateTime? purchasedAt,
    int? amount,
    double storeNameSimilarity = 0,
  }) : this._(
         decision: ReceiptOcrDecision.rejected,
         failureReason: reason,
         message: message,
         storeName: storeName,
         purchasedAt: purchasedAt,
         amount: amount,
         storeNameSimilarity: storeNameSimilarity,
       );
}

abstract interface class ReceiptTextRecognizer {
  Future<String> recognizeText(String imagePath);
}

class ReceiptOcrChecker {
  final ReceiptTextRecognizer recognizer;
  final ReceiptOcrValidator validator;

  const ReceiptOcrChecker({
    required this.recognizer,
    this.validator = const ReceiptOcrValidator(),
  });

  Future<ReceiptOcrValidationResult> check({
    required String imagePath,
    required String expectedStoreName,
    DateTime? now,
  }) async {
    try {
      final rawText = await recognizer.recognizeText(imagePath);
      return validator.validate(
        rawText: rawText,
        expectedStoreName: expectedStoreName,
        now: now,
      );
    } catch (_) {
      return const ReceiptOcrValidationResult.retry(
        reason: ReceiptOcrFailureReason.recognitionError,
        message: '영수증 인식에 실패했습니다. 다시 촬영해 주세요.',
      );
    }
  }
}

class ReceiptOcrValidator {
  final Duration maxReceiptAge;
  final Duration futureTolerance;
  final double storeNameThreshold;

  const ReceiptOcrValidator({
    this.maxReceiptAge = const Duration(hours: 6),
    this.futureTolerance = const Duration(minutes: 5),
    this.storeNameThreshold = 0.72,
  });

  ReceiptOcrValidationResult validate({
    required String rawText,
    required String expectedStoreName,
    DateTime? now,
  }) {
    final trimmedText = rawText.trim();
    if (trimmedText.isEmpty) {
      return const ReceiptOcrValidationResult.retry(
        reason: ReceiptOcrFailureReason.emptyText,
        message: '영수증 내용을 읽지 못했습니다. 다시 촬영해 주세요.',
      );
    }

    final expectedNormalized = _normalize(expectedStoreName);
    if (expectedNormalized.isEmpty) {
      return const ReceiptOcrValidationResult.retry(
        reason: ReceiptOcrFailureReason.storeNameNotFound,
        message: '인증할 업체 정보를 확인하지 못했습니다. 다시 시도해 주세요.',
      );
    }

    final storeMatch = _findBestStoreMatch(
      rawText: trimmedText,
      expectedNormalized: expectedNormalized,
    );

    if (storeMatch == null) {
      return const ReceiptOcrValidationResult.retry(
        reason: ReceiptOcrFailureReason.storeNameNotFound,
        message: '영수증에서 상호명을 읽지 못했습니다. 다시 촬영해 주세요.',
      );
    }

    if (storeMatch.similarity < storeNameThreshold) {
      return ReceiptOcrValidationResult.rejected(
        reason: ReceiptOcrFailureReason.storeNameMismatch,
        message: '선택한 업체와 영수증의 상호명이 일치하지 않습니다.',
        storeName: storeMatch.originalLine,
        storeNameSimilarity: storeMatch.similarity,
      );
    }

    final purchasedAt = _extractPurchaseDateTime(trimmedText);
    if (purchasedAt == null) {
      return const ReceiptOcrValidationResult.retry(
        reason: ReceiptOcrFailureReason.purchaseDateTimeNotFound,
        message: '영수증에서 결제 일시를 읽지 못했습니다. 다시 촬영해 주세요.',
      );
    }

    final currentTime = now ?? DateTime.now();
    if (purchasedAt.isAfter(currentTime.add(futureTolerance))) {
      return ReceiptOcrValidationResult.rejected(
        reason: ReceiptOcrFailureReason.futureDatedReceipt,
        message: '결제 시간이 현재 시간보다 이후로 확인됩니다.',
        storeName: storeMatch.originalLine,
        purchasedAt: purchasedAt,
        amount: _extractAmount(trimmedText),
        storeNameSimilarity: storeMatch.similarity,
      );
    }

    if (currentTime.difference(purchasedAt) > maxReceiptAge) {
      return ReceiptOcrValidationResult.rejected(
        reason: ReceiptOcrFailureReason.receiptExpired,
        message: '인증 가능한 시간이 지난 영수증입니다.',
        storeName: storeMatch.originalLine,
        purchasedAt: purchasedAt,
        amount: _extractAmount(trimmedText),
        storeNameSimilarity: storeMatch.similarity,
      );
    }

    return ReceiptOcrValidationResult.approved(
      storeName: storeMatch.originalLine,
      purchasedAt: purchasedAt,
      amount: _extractAmount(trimmedText),
      storeNameSimilarity: storeMatch.similarity,
    );
  }

  _StoreMatch? _findBestStoreMatch({
    required String rawText,
    required String expectedNormalized,
  }) {
    _StoreMatch? bestMatch;
    final lines = rawText
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty);

    for (final line in lines) {
      final normalizedLine = _normalize(line);
      if (normalizedLine.isEmpty || !_containsLetter(normalizedLine)) continue;

      final similarity = _storeSimilarity(expectedNormalized, normalizedLine);
      if (bestMatch == null || similarity > bestMatch.similarity) {
        bestMatch = _StoreMatch(originalLine: line, similarity: similarity);
      }
    }

    return bestMatch;
  }

  DateTime? _extractPurchaseDateTime(String rawText) {
    final prioritizedLines = rawText
        .split(RegExp(r'[\r\n]+'))
        .where((line) => RegExp(r'결제|거래|승인|일시|날짜').hasMatch(line))
        .join('\n');

    return _parseDateTime(prioritizedLines) ?? _parseDateTime(rawText);
  }

  DateTime? _parseDateTime(String text) {
    final dateMatch = RegExp(
      r'(\d{2,4})\s*(?:년|[.\/-])\s*(\d{1,2})\s*(?:월|[.\/-])\s*(\d{1,2})\s*일?',
    ).firstMatch(text);
    final timeMatch = RegExp(
      r'(오전|오후|AM|PM)?\s*(\d{1,2})\s*(?::|시)\s*(\d{1,2})(?:\s*(?::|분)\s*(\d{1,2}))?',
      caseSensitive: false,
    ).firstMatch(text);

    if (dateMatch == null || timeMatch == null) return null;

    var year = int.parse(dateMatch.group(1)!);
    if (year < 100) year += 2000;

    final month = int.parse(dateMatch.group(2)!);
    final day = int.parse(dateMatch.group(3)!);
    var hour = int.parse(timeMatch.group(2)!);
    final minute = int.parse(timeMatch.group(3)!);
    final second = int.tryParse(timeMatch.group(4) ?? '') ?? 0;
    final marker = timeMatch.group(1)?.toUpperCase();

    if ((marker == '오후' || marker == 'PM') && hour < 12) hour += 12;
    if ((marker == '오전' || marker == 'AM') && hour == 12) hour = 0;

    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    if (second < 0 || second > 59) return null;

    final parsed = DateTime(year, month, day, hour, minute, second);
    if (parsed.year != year ||
        parsed.month != month ||
        parsed.day != day ||
        parsed.hour != hour ||
        parsed.minute != minute ||
        parsed.second != second) {
      return null;
    }

    return parsed;
  }

  int? _extractAmount(String rawText) {
    final match = RegExp(
      r'(?:합계|총액|결제금액|받을금액|카드결제)\s*[:：]?\s*[₩￦]?\s*([0-9][0-9,]*)\s*원?',
    ).firstMatch(rawText);
    if (match == null) return null;

    return int.tryParse(match.group(1)!.replaceAll(',', ''));
  }

  double _storeSimilarity(String expected, String actual) {
    if (expected == actual) return 1;
    if (actual.contains(expected)) return 1;
    if (expected.length >= 3 && expected.contains(actual)) return 0.9;
    return _diceCoefficient(expected, actual);
  }

  double _diceCoefficient(String left, String right) {
    if (left == right) return 1;
    if (left.length < 2 || right.length < 2) return 0;

    final leftPairs = <String, int>{};
    for (var index = 0; index < left.length - 1; index++) {
      final pair = left.substring(index, index + 2);
      leftPairs[pair] = (leftPairs[pair] ?? 0) + 1;
    }

    var intersection = 0;
    for (var index = 0; index < right.length - 1; index++) {
      final pair = right.substring(index, index + 2);
      final count = leftPairs[pair] ?? 0;
      if (count > 0) {
        intersection++;
        leftPairs[pair] = count - 1;
      }
    }

    return (2 * intersection) / (left.length + right.length - 2);
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^0-9a-z가-힣]'), '');
  }

  bool _containsLetter(String value) {
    return RegExp(r'[a-z가-힣]').hasMatch(value);
  }
}

class _StoreMatch {
  final String originalLine;
  final double similarity;

  const _StoreMatch({required this.originalLine, required this.similarity});
}
