import 'package:flutter/material.dart';
import '../../road/models/place_model.dart'; // 🆕 진짜 PlaceModel로 경로 변경!

class StampVerificationDialog extends StatelessWidget {
  final List<PlaceModel> places; // 🆕 진짜 PlaceModel 규격 적용
  final Function(PlaceModel) onPlaceSelected;

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
        borderRadius: BorderRadius.circular(20), // 🎨 더 둥글고 트렌디한 모서리
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          // 🍒 체리 컨셉의 화사한 원형 아이콘 배경
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
        height: 380, // 팝업창 내부 리스트뷰 높이
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
                // 🖼️ 실제 썸네일 이미지 출력 + 실패 시 🍰 디저트 이모지 보완
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 50,
                    height: 50,
                    color: Colors.orange[50],
                    alignment: Alignment.center,
                    child: place.thumbnailUrl.isNotEmpty
                        ? Image.network(
                      place.thumbnailUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                      const Text('🍰', style: TextStyle(fontSize: 24)),
                    )
                        : const Text('🍰', style: TextStyle(fontSize: 24)),
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
                    // 🏃 실측 거리 표시 (예: 7.3km)
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
                          ' ${place.rating.toStringAsFixed(1)}',
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
                          ' ${place.stampCount}',
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
                    // 🌟 실제 Firestore 문서 ID(place.id) 기준 콘솔 출력
                    debugPrint('============== STAMP VERIFICATION ==============');
                    debugPrint('[클릭 이벤트] 유저가 스탬프 인증 업체를 선택했습니다.');
                    debugPrint('선택된 업체 고유 ID (id): ${place.id}');
                    debugPrint('선택된 업체 이름 (name): ${place.name}');
                    debugPrint('================================================');

                    // 부모 화면으로 선택 데이터 송신
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