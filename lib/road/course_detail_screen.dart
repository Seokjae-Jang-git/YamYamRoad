import 'package:flutter/material.dart';
import 'data/road_mock_data.dart';
import 'data/place_mock_data.dart';

class CourseDetailScreen extends StatefulWidget {
  final CourseData course;

  const CourseDetailScreen({
    super.key,
    required this.course,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  String _sortOption = '거리순'; // 기본 정렬 옵션 설정

  // 외래키 리스트를 활용해 실시간으로 매칭되는 마스터 가게 데이터 추출 및 필터 정렬
  List<PlaceData> get _getMatchedPlaces {
    // 1. 코스 모델의 placeIds에 등록된 가게만 필터링
    List<PlaceData> filtered = masterPlaces
        .where((place) => widget.course.placeIds.contains(place.placeId))
        .toList();

    // 2. 선택된 기획 사양 정렬 옵션 대입
    if (_sortOption == '거리순') {
      filtered.sort((a, b) => a.distanceValue.compareTo(b.distanceValue));
    } else if (_sortOption == '스탬프 순') {
      filtered.sort((a, b) => b.stampCount.compareTo(a.stampCount));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final matchedPlaces = _getMatchedPlaces;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.course.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(color: Colors.black12, height: 1.0, thickness: 0.5),
        ),
      ),
      body: Stack(
        children: [
          // 🗺️ 상단 레이어: 가상 상호작용 지도 시뮬레이션 백뷰 (수학적 핀 위치 배정)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45, // 화면의 상단 45% 확보
            child: _buildMockMap(matchedPlaces),
          ),

          // 🛗 하단 레이어: 드래그 가능한 슬라이딩 시트 (기획서의 '여기' 화살표 및 슬라이더 기조 반영)
          Positioned.fill(
            child: DraggableScrollableSheet(
              initialChildSize: 0.50, // 최초 실행 시 50% 높이 차지
              minChildSize: 0.45,     // 최소 높이 45% (지도를 가리지 않게 유지)
              maxChildSize: 0.85,     // 최대 펼쳤을 때 85%
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 시트 상단 조작 핸들바 테코레이션
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),

                      // 1. 기획안 헤더: 코스명 & 개수 표시 및 정렬 칩 배치
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.course.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${widget.course.placeCount}개',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.orange[800],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            // 거리순 / 스탬프 순 세그먼트 정렬 바
                            Row(
                              children: [
                                _buildSortOptionChip('거리순'),
                                const SizedBox(width: 6),
                                _buildSortOptionChip('스탬프 순'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.black12, height: 1.0),

                      // 2. 동적 스크롤 가능한 실시간 목록 영역
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: matchedPlaces.length,
                          itemBuilder: (context, index) {
                            final place = matchedPlaces[index];
                            return _buildPlaceCard(index + 1, place);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🗺️ 가상 지도 그래픽 뷰 구성기 (핀들의 상대좌표 매칭)
  Widget _buildMockMap(List<PlaceData> places) {
    return Container(
      color: const Color(0xFFE8F5E9), // 산뜻한 지도 느낌의 파스텔톤 초록 배경
      child: Stack(
        children: [
          // 가상 그리드/도로 모사 데코레이션 선들
          Positioned.fill(
            child: GridPaper(
              color: Colors.green[100]!.withOpacity(0.5),
              divisions: 2,
              interval: 100,
              subdivisions: 1,
            ),
          ),
          const Center(
            child: Text(
              '🧭 가상 상호작용 지도 시뮬레이션 영역',
              style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),

          // 실시간 코스 내 가게 핀(Pin) 꽂기 루프
          ...places.asMap().entries.map((entry) {
            final int idx = entry.key + 1;
            final PlaceData place = entry.value;

            return Positioned(
              left: MediaQuery.of(context).size.width * place.mapX,
              top: (MediaQuery.of(context).size.height * 0.45) * place.mapY,
              child: Tooltip(
                message: place.name,
                child: Column(
                  children: [
                    // 동그라미 번호 핀 디자인 기획 구현
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                      ),
                      child: Text(
                        '$idx',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.orange, size: 16),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // 정렬 제어 칩 빌더
  Widget _buildSortOptionChip(String title) {
    final bool isSelected = _sortOption == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortOption = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange[50] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey[300]!,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.orange[800] : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  // 🏪 기획서 사양이 완벽하게 구현된 매장 리스트 카드 빌더
  Widget _buildPlaceCard(int index, PlaceData place) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 메인 사진 placeholder (서울 이미지 대체 연동)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(
                  'assets/images/seoul.PNG',
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 72,
                      height: 72,
                      color: Colors.orange[100],
                      alignment: Alignment.center,
                      child: const Text('🍊', style: TextStyle(fontSize: 28)),
                    );
                  },
                ),
              ),
              const SizedBox(width: 14),

              // 2. 가정보 표시 텍스트 라인
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$index. ${place.name}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    // 기획안의 "★ 4.8 🍉 120 | 내 위치에서 200m" 양식 완벽 동기화
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 2),
                        Text(
                          '${place.rating}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '🍉 ${place.stampCount}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '|  ${place.distance}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 웨이팅 여부 안내 및 설명
                    Text(
                      place.description,
                      style: TextStyle(fontSize: 11, color: Colors.grey[700], fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              // 깜찍한 윙크 이모지 데코레이션
              const Text('😋', style: TextStyle(fontSize: 22)),
            ],
          ),
          const SizedBox(height: 12),

          // 3. 길찾기 및 스탬프 인증하기 연계 버튼 열 (기획안 하단 반영)
          Row(
            children: [
              // 길찾기 버튼
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('[${place.name}] 매장 길찾기 안내 로그가 활성화되었습니다.')),
                    );
                  },
                  icon: const Icon(Icons.map, size: 14, color: Colors.blue),
                  label: const Text('🗺️ 길찾기', style: TextStyle(fontSize: 11, color: Colors.black87)),
                ),
              ),
              const SizedBox(width: 8),

              // 스탬프 인증하러가기 버튼 (핵심 요구사항: 업체를 선택해서 ID까지 안전하게 넘겨주기!)
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  onPressed: () {
                    // 🌟 [기획 디테일 완료]: 스탬프 인증을 위한 placeId 안전 전달 및 디버그 로깅
                    debugPrint('==================================================');
                    debugPrint('[얌얌로드 코스 상세 인증 트리거] Selected Place ID: ${place.placeId}');
                    debugPrint('==================================================');

                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('스탬프 인증 요청'),
                          content: Text(
                            '선택한 가게: [${place.name}]\n전송 데이터(ID): ${place.placeId}\n\n스탬프 엔진에 해당 고유 아이디가 성공적으로 매칭 전송되었습니다! 🍉',
                            style: const TextStyle(fontSize: 13),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('확인'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner, size: 14),
                  label: const Text('스탬프 인증', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}