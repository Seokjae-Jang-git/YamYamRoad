import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_location_provider.dart';

class LocationBar extends StatelessWidget {
  const LocationBar({super.key});

  // 브랜드 공식 컬러 상수 정의
  static const Color coralRed = Color(0xFFFF6B57);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color creamyIvory = Color(0xFFFFFDF9);
  static const Color borderColor = Color(0xFFE8E2D9);

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<UserLocationProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: creamyIvory,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on,
            color: coralRed,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              locationProvider.isLoading
                  ? '위치 정보를 가져오는 중...'
                  : locationProvider.currentAddress,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: deepChocolate,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: locationProvider.isLoading
                ? null
                : () {
              // 새로고침 버튼 클릭 시 forceRefresh: true 전달
              context.read<UserLocationProvider>().refreshLocation(forceRefresh: true);
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: locationProvider.isLoading
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(coralRed),
                ),
              )
                  : const Icon(
                Icons.refresh,
                size: 20,
                color: deepChocolate,
              ),
            ),
          ),
        ],
      ),
    );
  }
}