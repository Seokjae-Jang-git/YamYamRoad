import 'package:flutter/material.dart';
import 'emoticon_image.dart';
import 'emoticon_product_repository.dart';
import 'emoticon_token.dart';

class _EmoticonEntry {
  final String token; // 저장용 원본 토큰 텍스트, 예: [emoji:productId:itemId]
  final String imageUrl;

  const _EmoticonEntry(this.token, this.imageUrl);
}

/// 🌟 이모티콘을 인라인 이미지로 보여주는 컨트롤러.
///
/// 예전에는 실제 텍스트 버퍼에 `[emoji:productId:itemId]` 같은 긴 토큰
/// 문자열을 그대로 두고, 화면에 그릴 때만 buildTextSpan에서 WidgetSpan
/// 이미지 1개로 "압축"해서 보여줬습니다. 문제는 Flutter가 탭 위치 → 커서
/// 위치를 계산할 때 "화면에 그려진 구조"(이미지=1글자) 기준으로 계산하는데,
/// 실제 편집(삽입/삭제)은 "진짜 텍스트 버퍼"(토큰 원문 그대로, 수십 글자)
/// 기준으로 일어난다는 점이었습니다. 그래서 이모티콘을 하나라도 지나면
/// 화면 위치와 실제 편집 위치가 어긋났고, 아무리 diff 로직을 다듬어도
/// 구조적으로 고칠 수 없었습니다.
///
/// 지금은 실제 텍스트 버퍼에도 "글자 1개짜리 플레이스홀더"만 넣습니다.
/// 화면 위치와 텍스트 위치가 항상 1:1로 일치하므로 커서/삽입/삭제가 표준
/// TextField 동작 그대로 정확하게 작동하고, 이모티콘은 "글자 1개"라서
/// 삭제할 때 항상 통째로 지워지고 절대 부분적으로 잘리지 않습니다.
/// 저장(Firestore)할 때만 [toStorageText]로 실제 토큰 문자열로 변환합니다.
class EmoticonTextEditingController extends TextEditingController {
  final Map<String, _EmoticonEntry> _placeholders = {};

  // Private Use Area(U+E000~U+F8FF)를 플레이스홀더 문자로 사용합니다.
  // 일반 텍스트/이모지와 절대 겹치지 않는 영역입니다.
  static const int _puaStart = 0xE000;
  static const int _puaEnd = 0xF8FF;
  int _nextCodeUnit = _puaStart;

  EmoticonTextEditingController({String? text}) : super(text: text);

  String _newPlaceholder() {
    final placeholder = String.fromCharCode(_nextCodeUnit);
    _nextCodeUnit = _nextCodeUnit >= _puaEnd ? _puaStart : _nextCodeUnit + 1;
    return placeholder;
  }

  /// 커서(선택 영역) 위치에 이모티콘 하나를 삽입합니다.
  /// [token]은 저장용 원본 텍스트("[emoji:productId:itemId]"),
  /// [imageUrl]은 바로 렌더링할 이미지 주소입니다.
  void insertEmoticon(String token, String imageUrl) {
    final placeholder = _newPlaceholder();
    _placeholders[placeholder] = _EmoticonEntry(token, imageUrl);

    final current = text;
    final sel = selection;
    final start = sel.start >= 0 ? sel.start : current.length;
    final end = sel.end >= 0 ? sel.end : current.length;
    final newText = current.replaceRange(start, end, placeholder);

    value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + placeholder.length),
    );
  }

  /// 저장돼 있던 본문(`storedContent`, 토큰 원문 포함)을 편집 가능한
  /// 플레이스홀더 형태로 변환하고, 필요한 이미지를 조회해서 채워둡니다.
  /// 수정 화면 진입 시(initState) 한 번 호출하세요.
  Future<void> loadStoredContent(String storedContent) async {
    final matches = EmoticonToken.pattern.allMatches(storedContent).toList();
    if (matches.isEmpty) {
      text = storedContent;
      return;
    }

    final productIds = matches.map((m) => m.group(1)!).toSet();
    final products = await EmoticonProductRepository.fetchProducts(productIds);

    final buffer = StringBuffer();
    int last = 0;
    for (final m in matches) {
      buffer.write(storedContent.substring(last, m.start));

      final token = m.group(0)!;
      String imageUrl = '';
      final product = products[m.group(1)!];
      if (product != null) {
        for (final item in product.items) {
          if (item.itemId == m.group(2)) {
            imageUrl = item.imageUrl;
            break;
          }
        }
      }

      final placeholder = _newPlaceholder();
      _placeholders[placeholder] = _EmoticonEntry(token, imageUrl);
      buffer.write(placeholder);
      last = m.end;
    }
    buffer.write(storedContent.substring(last));

    text = buffer.toString();
  }

  /// 현재 편집 중인(플레이스홀더 포함) 텍스트를 저장용 원본 토큰 문자열로
  /// 변환합니다. Firestore에 저장할 때 이 값을 쓰세요 (text 대신).
  String toStorageText() {
    final buffer = StringBuffer();
    for (final codeUnit in text.codeUnits) {
      final ch = String.fromCharCode(codeUnit);
      final entry = _placeholders[ch];
      buffer.write(entry != null ? entry.token : ch);
    }
    return buffer.toString();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (_placeholders.isEmpty) {
      return TextSpan(style: style, text: text);
    }

    final size = (style?.fontSize ?? 14) * 1.3;
    final spans = <InlineSpan>[];
    final buffer = StringBuffer();

    void flush() {
      if (buffer.isNotEmpty) {
        spans.add(TextSpan(text: buffer.toString(), style: style));
        buffer.clear();
      }
    }

    for (final codeUnit in text.codeUnits) {
      final ch = String.fromCharCode(codeUnit);
      final entry = _placeholders[ch];
      if (entry == null) {
        buffer.write(ch);
        continue;
      }
      flush();
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: entry.imageUrl.isNotEmpty
            ? EmoticonImage(imageUrl: entry.imageUrl, size: size)
            : _placeholder(size),
      ));
    }
    flush();

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
