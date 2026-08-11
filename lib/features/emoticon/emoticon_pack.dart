class EmoticonPack {
  final String id;
  final String name;
  final String coverAsset;
  final int price;
  final int emoticonCount; // 팩 안에 들어있는 이모티콘 개수

  const EmoticonPack({
    required this.id,
    required this.name,
    required this.coverAsset,
    required this.price,
    required this.emoticonCount,
  });

  // assets/emoticons/{id}/1.png ~ N.png 형태를 가정
  List<String> get emoticonAssets =>
      List.generate(emoticonCount, (i) => 'assets/emoticons/$id/${i + 1}.png');
}

// ⚠️ price, emoticonCount는 실제 값에 맞게 수정해주세요.
const List<EmoticonPack> kEmoticonPacks = [
  EmoticonPack(id: 'gomdeuli_namnam', name: '곰돌이 남남팩', coverAsset: 'assets/emoticons/gomdeuli_namnam/cover.png', price: 1500, emoticonCount: 16),
  EmoticonPack(id: 'gureum_mongsil', name: '구름 몽실팩', coverAsset: 'assets/emoticons/gureum_mongsil/cover.png', price: 1500, emoticonCount: 16),
  EmoticonPack(id: 'jjinten', name: '찐텐 이모지팩', coverAsset: 'assets/emoticons/jjinten/cover.png', price: 1500, emoticonCount: 16),
  EmoticonPack(id: 'reaction_pokbal', name: '리액션 폭발팩', coverAsset: 'assets/emoticons/reaction_pokbal/cover.png', price: 1500, emoticonCount: 16),
  EmoticonPack(id: 'penguin_dwidung', name: '펭귄 뒤뚱팩', coverAsset: 'assets/emoticons/penguin_dwidung/cover.png', price: 1500, emoticonCount: 16),
];