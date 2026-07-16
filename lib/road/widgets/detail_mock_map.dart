import 'package:flutter/material.dart';
import '../data/place_mock_data.dart';

class DetailMockMap extends StatelessWidget {
  final List<PlaceData> places;

  const DetailMockMap({
    super.key,
    required this.places,
  });

  @override
  Widget build(BuildContext context) {
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
}