import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// [imageFile]을 스토리지의 [folderName]/[fileName] 경로에 업로드하고,
  /// 업로드가 완료되면 그 이미지에 접근할 수 있는 다운로드 URL(웹 주소)을 반환합니다.
  static Future<String?> uploadImage({
    required File imageFile,
    required String folderName,
    required String fileName,
  }) async {
    try {
      // 1. 스토리지 내 저장할 참조(경로) 설정
      final ref = _storage.ref().child(folderName).child(fileName);

      // 2. 파일 업로드 실행
      final uploadTask = await ref.putFile(imageFile);

      // 3. 업로드 완료 후 다운로드 주소(URL) 획득
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl; // 예: https://firebasestorage.googleapis.com/...
    } catch (e) {
      print("스토리지 업로드 에러 발생: $e");
      return null;
    }
  }
}