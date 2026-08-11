import 'package:flutter/material.dart';

/// 스크린샷(문의하기 화면)에서 추출한 공통 컬러 팔레트
class AppColors {
  AppColors._();

  static const background = Color(0xFFFBF6EC); // 크림색 배경
  static const cardBackground = Color(0xFFFFFFFF);
  static const primary = Color(0xFFF4934A); // 메인 오렌지
  static const primaryLight = Color(0xFFFCE6D3);

  static const textPrimary = Color(0xFF2B2B2B);
  static const textSecondary = Color(0xFF8B8B8B);
  static const hint = Color(0xFFBBBBBB);

  static const border = Color(0xFFE7E0D3);
  static const success = Color(0xFFF4934A);

  static const statusPendingBg = Color(0xFFF1F1F1);
  static const statusPendingText = Color(0xFF8B8B8B);
  static const statusAnsweredBg = Color(0xFFFCE6D3);
  static const statusAnsweredText = Color(0xFFF4934A);
}
