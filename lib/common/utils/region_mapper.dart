class RegionMapper {
  /// 지역 축약어와 정식 명칭 간의 매핑 테이블
  static const Map<String, List<String>> _regionAliases = {
    '서울': ['서울', '서울특별시'],
    '경기': ['경기', '경기도'],
    '인천': ['인천', '인천광역시'],
    '강원': ['강원', '강원특별자치도', '강원도'],
    '세종': ['세종', '세종특별자치시'],
    '대전': ['대전', '대전광역시'],
    '충북': ['충북', '충청북도'],
    '충남': ['충남', '충청남도'],
    '광주': ['광주', '광주광역시'],
    '전북': ['전북', '전라북도', '전북특별자치도'],
    '전남': ['전남', '전라남도'],
    '부산': ['부산', '부산광역시'],
    '대구': ['대구', '대구광역시'],
    '울산': ['울산', '울산광역시'],
    '경북': ['경북', '경상북도'],
    '경남': ['경남', '경상남도'],
    '제주': ['제주', '제주특별자치도', '제주도'],
  };

  /// [selectedRegion]: 칩에서 선택한 지역명 (예: '충북', '경남', '전체')
  /// [targetText]: 검사할 데이터 텍스트 (예: '충청북도 청주시...', '충북 디저트 탐방')
  ///
  /// 선택된 지역의 축약어/풀네임 중 하나라도 targetText에 포함되어 있으면 true를 반환합니다.
  static bool isMatch({
    required String selectedRegion,
    required String targetText,
  }) {
    // '전체'이거나 empty일 경우 모든 데이터 통과
    if (selectedRegion == '전체' || selectedRegion.trim().isEmpty) {
      return true;
    }

    if (targetText.trim().isEmpty) {
      return false;
    }

    // 매핑 테이블에 등록된 지역인 경우, 연관 키워드(축약어, 풀네임 등) 중 하나라도 포함되는지 검사
    final aliases = _regionAliases[selectedRegion];
    if (aliases != null) {
      return aliases.any((alias) => targetText.contains(alias));
    }

    // 매핑 테이블에 없는 기타 지역은 단순 문자열 포함 여부 검사
    return targetText.contains(selectedRegion);
  }
}