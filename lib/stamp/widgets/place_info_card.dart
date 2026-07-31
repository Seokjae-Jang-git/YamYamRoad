import 'package:flutter/material.dart';
import '../colors/stamp_colors.dart';

class PlaceInfoCard extends StatelessWidget {
  final String placeId;
  final String placeName;

  const PlaceInfoCard({
    super.key,
    required this.placeId,
    required this.placeName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: YamYamStampColors.borderPink, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: YamYamStampColors.coralRed.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: YamYamStampColors.softPink,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '🍰',
                style: TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: YamYamStampColors.coralRed.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '인증 대상 매장',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: YamYamStampColors.coralRed,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  placeName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: YamYamStampColors.deepChocolate,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '매장 ID: $placeId',
                  style: const TextStyle(
                    fontSize: 11,
                    color: YamYamStampColors.subTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}