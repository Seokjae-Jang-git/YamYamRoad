import 'package:flutter/material.dart';
import '../models/point_model.dart';
import 'ad_reward_card.dart';

class AdmobTabView extends StatelessWidget {
  final bool isAdLoading;
  final PointModel pointModel;
  final Function(String adId, int rewardPoints) onWatchAdMobAd;

  const AdmobTabView({
    super.key,
    required this.isAdLoading,
    required this.pointModel,
    required this.onWatchAdMobAd,
  });

  @override
  Widget build(BuildContext context) {
    final bool isInterstitialWatched = pointModel.hasWatchedToday('admob_interstitial');
    final bool isVideoWatched = pointModel.hasWatchedToday('admob_rewarded');

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey[300]!, width: 0.5),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '구글 시스템을 통해 24시간 실시간 광고가 자동 매칭되는 안정적인 수익 모델입니다.',
                  style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        AdRewardCard(
          title: '⚡ 보상형 전면 광고',
          specs: isInterstitialWatched
              ? '오늘 시청 완료 (내일 다시 참여 가능)'
              : (isAdLoading ? '광고 로딩 중...' : '특징: 광고 시청 시 즉시 보상 지급!'),
          reward: isInterstitialWatched ? '완료' : '10 P',
          isSponsor: false,
          onTap: () => onWatchAdMobAd('admob_interstitial', 10),
        ),

        AdRewardCard(
          title: '🎬 보상형 영상 광고',
          specs: isVideoWatched
              ? '오늘 시청 완료 (내일 다시 참여 가능)'
              : (isAdLoading ? '광고 로딩 중...' : '특징: 15초~30초 시청 시 큰 보상 지급'),
          reward: isVideoWatched ? '완료' : '30 P',
          isSponsor: false,
          onTap: () => onWatchAdMobAd('admob_rewarded', 30),
        ),
      ],
    );
  }
}