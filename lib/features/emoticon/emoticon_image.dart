import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 이모티콘 이미지를 그려주는 공용 위젯.
///
/// Firestore의 imageUrl 필드는 두 가지 형태를 모두 가질 수 있어요:
/// - "https://..." 형태의 Firebase Storage 다운로드 URL (실제 배포 이미지)
/// - "assets/emoticons/character/01_smile.svg" 형태의 로컬 에셋 경로 (테스트 데이터)
///
/// 그리고 확장자에 따라 렌더링 방식도 달라져야 해요:
/// - .svg → flutter_svg의 SvgPicture
/// - 그 외(png/jpg 등) → 기본 Image 위젯
///
/// 이 위젯이 imageUrl 값을 보고 알아서 올바른 방식으로 그려줍니다.
class EmoticonImage extends StatelessWidget {
  final String imageUrl;
  final double size;
  final BoxFit fit;

  const EmoticonImage({
    Key? key,
    required this.imageUrl,
    required this.size,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  bool get _isNetwork =>
      imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

  bool get _isSvg => imageUrl.toLowerCase().endsWith('.svg');

  Widget get _placeholder => SizedBox(width: size, height: size);

  Widget get _errorIcon => Icon(
    Icons.image_not_supported_outlined,
    size: size * 0.7,
    color: Colors.grey,
  );

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return _placeholder;

    if (_isSvg) {
      return _isNetwork
          ? SvgPicture.network(
        imageUrl,
        width: size,
        height: size,
        fit: fit,
        placeholderBuilder: (_) => _placeholder,
        errorBuilder: (_, __, ___) => _errorIcon,
      )
          : SvgPicture.asset(
        imageUrl,
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (_, __, ___) => _errorIcon,
      );
    }

    return _isNetwork
        ? Image.network(
      imageUrl,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (_, __, ___) => _errorIcon,
    )
        : Image.asset(
      imageUrl,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (_, __, ___) => _errorIcon,
    );
  }
}