import 'package:flutter/material.dart';
import '../models/point_model.dart';
import '../models/mock_ad_data.dart';
import 'ad_reward_card.dart';

class InHouseTabView extends StatelessWidget {
  final PointModel pointModel;
  final Function({
  required String adId,
  required String brandName,
  required int durationSeconds,
  required int rewardPoints,
  }) onPlayInHouseAd;

  const InHouseTabView({
    super.key,
    required this.pointModel,
    required this.onPlayInHouseAd,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.orange[100]!, width: 0.5),
          ),
          child: const Row(
            children: [
              Icon(Icons.store, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '얌얌로드와 정식 제휴를 맺은 브랜드의 프리미엄 광고를 시청하고 큰 보상을 받으세요!',
                  style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ...mockInHouseAds.map((ad) {
          final bool isWatched = pointModel.hasWatchedToday(ad.adId);
          return AdRewardCard(
            title: ad.title,
            specs: isWatched
                ? '오늘 시청 완료 (내일 다시 참여 가능)'
                : '보상: ${ad.rewardPoints} P (영상 길이: ${ad.durationSeconds}초)',
            reward: isWatched ? '완료' : '${ad.rewardPoints} P',
            isSponsor: true,
            onTap: () => onPlayInHouseAd(
              adId: ad.adId,
              brandName: ad.brandName,
              durationSeconds: ad.durationSeconds,
              rewardPoints: ad.rewardPoints,
            ),
          );
        }),
      ],
    );
  }
}