import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../road/models/place_model.dart'; // 🆕 진짜 PlaceModel로 타입 교체!
import '../../road/repositories/place_repository.dart';
import '../../providers/user_location_provider.dart';
import 'stamp_verification_dialog.dart';

class HomeStampDashboard extends StatelessWidget {
  final List<PlaceModel> verifiablePlaces; // 🆕 진짜 PlaceModel 목록 규격 적용
  final ValueChanged<PlaceModel> onPlaceSelected;

  const HomeStampDashboard({
    super.key,
    required this.verifiablePlaces,
    required this.onPlaceSelected,
  });

  /// [14-2단계] 인증하기 버튼 클릭 시 위치 기반 근처 가게 Top 10 조회 후 팝업 출력
  void _handleStampAuth(BuildContext context) async {
    // 1. 전역 위치 Provider에서 현재 위도/경도 가져오기
    final locationProvider = Provider.of<UserLocationProvider>(context, listen: false);
    final double userLat = locationProvider.userLat;
    final double userLng = locationProvider.userLng;

    print('📍 [14-2단계] 사용자 현재 위치: 위도 $userLat, 경도 $userLng');

    try {
      // 2. PlaceRepository를 통해 내 근처 스탬프 매장 Top 10 조회
      final places = await PlaceRepository().fetchNearbyStampPlaces(
        userLat: userLat,
        userLng: userLng,
      );

      print('=== 🧪 [14-2단계 성공] 근처 가게 목록 (총 ${places.length}개) ===');
      for (var i = 0; i < places.length; i++) {
        print('${i + 1}. [ID: ${places[i].id}] ${places[i].name} - 거리: ${places[i].distance}');
      }

      // 3. 조회해 온 진짜 내 근처 매장 10개 목록으로 인증 팝업 띄우기
      if (context.mounted) {
        _showStampVerificationPopup(context, places.isNotEmpty ? places : verifiablePlaces);
      }
    } catch (e) {
      print('❌ [14-2단계 실패]: $e');
      // 에러 발생 시 기본 매장 목록으로 팝업 출력
      if (context.mounted) {
        _showStampVerificationPopup(context, verifiablePlaces);
      }
    }
  }

  void _showStampVerificationPopup(BuildContext context, List<PlaceModel> places) {
    showDialog(
      context: context,
      builder: (context) {
        return StampVerificationDialog(
          places: places,
          onPlaceSelected: onPlaceSelected,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.blue[100]!, width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '지금 매장에 계신가요?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '근처 제휴 업체 스탬프 인증하기',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: Colors.blue.withOpacity(0.3),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _handleStampAuth(context),
            child: const Text(
              '인증하기',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}