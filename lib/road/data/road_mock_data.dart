import 'package:cloud_firestore/cloud_firestore.dart';

class CourseData {
  final String id; // 문서 ID (유일한 필수 값)

  // 🌟 1. UI 더미 데이터 및 구형 스펙 필드들
  final int? stampCount;
  final String? category;
  final bool? isCompleted;
  final String? imageUrl;
  final String? region;
  final int? rewardPoints;

  // 🌟 2. 신형 DB 및 Road 클래스 일치 필드들
  final String? badgeName;
  final List<String>? categoryIds;
  final DateTime? createdAt;
  final String? description;
  final int? estimatedTimeMinutes;
  final int? placeCount;
  final List<String>? placeIds;
  final String? regionId;
  final String? title;
  final double? totalDistanceKm;
  final DateTime? updatedAt;
  final dynamic roadPlace;
  final String? thumbnailUrl;
  final int? stampRewardPoint;
  final List<String>? searchKeywords;
  final bool? isActive;

  const CourseData({
    required this.id, // id만 필수로 받습니다.

    // 1. UI 더미 데이터 및 구형 필드
    this.stampCount,
    this.category,
    this.isCompleted,
    this.imageUrl,
    this.region,
    this.rewardPoints,

    // 2. 신형 DB 및 Road 클래스 대응 필드
    this.badgeName,
    this.categoryIds,
    this.createdAt,
    this.description,
    this.estimatedTimeMinutes,
    this.placeCount,
    this.placeIds,
    this.regionId,
    this.title,
    this.totalDistanceKm,
    this.updatedAt,
    this.roadPlace,
    this.thumbnailUrl,
    this.stampRewardPoint,
    this.searchKeywords,
    this.isActive,
  });

  /// 🌟 3. Firestore 데이터를 안전하게 변환하는 팩토리 함수 (구/신형 DB 필드 이름 호환 처리)
  factory CourseData.fromMap(Map<String, dynamic> map, String docId) {
    // DateTime 파싱 헬퍼
    DateTime? parseDateTime(dynamic value) {
      if (value is DateTime) return value;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return CourseData(
      id: docId,
      title: map['title']?.toString(),
      description: map['description']?.toString(),

      // regionId가 없을 경우 region 필드도 확인
      regionId: map['regionId']?.toString() ?? map['region']?.toString(),
      region: map['region']?.toString() ?? map['regionId']?.toString(),

      // 카테고리 ID 리스트
      categoryIds: map['categoryIds'] != null ? List<String>.from(map['categoryIds']) : null,
      category: map['category']?.toString(),

      // 장소 ID (roadPlace와 placeIds 모두 호환)
      roadPlace: map['roadPlace'] ?? map['placeIds'],
      placeIds: map['placeIds'] != null
          ? List<String>.from(map['placeIds'])
          : (map['roadPlace'] != null ? List<String>.from(map['roadPlace']) : null),

      // 이미지 URL (thumbnailUrl과 imageUrl 모두 호환)
      thumbnailUrl: map['thumbnailUrl']?.toString() ?? map['imageUrl']?.toString(),
      imageUrl: map['imageUrl']?.toString() ?? map['thumbnailUrl']?.toString(),

      badgeName: map['badgeName']?.toString(),

      // 스탬프 보상 포인트 (stampRewardPoint와 rewardPoints 모두 호환)
      stampRewardPoint: ((map['stampRewardPoint'] ?? map['rewardPoints']) as num?)?.toInt(),
      rewardPoints: ((map['rewardPoints'] ?? map['stampRewardPoint']) as num?)?.toInt(),

      searchKeywords: map['searchKeywords'] != null ? List<String>.from(map['searchKeywords']) : null,

      isActive: map['isActive'] is bool ? map['isActive'] : true,

      placeCount: (map['placeCount'] as num?)?.toInt(),
      stampCount: (map['stampCount'] as num?)?.toInt(),
      estimatedTimeMinutes: (map['estimatedTimeMinutes'] as num?)?.toInt(),
      totalDistanceKm: (map['totalDistanceKm'] as num?)?.toDouble(),
      isCompleted: map['isCompleted'] as bool?,

      createdAt: parseDateTime(map['createdAt']),
      updatedAt: parseDateTime(map['updatedAt']),
    );
  }

  factory CourseData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CourseData.fromMap(data, doc.id);
  }
}

// 🆕 1. [지역별 탭 전용] 전국 지역 탐방 중심의 코스 테마 목록 (14대 데이터 전체 원본 보존 완료!)
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
    placeIds: ['place_s1_1', 'place_s1_2'], // 성수 소금빵 팩토리, 온화 베이커리 매칭
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
    placeIds: ['place_s2_1', 'place_s2_2'], // 스페셜티 딥 망원, 망원 홍차 찻집 매칭
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
    placeIds: ['place_k1_1', 'place_k1_2'], // 행궁 구움과점, 한글 쿠키 매칭
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
    placeIds: ['place_i1_1', 'place_i1_2'], // 구월 타르트, 멜로우 디저트 매칭
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
    placeIds: ['place_g1_1', 'place_g1_2'], // 속초 오션, 설악 단풍빵 매칭
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
    placeIds: ['place_j1_1', 'place_j1_2'], // 여수 오션 카페, 밤바다 블렌딩 매칭
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
    placeIds: ['place_je1_1', 'place_je1_2'], // 애월 한라봉 도넛, 돌하르방 마카롱 매칭
  ),
];

// 🆕 2. [메뉴별 탭 전용] 특정 메뉴 카테고리에 집중된 정통 전문 투어 코스 목록 (14대 데이터 전체 원본 보존 완료!)
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
    placeIds: ['place_s2_1', 'place_j1_2'], // 망원 스페셜티 드립숍 & 여수 드립커피숍 N:M 매핑 시너지
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
    placeIds: ['place_m2_1', 'place_m2_2'], // 인사동 가온한과, 개성주악 정원 매칭
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
    placeIds: ['place_m3_1', 'place_m3_2'], // 터키 카이막 행궁, 판교 카이막 매칭
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
    placeIds: ['place_m4_1', 'place_m4_2'], // 동성로 빙수, 대구 삼덕 생딸기 매칭
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
    placeIds: ['place_m5_1', 'place_m5_2'], // 해운대 수제 샌드위치, 서면 호밀빵 매칭
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
    placeIds: ['place_m6_1', 'place_m6_2'], // 강릉 인절미 크림빵, 설악 퓨전 떡카페 매칭
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
    placeIds: ['place_m7_1', 'place_m7_2'], // 송도 그린티 하우스, 부평 말차 아인슈페너 매칭
  ),
];