/// 이모티콘 하나를 본문 텍스트에 표시하기 위한 토큰.
/// productId : emoticon 컬렉션 문서 id (구매 단위 = 상품/팩)
/// itemId    : 상품 안 개별 이모티콘의 itemId (EmoticonItem.itemId)
class EmoticonToken {
  final String productId;
  final String itemId;

  const EmoticonToken(this.productId, this.itemId);

  String toText() => '[emoji:$productId:$itemId]';

  static final RegExp pattern =
  RegExp(r'\[emoji:([a-zA-Z0-9_\-]+):([a-zA-Z0-9_\-]+)\]');
}