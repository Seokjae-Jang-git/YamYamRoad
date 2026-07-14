import 'package:flutter/material.dart';

// 업체 정보를 표현할 임시 데이터 구조 클래스
class VerifiablePlace {
  final String placeId;
  final String name;
  final String distance;
  final double rating;
  final int stampCount;
  final String category;

  const VerifiablePlace({
    required this.placeId,
    required this.name,
    required this.distance,
    required this.rating,
    required this.stampCount,
    required this.category,
  });
}

class StampVerificationDialog extends StatelessWidget {
  final List<VerifiablePlace> places;
  final Function(VerifiablePlace) onPlaceSelected;

  const StampVerificationDialog({
    super.key,
    required this.places,
    required this.onPlaceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.blue),
          SizedBox(width: 8),
          Text(
            '근처 인증 가능 업체',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 350, // 팝업 내 리스트뷰가 깨지지 않도록 높이 제한 설정
        child: places.isEmpty
            ? const Center(child: Text('근처에 인증 가능한 업체의 정보가 없습니다.'))
            : ListView.builder(
          shrinkWrap: true,
          itemCount: places.length,
          itemBuilder: (context, index) {
            final place = places[index];
            return Card(
              elevation: 1,
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.grey, width: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(8),
                // 업체 이미지 Placeholder 영역
                leading: Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: const Text(
                    '이미지',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
                title: Text(
                  place.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      '${place.category} · 📍 ${place.distance}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 12),
                        Text(
                          ' ${place.rating}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.confirmation_number_outlined, color: Colors.blue, size: 12),
                        Text(
                          ' 스탬프 ${place.stampCount}개',
                          style: const TextStyle(fontSize: 11, color: Colors.blue),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(60, 32),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: () {
                    // 콘솔에 직접 placeId 출력 시각화
                    debugPrint('============== STAMP VERIFICATION ==============');
                    debugPrint('[클릭 이벤트] 유저가 스탬프 인증 업체를 선택했습니다.');
                    debugPrint('선택된 업체 고유 ID (placeId): ${place.placeId}');
                    debugPrint('선택된 업체 이름 (name): ${place.name}');
                    debugPrint('================================================');

                    // 기존 콜백 실행
                    onPlaceSelected(place);
                  },
                  child: const Text('선택', style: TextStyle(fontSize: 12)),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}