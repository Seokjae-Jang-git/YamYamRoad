import 'package:flutter/services.dart';
import 'emoticon_token.dart';

/// 이모티콘 토큰([emoji:productId:itemId])이 부분적으로 잘리지 않도록
/// 지켜주는 TextInputFormatter.
///
/// 🌟 예전에는 커스텀 TextEditingController에서 `value` setter를 가로채서
/// "직전 값"을 스스로 추적했는데, 그 "직전 값"이 실제로 위젯이 마지막으로
/// 반영한 값과 항상 일치한다는 보장이 없었습니다 (기기/키보드에 따라 탭+타이핑이
/// 배치로 들어오거나, 조합 입력 중간 상태가 끼는 등). 그래서 커서 위치를
/// 아무리 정교하게 추정해도 가끔 엉뚱한 위치가 편집되는 문제가 계속 생겼습니다.
///
/// TextInputFormatter.formatEditUpdate(oldValue, newValue)는 다릅니다 —
/// 여기 넘어오는 oldValue는 프레임워크가 "바로 직전에 실제로 반영됐던 값"임을
/// 보장해주는 공식 API라서, 더 이상 추측할 필요가 없습니다. 이 값 기준으로
/// 정확히 어디가 바뀌었는지 계산하기 때문에, 이모티콘 토큰 사이에 새 내용을
/// 넣거나 지우는 것도 정확한 경계로 처리됩니다.
class EmoticonTokenGuardFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final oldText = oldValue.text;
    final newText = newValue.text;

    // 텍스트가 그대로면 순수 커서 이동/선택일 뿐이므로 건드리지 않습니다.
    if (newText == oldText) {
      return newValue;
    }

    final oldLen = oldText.length;
    final newLen = newText.length;
    final minLen = oldLen < newLen ? oldLen : newLen;

    // 앞/뒤에서부터 같은 문자가 이어지는 최대 길이를 구합니다. 같은 이모티콘
    // 팩 토큰들처럼 문자열이 거의 겹치는 경우를 대비해, 아래에서 old/new
    // selection으로 한 번 더 상한선을 둡니다.
    int prefixMax = 0;
    while (prefixMax < minLen && oldText[prefixMax] == newText[prefixMax]) {
      prefixMax++;
    }
    int suffixMax = 0;
    final maxSuffixByLen = minLen - prefixMax;
    while (suffixMax < maxSuffixByLen &&
        oldText[oldLen - 1 - suffixMax] == newText[newLen - 1 - suffixMax]) {
      suffixMax++;
    }

    int prefix = prefixMax;
    int suffix = suffixMax;

    // oldValue.selection은 이제 프레임워크가 보장하는 "진짜 직전" 커서라
    // 안심하고 상한선으로 쓸 수 있습니다.
    final oldSelection = oldValue.selection;
    if (oldSelection.isValid) {
      final selStart =
      oldSelection.start < oldSelection.end ? oldSelection.start : oldSelection.end;
      final selEnd =
      oldSelection.start < oldSelection.end ? oldSelection.end : oldSelection.start;
      final anchorStart = selStart.clamp(0, oldLen);
      final anchorEnd = selEnd.clamp(0, oldLen);

      if (anchorStart < prefix) prefix = anchorStart;
      final maxSuffixByOldAnchor = oldLen - anchorEnd;
      if (maxSuffixByOldAnchor < suffix) suffix = maxSuffixByOldAnchor;
    }

    // newValue.selection(편집 직후 커서)도 보조 상한선으로 같이 씁니다 —
    // 붙여넣기처럼 선택 영역이 통째로 바뀌는 경우까지 커버하기 위함입니다.
    final newSelection = newValue.selection;
    if (newSelection.isValid && newSelection.start == newSelection.end) {
      final cursor = newSelection.start.clamp(0, newLen);
      final lengthDiff = newLen - oldLen;
      final insertedLen = lengthDiff > 0 ? lengthDiff : 0;

      final prefixCap = cursor - insertedLen;
      if (prefixCap >= 0 && prefixCap < prefix) prefix = prefixCap;

      final suffixCap = newLen - cursor;
      if (suffixCap >= 0 && suffixCap < suffix) suffix = suffixCap;
    }

    if (prefix + suffix > minLen) {
      suffix = minLen - prefix;
      if (suffix < 0) {
        prefix = minLen;
        suffix = 0;
      }
    }

    final changedOldStart = prefix;
    final changedOldEnd = oldLen - suffix;
    final replacement = newText.substring(prefix, newLen - suffix);

    return _applyTokenGuard(
      oldText: oldText,
      changedOldStart: changedOldStart,
      changedOldEnd: changedOldEnd,
      replacement: replacement,
      fallbackValue: newValue,
    );
  }

  /// 확정된 변경 구간이 토큰 일부만 건드리면 토큰 전체를 포함하도록 넓힌 뒤,
  /// 넓어진 구간 기준으로 텍스트를 재구성합니다. 토큰과 무관한 편집(이모티콘
  /// 사이/바깥의 일반적인 삽입·삭제 포함)은 그대로 통과시킵니다.
  TextEditingValue _applyTokenGuard({
    required String oldText,
    required int changedOldStart,
    required int changedOldEnd,
    required String replacement,
    required TextEditingValue fallbackValue,
  }) {
    final oldMatches = EmoticonToken.pattern.allMatches(oldText).toList();

    var expandedStart = changedOldStart;
    var expandedEnd = changedOldEnd;

    bool expanded = true;
    while (expanded) {
      expanded = false;
      for (final m in oldMatches) {
        final overlaps = expandedStart < m.end && expandedEnd > m.start;
        final wholeTokenAlreadyIncluded = expandedStart <= m.start && expandedEnd >= m.end;
        if (overlaps && !wholeTokenAlreadyIncluded) {
          if (m.start < expandedStart) {
            expandedStart = m.start;
            expanded = true;
          }
          if (m.end > expandedEnd) {
            expandedEnd = m.end;
            expanded = true;
          }
        }
      }
    }

    if (expandedStart == changedOldStart && expandedEnd == changedOldEnd) {
      // 토큰을 건드리지 않는 정상적인 편집(이모티콘 사이 편집 포함)이므로
      // 그대로 통과시킵니다.
      return fallbackValue;
    }

    final correctedText =
        oldText.substring(0, expandedStart) + replacement + oldText.substring(expandedEnd);
    final newCursor = expandedStart + replacement.length;

    return TextEditingValue(
      text: correctedText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
  }
}
