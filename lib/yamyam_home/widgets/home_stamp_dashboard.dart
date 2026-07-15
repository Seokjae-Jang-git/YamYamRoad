import 'package:flutter/material.dart';
import '../../road/data/place_mock_data.dart'; // 진짜 공용 매장 데이터 모델
import 'stamp_verification_dialog.dart';

class HomeStampDashboard extends StatelessWidget {
  final List<PlaceData> verifiablePlaces; // 🆕 가상 모델을 삭제하고 진짜 PlaceData 목록 수급
  final ValueChanged<PlaceData> onPlaceSelected;

  const HomeStampDashboard({
    super.key,
    required this.verifiablePlaces,
    required this.onPlaceSelected,
  });

  void _showStampVerificationPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StampVerificationDialog(
          places: verifiablePlaces,
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
            onPressed: () => _showStampVerificationPopup(context),
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