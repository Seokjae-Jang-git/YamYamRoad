import 'package:flutter/material.dart';
import '../models/point_model.dart';
import '../models/in_house_ad_model.dart';
import '../services/ad_station_service.dart';
import 'ad_reward_card.dart';

class InHouseTabView extends StatelessWidget {
  final PointModel pointModel;
  final void Function(InHouseAdModel ad) onPlayInHouseAd;

  const InHouseTabView({
    super.key,
    required this.pointModel,
    required this.onPlayInHouseAd,
  });

  @override
  Widget build(BuildContext context) {
    final AdStationService adStationService = AdStationService();

    // 제휴(In-House) 스폰서 전용 캐러멜 골드 컬러 정의
    const Color caramelGold = Color(0xFFC88A4B);
    const Color deepChocolate = Color(0xFF4A3225);
    const Color cocoaText = Color(0xFF8C7A6B);
    const Color sponsorBg = Color(0xFFFBF3EB);

    return StreamBuilder<List<InHouseAdModel>>(
      stream: adStationService.getInHouseAdsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: caramelGold,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              '광고 데이터를 불러오는데 실패했습니다: ${snapshot.error}',
              style: const TextStyle(color: cocoaText),
            ),
          );
        }

        final ads = snapshot.data ?? [];

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            // 제휴 광고 전용 안내 상자 (캐러멜 골드 포인트)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: sponsorBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: caramelGold.withOpacity(0.3),
                  width: 1.0,
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.store, color: caramelGold, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '얌얌로드와 정식 제휴를 맺은 브랜드의 프리미엄 광고를 시청하고 큰 보상을 받으세요!',
                      style: TextStyle(
                        fontSize: 12,
                        color: deepChocolate,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (ads.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: Text(
                    '현재 진행 중인 제휴 광고가 없습니다.',
                    style: TextStyle(fontSize: 14, color: cocoaText),
                  ),
                ),
              )
            else
              ...ads.map((ad) {
                final bool isWatched = pointModel.hasWatchedToday(ad.id);
                return AdRewardCard(
                  title: ad.title,
                  specs: isWatched
                      ? '오늘 시청 완료 (내일 다시 참여 가능)'
                      : '보상: ${ad.rewardPoint} P (영상 길이: ${ad.videoDuration}초)',
                  reward: isWatched ? '완료' : '${ad.rewardPoint} P',
                  isSponsor: true,
                  onTap: () => onPlayInHouseAd(ad),
                );
              }),
          ],
        );
      },
    );
  }
}