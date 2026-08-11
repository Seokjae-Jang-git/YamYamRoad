import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'emoticon_image.dart';
import 'emoticon_product_repository.dart';
import 'emoticon_token.dart';

/// [emoji:productId:itemId] 토큰을 ExtendedTextField 입력창 "안에서" 바로
/// 이미지로 그려주는 SpecialText. (일반 TextField에서는 동작하지 않고,
/// 반드시 ExtendedTextField + specialTextSpanBuilder와 함께 써야 합니다)
class EmoticonSpecialText extends SpecialText {
  static const String flag = '[emoji:';
  final double emojiSize;

  EmoticonSpecialText({
    required this.emojiSize,
    TextStyle? textStyle,
    SpecialTextGestureTapCallback? onTap,
  }) : super(flag, ']', textStyle, onTap: onTap);

  @override
  bool isEnd(String value) => value == endFlag;

  @override
  InlineSpan finishText() {
    final text = toString(); // 예: "[emoji:emo_character_test:01_smile.svg]"
    final match = EmoticonToken.pattern.firstMatch(text);

    // 패턴에 안 맞는 이상한 텍스트면 그냥 원문 그대로 보여줍니다.
    if (match == null) {
      return TextSpan(text: text, style: textStyle);
    }

    final productId = match.group(1)!;
    final itemId = match.group(2)!;

    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: _EmoticonTokenImage(
        productId: productId,
        itemId: itemId,
        size: emojiSize,
      ),
    );
  }
}

/// 토큰의 productId/itemId로 실제 이미지 URL을 찾아서 그려주는 내부 위젯.
/// EmoticonProductRepository가 이미 캐싱을 해주므로, 같은 상품을 여러 번
/// 참조해도 Firestore를 반복해서 읽지 않습니다.
class _EmoticonTokenImage extends StatelessWidget {
  final String productId;
  final String itemId;
  final double size;

  const _EmoticonTokenImage({
    required this.productId,
    required this.itemId,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: EmoticonProductRepository.fetchProducts([productId]),
      builder: (context, snapshot) {
        final product = snapshot.data?[productId];
        String? imageUrl;
        if (product != null) {
          for (final item in product.items) {
            if (item.itemId == itemId) {
              imageUrl = item.imageUrl;
              break;
            }
          }
        }
        if (imageUrl == null) {
          return SizedBox(width: size, height: size);
        }
        return EmoticonImage(imageUrl: imageUrl, size: size);
      },
    );
  }
}

/// ExtendedTextField의 `specialTextSpanBuilder`에 넘겨줄 빌더.
/// 이모티콘 토큰이 아닌 나머지 일반 텍스트는 그대로 둡니다.
class EmoticonSpecialTextSpanBuilder extends SpecialTextSpanBuilder {
  final double emojiSize;

  EmoticonSpecialTextSpanBuilder({this.emojiSize = 22});

  @override
  SpecialText? createSpecialText(
      String flag, {
        TextStyle? textStyle,
        SpecialTextGestureTapCallback? onTap,
        required int index,
      }) {
    if (flag.isEmpty) return null;

    if (isStart(flag, EmoticonSpecialText.flag)) {
      return EmoticonSpecialText(
        emojiSize: emojiSize,
        textStyle: textStyle,
        onTap: onTap,
      );
    }
    return null;
  }
}
