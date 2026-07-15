class PlaceData {
  final String placeId;
  final String name;
  final double rating;
  final int stampCount; // 🍉 수박 스탬프 카운트
  final String distance;
  final int distanceValue; // 실시간 거리순 정렬을 위한 가상 미터(m) 값
  final String description;
  final double mapX; // 가상 지도상 가로 위치 비율 (0.0 ~ 1.0)
  final double mapY; // 가상 지도상 세로 위치 비율 (0.0 ~ 1.0)

  const PlaceData({
    required this.placeId,
    required this.name,
    required this.rating,
    required this.stampCount,
    required this.distance,
    required this.distanceValue,
    required this.description,
    required this.mapX,
    required this.mapY,
  });
}

// 얌얌로드 14대 전국구 코스들에 대응하는 가게 마스터 데이터베이스
final List<PlaceData> masterPlaces = [
  // 1. 성수동 소금빵 코스 매칭 가게들
  const PlaceData(
    placeId: 'place_s1_1',
    name: '성수 소금빵 팩토리',
    rating: 4.9,
    stampCount: 120,
    distance: '내 위치에서 850m',
    distanceValue: 850,
    description: '[인기] 🧂 버터 풍미 가득한 바삭한 유기농 소금빵',
    mapX: 0.3,
    mapY: 0.4,
  ),
  const PlaceData(
    placeId: 'place_s1_2',
    name: '온화 베이커리 성수',
    rating: 4.6,
    stampCount: 40,
    distance: '내 위치에서 1.1km',
    distanceValue: 1100,
    description: '🥯 매일 정해진 수량만 구워내는 특제 소금빵집',
    mapX: 0.5,
    mapY: 0.2,
  ),

  // 2. 망리단길 카페 코스 매칭 가게들
  const PlaceData(
    placeId: 'place_s2_1',
    name: '스페셜티 딥 망원',
    rating: 4.8,
    stampCount: 45,
    distance: '내 위치에서 2.4km',
    distanceValue: 2400,
    description: '[인기] ☕️ 드립 마스터가 내려주는 완벽한 싱글오리진 커피',
    mapX: 0.4,
    mapY: 0.6,
  ),
  const PlaceData(
    placeId: 'place_s2_2',
    name: '망원 홍차 찻집',
    rating: 4.4,
    stampCount: 20,
    distance: '내 위치에서 2.8km',
    distanceValue: 2800,
    description: '🍂 은은한 얼그레이 밀크티와 따뜻한 스콘의 환상 조화',
    mapX: 0.7,
    mapY: 0.5,
  ),

  // 3. 수원 행궁동 구움과자 코스 매칭 가게들
  const PlaceData(
    placeId: 'place_k1_1',
    name: '행궁 구움과점',
    rating: 4.7,
    stampCount: 320,
    distance: '내 위치에서 450m',
    distanceValue: 450,
    description: '[추천] 🍪 겉은 바삭하고 촉촉한 구운과자의 성지',
    mapX: 0.2,
    mapY: 0.5,
  ),
  const PlaceData(
    placeId: 'place_k1_2',
    name: '한글 쿠키 행궁',
    rating: 4.5,
    stampCount: 160,
    distance: '내 위치에서 600m',
    distanceValue: 600,
    description: '🎨 눈과 입이 모두 즐거운 이색 수제 아이싱 쿠키 전문점',
    mapX: 0.6,
    mapY: 0.3,
  ),

  // 4. 구월동 타르트 코스 매칭 가게들
  const PlaceData(
    placeId: 'place_i1_1',
    name: '구월 타르트 팩토리',
    rating: 4.5,
    stampCount: 85,
    distance: '내 위치에서 1.5km',
    distanceValue: 1500,
    description: '🥧 제철 생과일이 듬뿍 올라간 시그니처 과일 타르트',
    mapX: 0.3,
    mapY: 0.7,
  ),
  const PlaceData(
    placeId: 'place_i1_2',
    name: '멜로우 디저트 구월',
    rating: 4.2,
    stampCount: 40,
    distance: '내 위치에서 1.8km',
    distanceValue: 1800,
    description: '🍯 부드러운 수제 에그타르트의 달콤한 향기가 머무는 곳',
    mapX: 0.5,
    mapY: 0.8,
  ),

  // 5. 속초 샌드 코스 매칭 가게들
  const PlaceData(
    placeId: 'place_g1_1',
    name: '속초 오션 샌드위치',
    rating: 4.8,
    stampCount: 155,
    distance: '내 위치에서 300m',
    distanceValue: 300,
    description: '[인기] 🥪 신선한 속초 홍게살이 가득 찬 시그니처 게살 샌드',
    mapX: 0.35,
    mapY: 0.45,
  ),
  const PlaceData(
    placeId: 'place_g1_2',
    name: '중앙시장 설악 단풍빵',
    rating: 4.3,
    stampCount: 75,
    distance: '내 위치에서 500m',
    distanceValue: 500,
    description: '🍁 고소한 단풍 팥 앙금이 듬뿍 들어간 동글동글 앙금빵',
    mapX: 0.55,
    mapY: 0.65,
  ),

  // 6. 여수 밤바다 코스 매칭 가게들
  const PlaceData(
    placeId: 'place_j1_1',
    name: '여수 돌산 오션 카페',
    rating: 4.9,
    stampCount: 190,
    distance: '내 위치에서 400m',
    distanceValue: 400,
    description: '[추천] 🌊 여수 밤바다의 야경이 한눈에 보이는 명품 테라스',
    mapX: 0.2,
    mapY: 0.3,
  ),
  const PlaceData(
    placeId: 'place_j1_2',
    name: '낭만포차 밤바다 블렌딩',
    rating: 4.5,
    stampCount: 90,
    distance: '내 위치에서 650m',
    distanceValue: 650,
    description: '🌌 낭만적인 밤공기와 어우러지는 콜드브루 스페셜티',
    mapX: 0.6,
    mapY: 0.5,
  ),

  // 7. 제주 애월 코스 매칭 가게들
  const PlaceData(
    placeId: 'place_je1_1',
    name: '애월 한라봉 도넛',
    rating: 4.7,
    stampCount: 410,
    distance: '내 위치에서 2.1km',
    distanceValue: 2100,
    description: '[인기] 🍊 제주 청정 한라봉을 갈아 넣은 수제 필링 도넛',
    mapX: 0.3,
    mapY: 0.5,
  ),
  const PlaceData(
    placeId: 'place_je1_2',
    name: '제주 돌하르방 마카롱',
    rating: 4.6,
    stampCount: 200,
    distance: '내 위치에서 2.5km',
    distanceValue: 2500,
    description: '🗿 귀여운 하르방 모양의 쫀득한 쑥 말차 마카롱',
    mapX: 0.7,
    mapY: 0.4,
  ),

  // 8. 인사동 개성주악 코스 매칭 가게들
  const PlaceData(
    placeId: 'place_m2_1',
    name: '인사동 가온 한과',
    rating: 4.8,
    stampCount: 180,
    distance: '내 위치에서 1.2km',
    distanceValue: 1200,
    description: '🍯 바삭함과 부드러움이 살아있는 정통 유과와 수제 강정',
    mapX: 0.4,
    mapY: 0.3,
  ),
  const PlaceData(
    placeId: 'place_m2_2',
    name: '한옥 개성주악 정원',
    rating: 4.7,
    stampCount: 100,
    distance: '내 위치에서 1.5km',
    distanceValue: 1500,
    description: '[추천] 🪵 예스러운 한옥에서 맛보는 겉바속촉 조청 주악',
    mapX: 0.6,
    mapY: 0.5,
  ),

  // 9. 카이막 빵지순례 코스 매칭 가게들
  const PlaceData(
    placeId: 'place_m3_1',
    name: '터키 카이막 행궁동 본점',
    rating: 4.9,
    stampCount: 350,
    distance: '내 위치에서 700m',
    distanceValue: 700,
    description: '[인기] 🥛 물 건너온 정통 레시피로 매일 끓여내는 리얼 카이막',
    mapX: 0.25,
    mapY: 0.6,
  ),
  const PlaceData(
    placeId: 'place_m3_2',
    name: '판교 카이막 하우스',
    rating: 4.6,
    stampCount: 150,
    distance: '내 위치에서 3.5km',
    distanceValue: 3500,
    description: '🥖 화덕에서 갓 구운 피타 브레드와 카이막의 꿀조합',
    mapX: 0.65,
    mapY: 0.4,
  ),

  // 10. 동성로 딸기빙수 코스 매칭 가게들
  const PlaceData(
    placeId: 'place_m4_1',
    name: '동성로 눈꽃 빙수',
    rating: 4.7,
    stampCount: 120,
    distance: '내 위치에서 900m',
    distanceValue: 900,
    description: '🍧 부드러운 순수 우유 눈꽃 얼음과 단팥 가득 빙수',
    mapX: 0.45,
    mapY: 0.55,
  ),
  const PlaceData(
    placeId: 'place_m4_2',
    name: '대구 삼덕 생딸기 설빙',
    rating: 4.5,
    stampCount: 80,
    distance: '내 위치에서 1.1km',
    distanceValue: 1100,
    description: '[추천] 🍓 제철 생딸기가 산더미처럼 얹어진 시즌 핫 메뉴',
    mapX: 0.55,
    mapY: 0.35,
  ),

  // 11. 부산 수제 샌드위치 코스 매칭 가게들
  const PlaceData(
    placeId: 'place_m5_1',
    name: '해운대 수제 샌드위치 숍',
    rating: 4.9,
    stampCount: 220,
    distance: '내 위치에서 1.3km',
    distanceValue: 1300,
    description: '[인기] 🥗 신선한 생연어와 건강한 통밀 식빵의 만남',
    mapX: 0.3,
    mapY: 0.7,
  ),
  const PlaceData(
    placeId: 'place_m5_2',
    name: '서면 호밀빵 팩토리',
    rating: 4.4,
    stampCount: 140,
    distance: '내 위치에서 2.1km',
    distanceValue: 2100,
    description: '🍞 칼로리 부담 없이 맛있고 든든한 닭가슴살 아보카도 샌드',
    mapX: 0.6,
    mapY: 0.6,
  ),

  // 12. 강릉 인절미 코스 매칭 가게들
  const PlaceData(
    placeId: 'place_m6_1',
    name: '강릉 인절미 크림빵',
    rating: 4.8,
    stampCount: 130,
    distance: '내 위치에서 1.0km',
    distanceValue: 1000,
    description: '🍡 쫀득한 찹쌀떡과 부드러운 고소함 가득 콩가루 크림',
    mapX: 0.3,
    mapY: 0.4,
  ),
  const PlaceData(
    placeId: 'place_m6_2',
    name: '설악 퓨전 떡카페',
    rating: 4.3,
    stampCount: 60,
    distance: '내 위치에서 1.4km',
    distanceValue: 1400,
    description: '🍵 쑥을 갈아 넣은 와플과 달달한 인절미 쉐이크',
    mapX: 0.7,
    mapY: 0.5,
  ),

  // 13. 인천 말차 코스 매칭 가게들
  const PlaceData(
    placeId: 'place_m7_1',
    name: '송도 그린티 하우스',
    rating: 4.6,
    stampCount: 95,
    distance: '내 위치에서 2.0km',
    distanceValue: 2000,
    description: '[인기] 🍵 보성 유기농 진한 말차 크림이 흘러내리는 아인슈페너',
    mapX: 0.2,
    mapY: 0.6,
  ),
  const PlaceData(
    placeId: 'place_m7_2',
    name: '부평 말차 아인슈페너 전문점',
    rating: 4.5,
    stampCount: 50,
    distance: '내 위치에서 1.2km',
    distanceValue: 1200,
    description: '🍦 달콤 쌉싸름한 그린티 샷과 에스프레소의 환상 하모니',
    mapX: 0.8,
    mapY: 0.4,
  ),
];