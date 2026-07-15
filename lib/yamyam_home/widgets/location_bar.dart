import 'package:flutter/material.dart';

class LocationBar extends StatelessWidget {
  final String currentLocation;
  final VoidCallback onResetLocation;

  const LocationBar({
    super.key,
    required this.currentLocation,
    required this.onResetLocation,
  });

  @override
  Widget build(BuildContext context) {
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
              '내 위치: $currentLocation',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black.withOpacity(0.8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onResetLocation,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.refresh, size: 14, color: Colors.blue),
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