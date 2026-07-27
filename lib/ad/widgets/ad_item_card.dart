import 'package:flutter/material.dart';

/// 광고 목록 아이템 데이터 모델
class AdItem {
  final String id;
  final String title;
  final String description;
  final int rewardPoints;
  final IconData icon;

  const AdItem({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardPoints,
    required this.icon,
  });
}

/// 🎁 개별 광고 미션 카드 위젯
class AdItemCard extends StatelessWidget {
  final AdItem adItem;
  final bool isClaimedToday;
  final VoidCallback onTapClaim;

  const AdItemCard({
    Key? key,
    required this.adItem,
    required this.isClaimedToday,
    required this.onTapClaim,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isClaimedToday ? Colors.grey.shade300 : Colors.transparent,
        ),
        boxShadow: [
          if (!isClaimedToday)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 광고 아이콘
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: isClaimedToday
                  ? Colors.grey.shade100
                  : const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Icon(
              adItem.icon,
              color: isClaimedToday ? Colors.grey : const Color(0xFF1E88E5),
              size: 28,
            ),
          ),
          const SizedBox(width: 14.0),

          // 광고 제목 및 설명
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  adItem.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isClaimedToday ? Colors.grey : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  adItem.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isClaimedToday
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10.0),

          // 보상 받기 / 완료 버튼
          ElevatedButton(
            onPressed: isClaimedToday ? null : onTapClaim,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              disabledBackgroundColor: Colors.grey.shade200,
              elevation: isClaimedToday ? 0 : 1,
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 10.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: Text(
              isClaimedToday ? '참여 완료' : '+${adItem.rewardPoints}P',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isClaimedToday ? Colors.grey.shade500 : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}