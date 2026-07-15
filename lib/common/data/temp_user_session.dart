const String currentUserId = 'cherry_hunter_82'; // 🍒 디저트 탐험가 ID!

// 🆕 홈 화면의 시나리오 기반 가상 위치 데이터 세션 격리 수립
const String initialUserLocation = '인천광역시 강화군 강화읍';     // 앱 최초 구동 시 (이전 기록)
const String updatedUserLocation = '인천광역시 부평구 문화의거리'; // 재설정 버튼 터치 시 (실시간 보정)

// 가상 사용자가 실제로 도장을 깬(완료한) 가게 ID 목록 (Set 구조 활용)
final Set<String> completedPlaceIdsOfCurrentUser = {
  'place_s1_1',  // 성수 소금빵 팩토리 완료
  'place_k1_1',  // 행궁 구움과점 완료
  'place_g1_1',  // 속초 오션 샌드위치 완료
  'place_j1_1',  // 여수 돌산 오션 카페 완료
  'place_je1_1', // 애월 한라봉 도넛 완료
  'place_m2_1',  // 인사동 가온 한과 완료
  'place_m3_1',  // 터키 카이막 행궁동 본점 완료
};