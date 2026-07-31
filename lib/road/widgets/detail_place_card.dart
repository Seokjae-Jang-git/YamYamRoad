import 'package:flutter/material.dart';
import '../models/place_model.dart';
import '../../common/utils/map_launcher.dart';
import '../../stamp/logic/stamp_verification_navigator.dart';

class DetailPlaceCard extends StatelessWidget {
  final int index;
  final PlaceModel place;

  const DetailPlaceCard({
    super.key,
    required this.index,
    required this.place,
  });

  // YamYamRoad 브랜드 공식 컬러 상수 정의
  static const Color pointCoralRed = Color(0xFFFF6B57);    // 시그니처 코랄 레드 (인증 버튼, 스탬프 수)
  static const Color strawberryPink = Color(0xFFFFA09B);   // 연한 스트로베리 핑크 (에러 아이콘 배경 등)
  static const Color deepChocolate = Color(0xFF4A3225);    // 타이틀 및 메인 텍스트
  static const Color subBrown = Color(0xFF7A6B63);         // 서브 브라운 텍스트
  static const Color cardBorder = Color(0xFFEFEBE4);       // 구분선 & 테두리 컬러

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: cardBorder, width: 1.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 메인 썸네일 사진 (네트워크 이미지 연동 및 Fallback 예외 처리)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
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
                      color: cardBorder,
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: pointCoralRed,
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 72,
                      height: 72,
                      color: strawberryPink.withOpacity(0.2),
                      alignment: Alignment.center,
                      child: const Text('🍒', style: TextStyle(fontSize: 28)),
                    );
                  },
                )
                    : Container(
                  width: 72,
                  height: 72,
                  color: strawberryPink.withOpacity(0.2),
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
                        color: deepChocolate,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 2),
                        Text(
                          '${place.rating}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: deepChocolate,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '🍒 ${place.stampCount}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: pointCoralRed,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '|  ${place.distance}',
                          style: const TextStyle(fontSize: 12, color: subBrown),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      place.description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: subBrown,
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
                        color: deepChocolate, // 가독성 높은 브라운 톤 텍스트
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
                    side: const BorderSide(color: cardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
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
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: deepChocolate,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pointCoralRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () async {
                    await StampVerificationNavigator.open(
                      context: context,
                      placeId: place.id,
                      placeName: place.name,
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