import 'package:flutter/material.dart';
import '../../road/data/place_mock_data.dart'; // 🆕 가짜 모델을 도려내고, 진짜 PlaceData 공용 모델로 연동!

class StampVerificationDialog extends StatelessWidget {
  final List<PlaceData> places; // 🆕 진짜 PlaceData 목록으로 수급 규격화
  final Function(PlaceData) onPlaceSelected;

  const StampVerificationDialog({
    super.key,
    required this.places,
    required this.onPlaceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // 🎨 더 둥글고 트렌디한 모서리 깎기
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          // 🍒 체리 컨셉의 화사한 원형 아이콘 배경 구현
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.pink[50],
              shape: BoxShape.circle,
            ),
            child: const Text('🍒', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 10),
          const Text(
            '근처 제휴 스탬프 인증',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 380, // 팝업창 내부 리스트 뷰 높이 최적화
        child: places.isEmpty
            ? const Center(
          child: Text(
            '근처에 인증 가능한 업체의 정보가 없습니다. 😢',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        )
            : ListView.builder(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          itemCount: places.length,
          itemBuilder: (context, index) {
            final place = places[index];
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[100]!, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(8),
                // 🎨 투박한 회색 글씨 대신, 산뜻한 파스텔 오렌지 컨테이너에 맛있는 디저트 이모지 썸네일 배치!
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 50,
                    height: 50,
                    color: Colors.orange[50],
                    alignment: Alignment.center,
                    child: const Text(
                      '🍰',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                title: Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    // 🏃 내 위치 기반 달리기 이모지와 거리 표시
                    Text(
                      '🏃 ${place.distance}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 12),
                        Text(
                          ' ${place.rating}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '🍒',
                          style: TextStyle(fontSize: 11),
                        ),
                        Text(
                          ' ${place.stampCount}개',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.redAccent[400],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(54, 32),
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    // 🌟 [임효진 님의 소중한 콘솔 로그 완벽 사수!]
                    debugPrint('============== STAMP VERIFICATION ==============');
                    debugPrint('[클릭 이벤트] 유저가 스탬프 인증 업체를 선택했습니다.');
                    debugPrint('선택된 업체 고유 ID (placeId): ${place.placeId}');
                    debugPrint('선택된 업체 이름 (name): ${place.name}');
                    debugPrint('================================================');

                    // 기존 콜백 실행 (부모인 HomeContentView에 선택 데이터 송신)
                    onPlaceSelected(place);
                  },
                  child: const Text(
                    '선택',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[600],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text(
            '닫기',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }
}