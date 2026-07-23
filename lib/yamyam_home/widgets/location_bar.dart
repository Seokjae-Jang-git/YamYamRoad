import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_location_provider.dart';

class LocationBar extends StatelessWidget {
  const LocationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<UserLocationProvider>();
    final position = locationProvider.currentPosition;
    final isLoading = locationProvider.isLoading;

    // 위치 표시 텍스트 (로딩 상태 및 좌표 표출)
    final String locationText = isLoading
        ? '위치 정보 불러오는 중...'
        : '위도 ${position.latitude.toStringAsFixed(4)}, 경도 ${position.longitude.toStringAsFixed(4)}';

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.black),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '내 위치: $locationText',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black.withOpacity(0.8),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: isLoading
                ? null
                : () async {
              await context.read<UserLocationProvider>().refreshLocation();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: isLoading
                ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.blue,
              ),
            )
                : const Icon(Icons.refresh, size: 14, color: Colors.blue),
            label: const Text(
              '재설정',
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}