class CourseData {
  final String id;
  final String title;
  final String description;
  final int placeCount;
  final int stampCount;
  final String region;
  final String category;
  final bool isCompleted;

  const CourseData({
    required this.id,
    required this.title,
    required this.description,
    required this.placeCount,
    required this.stampCount,
    required this.region,
    required this.category,
    required this.isCompleted,
  });
}

// 🆕 1. [지역별 탭 전용] 전국 지역 탐방 중심의 코스 테마 목록
final List<CourseData> regionCourses = [
  const CourseData(
    id: 'course_r1',
    title: '성수동 소금빵 투어',
    description: '베이커리 4개',
    placeCount: 4,
    stampCount: 120,
    region: '서울',
    category: '빵/도넛',
    isCompleted: true,
  ),
  const CourseData(
    id: 'course_r2',
    title: '망리단길 카페 투어',
    description: '카페 5개',
    placeCount: 5,
    stampCount: 45,
    region: '서울',
    category: '커피/차(카페)',
    isCompleted: false,
  ),
  const CourseData(
    id: 'course_r3',
    title: '수원 행궁동 구움과자 정복',
    description: '디저트 카페 3개',
    placeCount: 3,
    stampCount: 320,
    region: '경기',
    category: '빵/도넛',
    isCompleted: true,
  ),
  const CourseData(
    id: 'course_r4',
    title: '구월동 시그니처 타르트 투어',
    description: '베이커리 4개',
    placeCount: 4,
    stampCount: 85,
    region: '인천',
    category: '빵/도넛',
    isCompleted: false,
  ),
  const CourseData(
    id: 'course_r5',
    title: '속초 중앙시장 샌드 탐방',
    description: '디저트 카페 2개',
    placeCount: 2,
    stampCount: 155,
    region: '강원',
    category: '토스트/샌드위치/샐러드',
    isCompleted: true,
  ),
  const CourseData(
    id: 'course_r6',
    title: '여수 밤바다 카페 원정대',
    description: '오션뷰 카페 5개',
    placeCount: 5,
    stampCount: 190,
    region: '전남',
    category: '커피/차(카페)',
    isCompleted: true,
  ),
  const CourseData(
    id: 'course_r7',
    title: '제주 애월 한라봉 디저트',
    description: '오션뷰 베이커리 6개',
    placeCount: 6,
    stampCount: 410,
    region: '제주',
    category: '빵/도넛',
    isCompleted: false,
  ),
];

// 🆕 2. [메뉴별 탭 전용] 특정 메뉴 카테고리에 집중된 정통 전문 투어 코스 목록
final List<CourseData> menuCourses = [
  const CourseData(
    id: 'course_m1',
    title: '전국 스페셜티 핸드드립 투어',
    description: '바리스타 챔피언 카페 5개',
    placeCount: 5,
    stampCount: 290,
    region: '서울',
    category: '커피/차(카페)',
    isCompleted: false,
  ),
  const CourseData(
    id: 'course_m2',
    title: '쫀득 달달 개성주악 투어',
    description: '개성주악 전문점 4개',
    placeCount: 4,
    stampCount: 180,
    region: '서울',
    category: '떡/한과',
    isCompleted: true,
  ),
  const CourseData(
    id: 'course_m3',
    title: '천상의 맛 카이막 빵지순례',
    description: '카이막 베이커리 3개',
    placeCount: 3,
    stampCount: 350,
    region: '경기',
    category: '빵/도넛',
    isCompleted: true,
  ),
  const CourseData(
    id: 'course_m4',
    title: '생딸기 설빙 & 망고 눈꽃빙수',
    description: '빙수 전문점 3개',
    placeCount: 3,
    stampCount: 120,
    region: '대구',
    category: '아이스크림/빙수',
    isCompleted: false,
  ),
  const CourseData(
    id: 'course_m5',
    title: '유기농 수제 호밀 샌드위치',
    description: '건강 샌드위치 숍 4개',
    placeCount: 4,
    stampCount: 220,
    region: '부산',
    category: '토스트/샌드위치/샐러드',
    isCompleted: true,
  ),
  const CourseData(
    id: 'course_m6',
    title: '인절미 크림 퓨전 한과 로드',
    description: '퓨전 떡카페 3개',
    placeCount: 3,
    stampCount: 130,
    region: '강원',
    category: '떡/한과',
    isCompleted: false,
  ),
  const CourseData(
    id: 'course_m7',
    title: '말차 전문 아인슈페너 정복',
    description: '말차 특화 카페 4개',
    placeCount: 4,
    stampCount: 95,
    region: '인천',
    category: '커피/차(카페)',
    isCompleted: false,
  ),
];