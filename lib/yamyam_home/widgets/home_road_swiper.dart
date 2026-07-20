import 'package:flutter/material.dart';
import '../../road/models/road.dart';
import '../../road/models/place_model.dart';
import '../../road/course_detail_screen.dart';

class HomeRoadSwiper extends StatefulWidget {
  final List<Map<String, dynamic>> recommendedRoads;

  const HomeRoadSwiper({
    super.key,
    required this.recommendedRoads,
  });

  @override
  State<HomeRoadSwiper> createState() => _HomeRoadSwiperState();
}

class _HomeRoadSwiperState extends State<HomeRoadSwiper> {
  late PageController _pageController;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// dynamic 객체(CourseData 등)를 안전하게 Road 객체로 파싱하는 헬퍼 함수
  Road _parseToRoad(dynamic rawItem) {
    if (rawItem is Road) {
      return rawItem;
    }

    final dynamic d = rawItem;
    return Road(
      id: d?.id?.toString() ?? '',
      title: d?.title?.toString() ?? '제목 없음',
      description: d?.description?.toString() ?? '',
      region: d?.region?.toString() ?? '전체',
      categoryIds: (d?.categoryIds is List)
          ? List<String>.from((d.categoryIds as List).map((e) => e.toString()))
          : <String>[],
      placeIds: (d?.placeIds is List)
          ? List<String>.from((d.placeIds as List).map((e) => e.toString()))
          : <String>[],
      imageUrl: d?.imageUrl?.toString() ?? '',
      badgeName: d?.badgeName?.toString() ?? '',
      rewardPoints: (d?.rewardPoints as num?)?.toInt() ?? 0,
      estimatedTimeMinutes: (d?.estimatedTimeMinutes as num?)?.toInt() ?? 0,
      totalDistanceKm: (d?.totalDistanceKm as num?)?.toDouble() ?? 0.0,
      createdAt: (d?.createdAt is DateTime) ? d.createdAt : DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.recommendedRoads.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          double cardScale = 1.0;
          if (_pageController.position.haveDimensions) {
            double pageOffset = (_currentPage - index).abs();
            cardScale = (1.0 - (pageOffset * 0.06)).clamp(0.94, 1.0);
          } else {
            cardScale = index == 0 ? 1.0 : 0.94;
          }

          final item = widget.recommendedRoads[index];
          final rawRoadItem = item['road'] ?? item['course'];
          final Road road = _parseToRoad(rawRoadItem);
          final PlaceModel? nearestPlace = item['nearestPlace'];

          final labels = [
            '🔥 대세 추천 로드',
            '✨ 내 위치 밀착 로드',
            '🏆 베스트 도장깨기',
            '⭐️ 파워 핫플레이스',
            '🍀 보석 같은 골목 로드'
          ];
          final currentLabel = labels[index % labels.length];

          return Transform.scale(
            scale: cardScale,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CourseDetailScreen(road: road),
                  ),
                );
              },
              child: Card(
                color: Colors.white,
                elevation: 4,
                shadowColor: Colors.black38,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey[200]!, width: 1.2),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              'assets/temp_images/peach_salad.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.pink[50],
                                  alignment: Alignment.center,
                                  child: const Text('🍑', style: TextStyle(fontSize: 40)),
                                );
                              },
                            ),
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.pink[500]!.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                currentLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  road.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${road.region} | ${road.categoryIds.join(', ')}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),

                            if (nearestPlace != null)
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50]!.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange[100]!, width: 0.8),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, color: Colors.orange, size: 14),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            '관문: ${nearestPlace.name}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '🏃 ${nearestPlace.distance}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '🍒 ${nearestPlace.stampCount}개',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}