import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:yamyam_road/services/point_service.dart';
import '../models/in_house_ad_model.dart';
import '../models/point_model.dart';
import '../ad_mob_manager.dart';
import '../in_house_ad_player_page.dart';
import '../widgets/ad_dialogs.dart';

class AdStationService {
  final PointService _pointService = PointService();
  final AdMobManager adMobManager = AdMobManager();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// AdMob 초기화 및 광고 미리 로드
  void initAdMob({required VoidCallback onUpdate}) {
    adMobManager.loadRewardedAd(
      onLoaded: onUpdate,
      onFailed: onUpdate,
    );
  }

  /// 리소스 해제
  void dispose() {
    adMobManager.dispose();
  }

  /// Firestore 'ads' 컬렉션에서 활성화된 제휴 광고 목록 실시간 스트림 반환
  Stream<List<InHouseAdModel>> getInHouseAdsStream() {
    return _firestore
        .collection('ads')
        .where('type', isEqualTo: 'reward')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => InHouseAdModel.fromFirestore(doc))
        .toList());
  }

  /// Google AdMob 광고 시청 및 정산 프로세스 제어
  void handleAdMobAd({
    required BuildContext context,
    required String uid,
    required String adId,
    required int rewardPoints,
    required PointModel pointModel,
  }) {
    if (pointModel.hasWatchedToday(adId)) {
      AdDialogs.showSnackBar(context, '오늘 이미 시청 보상을 받은 광고입니다. 내일 다시 참여해주세요!');
      return;
    }

    adMobManager.showRewardedAd(
      onUserEarnedReward: (RewardItem reward) async {
        final bool success = await _pointService.earnAdMobReward(
          uid: uid,
          adId: adId,
          rewardAmount: rewardPoints,
        );

        if (!context.mounted) return;

        if (success) {
          AdDialogs.showRewardSuccessDialog(
            context,
            title: 'AdMob 포인트 적립 완료!',
            message: '구글 광고 시청 보상으로\n$rewardPoints P가 성공적으로 적립되었습니다.',
          );
        } else {
          AdDialogs.showSnackBar(context, '포인트 적립 실패: 오늘 이미 보상을 받았거나 오류가 발생했습니다.');
        }
      },
      onAdDismissed: () {},
      onError: (String message) {
        if (!context.mounted) return;
        AdDialogs.showSnackBar(context, message);
      },
    );
  }

  /// 자체 스폰서 광고 시청 및 정산 프로세스 제어
  Future<void> handleInHouseAd({
    required BuildContext context,
    required String uid,
    required InHouseAdModel ad,
    required PointModel pointModel,
  }) async {
    if (pointModel.hasWatchedToday(ad.id)) {
      AdDialogs.showSnackBar(context, '오늘 이미 시청 보상을 받은 광고입니다. 내일 다시 참여해주세요!');
      return;
    }

    final bool? isCompleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => InHouseAdPlayerPage(
          brandName: ad.title,
          duration: ad.videoDuration,
          reward: ad.rewardPoint,
        ),
      ),
    );

    if (isCompleted == true) {
      if (!context.mounted) return;

      AdDialogs.showLoadingDialog(context);

      final bool success = await _pointService.claimAdReward(
        uid: uid,
        adId: ad.id,
        rewardAmount: ad.rewardPoint,
        adTitle: '${ad.title} 시청',
      );

      if (!context.mounted) return;
      AdDialogs.hideLoadingDialog(context);

      if (success) {
        AdDialogs.showRewardSuccessDialog(
          context,
          title: '포인트 적립 완료!',
          message: '${ad.title} 시청 보상으로\n${ad.rewardPoint} P가 성공적으로 적립되었습니다.',
        );
      } else {
        AdDialogs.showSnackBar(context, '포인트 적립 실패: 오늘 이미 보상을 받았거나 오류가 발생했습니다.');
      }
    }
  }
}