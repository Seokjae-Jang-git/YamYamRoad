import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_location_provider.dart';

class LocationBar extends StatelessWidget {
  const LocationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<UserLocationProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on,
            color: Colors.redAccent,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              locationProvider.isLoading
                  ? '위치 정보를 가져오는 중...'
                  : locationProvider.currentAddress,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                ),
              )
                  : Icon(
                Icons.refresh,
                size: 20,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}