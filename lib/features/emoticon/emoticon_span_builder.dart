import 'package:flutter/material.dart';
import 'emoticon_product_repository.dart';
import 'emoticon_token.dart';

/// 본문 안 [emoji:productId:itemId] 토큰을 실제 이미지로 그려주는 위젯.
/// 이미지 URL은 비동기로 가져오므로, 로딩 중엔 빈 자리를 두고 완료되면 교체합니다.
class EmoticonRichContent extends StatelessWidget {
  final String content;
  final TextStyle? style;
  final double emojiSize;
  final List<InlineSpan> leadingSpans; // 답글 대상 "@닉네임" 등 앞에 붙는 스팬

  const EmoticonRichContent({
    Key? key,
    required this.content,
    this.style,
    this.emojiSize = 18,
    this.leadingSpans = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final matches = EmoticonToken.pattern.allMatches(content).toList();
    final productIds = matches.map((m) => m.group(1)!).toSet();

    if (productIds.isEmpty) {
      return RichText(
        text: TextSpan(
          style: style ?? DefaultTextStyle.of(context).style,
          children: [...leadingSpans, TextSpan(text: content, style: style)],
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: EmoticonProductRepository.fetchProducts(productIds),
      builder: (context, snapshot) {
        final products = snapshot.data ?? const {};
        return RichText(
          text: TextSpan(
            style: style ?? DefaultTextStyle.of(context).style,
            children: [...leadingSpans, ..._buildSpans(matches, products)],
          ),
        );
      },
    );
  }

  List<InlineSpan> _buildSpans(List<RegExpMatch> matches, Map<String, dynamic> products) {
    final spans = <InlineSpan>[];
    int last = 0;

    for (final match in matches) {
      if (match.start > last) {
        spans.add(TextSpan(text: content.substring(last, match.start), style: style));
      }

      final productId = match.group(1)!;
      final itemId = match.group(2)!;
      final product = products[productId];
      String? imageUrl;
      if (product != null) {
        for (final item in product.items) {
          if (item.itemId == itemId) {
            imageUrl = item.imageUrl;
            break;
          }
        }
      }

      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: imageUrl == null
              ? SizedBox(width: emojiSize, height: emojiSize)
              : Image.network(
            imageUrl,
            width: emojiSize,
            height: emojiSize,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => SizedBox(width: emojiSize, height: emojiSize),
          ),
        ),
      ));
      last = match.end;
    }
    if (last < content.length) {
      spans.add(TextSpan(text: content.substring(last), style: style));
    }
    return spans;
  }
}