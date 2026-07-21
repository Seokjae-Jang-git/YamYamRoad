import 'package:flutter/material.dart';
import '../models/place_model.dart';
import '../../common/data/temp_user_session.dart';
import '../../common/utils/map_launcher.dart';

class DetailPlaceCard extends StatelessWidget {
  final int index;
  final PlaceModel place;

  const DetailPlaceCard({
    super.key,
    required this.index,
    required this.place,
  });

  @override
  Widget build(BuildContext context) {
    // [개인화 비즈니스 로직]: 공용 세션의 완료 Set 데이터에 해당 가게 ID가 매칭되는가?
    final bool isCompleted = completedPlaceIdsOfCurrentUser.contains(place.id);

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
              // 1. 메인 사진 placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(
                  'assets/temp_images/seoul.PNG',
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 72,
                      height: 72,
                      color: Colors.orange[100],
                      alignment: Alignment.center,
                      child: const Text('🍒', style: TextStyle(fontSize: 28)),
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
                          '🍒 ${place.stampCount}',
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
                    Text(
                      place.description,
                      style: TextStyle(fontSize: 11, color: Colors.grey[700], fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),

              // [완료 여부 조건부 이모지 렌더링]
              Text(
                isCompleted ? '🍒' : '😋',
                style: const TextStyle(fontSize: 22),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. 길찾기 및 스탬프 인증하기 연계 버튼 열
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  onPressed: () {
                    MapLauncher.showMapSelectionBottomSheet(
                      context: context,
                      latitude: place.lat,
                      longitude: place.lng,
                      name: place.name,
                    );
                  },
                  icon: const Icon(Icons.map, size: 14, color: Colors.blue),
                  label: const Text('🗺️ 길찾기', style: TextStyle(fontSize: 11, color: Colors.black87)),
                ),
              ),
              const SizedBox(width: 8),

              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  onPressed: () {
                    debugPrint('==================================================');
                    debugPrint('[얌얌로드 코스 상세 인증 트리거] Selected Place ID: ${place.id}');
                    debugPrint('==================================================');

                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('스탬프 인증 요청'),
                          content: Text(
                            '선택한 가게: [${place.name}]\n전송 데이터(ID): ${place.id}\n\n스탬프 엔진에 해당 고유 아이디가 성공적으로 매칭 전송되었습니다! 🍒',
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