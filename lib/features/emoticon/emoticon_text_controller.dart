import 'package:flutter/material.dart';
import 'emoticon_image.dart';
import 'emoticon_product_repository.dart';
import 'emoticon_token.dart';

/// 입력창에 [emoji:productId:itemId] 토큰 대신 실제 이모티콘 이미지가
/// 인라인으로 보이게 해주는 컨트롤러.
///
/// imageUrl은 네트워크 URL일 수도, "assets/..." 로컬 asset 경로일 수도,
/// SVG일 수도 있어서 직접 Image/NetworkImage로 그리지 않고
/// 피커/본문 렌더링과 동일한 EmoticonImage 위젯을 그대로 재사용합니다.
///
/// - 피커에서 고른 직후에는 cacheToken()으로 즉시 등록 (네트워크 재조회 없음)
/// - 수정 모드로 기존 글을 불러올 때는 warmUpCache()로 누락분만 채움
class EmoticonTextEditingController extends TextEditingController {
  final Map<String, String> _cache = {};

  EmoticonTextEditingController({String? text}) : super(text: text);

  void cacheToken(String token, String imageUrl) {
    _cache[token] = imageUrl;
  }

  /// 캐시에 없는 토큰만 조회해서 채운다. 새로 채운 게 있으면 true.
  Future<bool> warmUpCache() async {
    final matches = EmoticonToken.pattern.allMatches(text).toList();
    final missing = matches.where((m) => !_cache.containsKey(m.group(0))).toList();
    if (missing.isEmpty) return false;

    final productIds = missing.map((m) => m.group(1)!).toSet();
    final products = await EmoticonProductRepository.fetchProducts(productIds);

    bool updated = false;
    for (final m in missing) {
      final product = products[m.group(1)!];
      if (product == null) continue;
      for (final item in product.items) {
        if (item.itemId == m.group(2)) {
          _cache[m.group(0)!] = item.imageUrl;
          updated = true;
          break;
        }
      }
    }
    return updated;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final matches = EmoticonToken.pattern.allMatches(text).toList();
    if (matches.isEmpty) return TextSpan(style: style, text: text);

    final size = (style?.fontSize ?? 14) * 1.3;
    final spans = <InlineSpan>[];
    int last = 0;

    for (final m in matches) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start), style: style));
      }
      final imageUrl = _cache[m.group(0)!];
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: imageUrl != null
            ? EmoticonImage(imageUrl: imageUrl, size: size)
            : _placeholder(size),
      ));
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last), style: style));
    }
    return TextSpan(style: style, children: spans);
  }

  Widget _placeholder(double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(4),
    ),
  );
}