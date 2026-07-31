import 'package:flutter/material.dart';

enum SortOption { latest, likes, comments, scrap }
enum SortPeriod { all, daily, weekly }

class CommunitySortBar extends StatelessWidget {
  final SortOption currentOption;
  final SortPeriod currentPeriod;
  final ValueChanged<SortOption> onOptionChanged;
  final ValueChanged<SortPeriod> onPeriodChanged;

  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color subTextColor = Color(0xFF7A6B63);

  const CommunitySortBar({
    super.key,
    required this.currentOption,
    required this.currentPeriod,
    required this.onOptionChanged,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool showPeriodRow =
        currentOption == SortOption.likes || currentOption == SortOption.scrap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _sortTabButton('최신순', SortOption.latest),
              const SizedBox(width: 12),
              _sortTabButton('좋아요순', SortOption.likes),
              const SizedBox(width: 12),
              _sortTabButton('댓글순', SortOption.comments),
              const SizedBox(width: 12),
              _sortTabButton('스크랩순', SortOption.scrap),
            ],
          ),
        ),
        if (showPeriodRow)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Row(
              children: [
                _periodChip('전체', SortPeriod.all),
                const SizedBox(width: 6),
                _periodChip('일간', SortPeriod.daily),
                const SizedBox(width: 6),
                _periodChip('주간', SortPeriod.weekly),
              ],
            ),
          ),
      ],
    );
  }

  Widget _sortTabButton(String label, SortOption option) {
    final bool selected = currentOption == option;
    return GestureDetector(
      onTap: () => onOptionChanged(option),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          color: selected ? pointCoralRed : subTextColor,
        ),
      ),
    );
  }

  Widget _periodChip(String label, SortPeriod period) {
    final bool selected = currentPeriod == period;
    return GestureDetector(
      onTap: () => onPeriodChanged(period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? pointCoralRed : deepChocolate.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : subTextColor,
          ),
        ),
      ),
    );
  }
}