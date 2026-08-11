import 'package:flutter/material.dart';
import '../colors/stamp_colors.dart';

class StarRatingCard extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onRatingChanged;

  const StarRatingCard({
    super.key,
    required this.rating,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: YamYamStampColors.borderPink, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: YamYamStampColors.coralRed.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '매장은 어떠셨나요?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: YamYamStampColors.deepChocolate,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '솔직한 만족도 별점을 남겨주세요',
            style: TextStyle(
              fontSize: 12,
              color: YamYamStampColors.subTextColor,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final value = index + 1;
              final isSelected = value <= rating;
              return IconButton(
                splashRadius: 24,
                tooltip: '$value점',
                onPressed: () => onRatingChanged(value),
                icon: Icon(
                  isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isSelected ? YamYamStampColors.starActive : YamYamStampColors.starInactive,
                  size: 40,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}