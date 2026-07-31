import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

/// 숫자를 세 자리마다 쉼표(,)가 들어간 한국어 표기 형식으로 변환
String formatPointNumber(int value) =>
    NumberFormat.decimalPattern('ko_KR').format(value);

/// 네트워크/아셋 SVG 및 일반 이미지를 유연하게 처리하는 공통 상품 이미지 위젯
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.imageUrl,
    required this.icon,
  });

  final String? imageUrl;
  final IconData icon;

  static const Color subBrown = Color(0xFF7A6B63);

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) return _buildPlaceholder();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: _buildImage(url),
    );
  }

  Widget _buildImage(String url) {
    if (_isNetworkUrl(url)) {
      return _isSvgUrl(url)
          ? SvgPicture.network(
        url,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => _buildPlaceholder(),
      )
          : Image.network(
        url,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildPlaceholder(),
      );
    }

    return _isSvgUrl(url)
        ? SvgPicture.asset(
      url,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      placeholderBuilder: (_) => _buildPlaceholder(),
    )
        : Image.asset(
      url,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _buildPlaceholder(),
    );
  }

  bool _isNetworkUrl(String url) {
    final scheme = Uri.tryParse(url)?.scheme.toLowerCase();
    return scheme == 'http' || scheme == 'https';
  }

  bool _isSvgUrl(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
    return path.endsWith('.svg');
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF3EDE6),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 38, color: subBrown.withOpacity(0.5)),
    );
  }
}

/// StreamBuilder 및 비동기 데이터의 로딩/에러/빈 상태를 일관되게 처리하는 공통 래퍼
class AsyncContent<T extends List<Object>> extends StatelessWidget {
  const AsyncContent({
    super.key,
    required this.snapshot,
    required this.emptyMessage,
    required this.builder,
  });

  final AsyncSnapshot<T> snapshot;
  final String emptyMessage;
  final Widget Function(T data) builder;

  static const Color pointCoralRed = Color(0xFFFF6B57);

  @override
  Widget build(BuildContext context) {
    if (snapshot.hasError) {
      return const PageMessage(
        icon: Icons.error_outline,
        message: '상품 정보를 불러오지 못했습니다.',
      );
    }
    if (!snapshot.hasData) {
      return const Center(
        child: CircularProgressIndicator(color: pointCoralRed),
      );
    }
    if (snapshot.data!.isEmpty) {
      return PageMessage(
        icon: Icons.inventory_2_outlined,
        message: emptyMessage,
      );
    }
    return builder(snapshot.data as T);
  }
}

/// 데이터 없음 또는 에러 시 중앙에 안내 문구와 아이콘을 띄우는 위젯
class PageMessage extends StatelessWidget {
  const PageMessage({
    super.key,
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  static const Color subBrown = Color(0xFF7A6B63);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: subBrown.withOpacity(0.5)),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(color: subBrown)),
        ],
      ),
    );
  }
}