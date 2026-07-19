import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'receipt_ocr_checker.dart';

/// ML Kit 한국어 모델로 영수증 이미지의 전체 텍스트를 추출한다.
///
/// 호출마다 recognizer를 닫아 네이티브 리소스가 남지 않게 한다.
class MlKitReceiptTextRecognizer implements ReceiptTextRecognizer {
  const MlKitReceiptTextRecognizer();

  @override
  Future<String> recognizeText(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.korean);

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await recognizer.processImage(inputImage);
      return recognizedText.text;
    } finally {
      await recognizer.close();
    }
  }
}
