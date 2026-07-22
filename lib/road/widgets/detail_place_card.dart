import 'package:flutter/material.dart';
import '../models/place_model.dart';
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
              // 1. 메인 썸네일 사진 (네트워크 이미지 연동 및 Fallback 예외 처리)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: place.thumbnailUrl.isNotEmpty
                    ? Image.network(
                  place.thumbnailUrl,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 72,
                      height: 72,
                      color: Colors.grey[200],
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 72,
                      height: 72,
                      color: Colors.orange[100],
                      alignment: Alignment.center,
                      child: const Text('🍒', style: TextStyle(fontSize: 28)),
                    );
                  },
                )
                    : Container(
                  width: 72,
                  height: 72,
                  color: Colors.orange[100],
                  alignment: Alignment.center,
                  child: const Text('🍒', style: TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 14),

              // 2. 장소 정보 표시 텍스트 라인
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$index. ${place.name}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
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
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
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
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2-1. [안내 배너]: 스탬프 300개 이상(showWaitingNotice가 true)일 때만 조건부 노출
          if (place.showWaitingNotice) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1), // 은은하고 따뜻한 노란빛 배경
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFFE082), width: 0.8),
              ),
              child: const Row(
                children: [
                  Text('💡', style: TextStyle(fontSize: 13)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '많은 사람이 방문한 장소예요. 대기 시간이 발생할 수 있습니다!',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF5D4037), // 가독성 높은 브라운 톤 텍스트
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // 3. 길찾기 및 스탬프 인증하기 연계 버튼 열
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  onPressed: () {
                    MapLauncher.launchNaverMap(
                      latitude: place.lat,
                      longitude: place.lng,
                      name: place.name,
                      address: place.address,
                    );
                  },
                  child: const Text(
                    '🗺️ 길찾기',
                    style: TextStyle(fontSize: 11, color: Colors.black87),
                  ),
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
                  label: const Text(
                    '스탬프 인증',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}