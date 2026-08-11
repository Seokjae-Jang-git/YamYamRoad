import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  // Google AdMob 안드로이드 테스트 ID
  static const String rewardedInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/5354046379'; // 보상형 전면 (10P)
  static const String rewardedVideoAdUnitId =
      'ca-app-pub-3940256099942544/5224354917'; // 보상형 동영상 (30P)

  RewardedInterstitialAd? _rewardedInterstitialAd;
  RewardedAd? _rewardedAd;

  bool isInterstitialLoaded = false;
  bool isVideoLoaded = false;

  /// 보상형 전면 광고 로드
  void loadRewardedInterstitialAd({VoidCallback? onLoaded}) {
    RewardedInterstitialAd.load(
      adUnitId: rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd = ad;
          isInterstitialLoaded = true;
          if (onLoaded != null) onLoaded();
        },
        onAdFailedToLoad: (error) {
          _rewardedInterstitialAd = null;
          isInterstitialLoaded = false;
        },
      ),
    );
  }

  /// 보상형 동영상 광고 로드
  void loadRewardedAd({VoidCallback? onLoaded}) {
    RewardedAd.load(
      adUnitId: rewardedVideoAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          isVideoLoaded = true;
          if (onLoaded != null) onLoaded();
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          isVideoLoaded = false;
        },
      ),
    );
  }

  /// 보상형 전면 광고 표출
  void showRewardedInterstitialAd({
    required Function(RewardItem reward) onUserEarnedReward,
    required VoidCallback onAdDismissed,
  }) {
    if (_rewardedInterstitialAd == null) return;

    _rewardedInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        isInterstitialLoaded = false;
        loadRewardedInterstitialAd();
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        isInterstitialLoaded = false;
        loadRewardedInterstitialAd();
        onAdDismissed();
      },
    );

    _rewardedInterstitialAd!.show(
      onUserEarnedReward: (ad, reward) {
        onUserEarnedReward(reward);
      },
    );
  }

  /// 보상형 동영상 광고 표출
  void showRewardedAd({
    required Function(RewardItem reward) onUserEarnedReward,
    required VoidCallback onAdDismissed,
  }) {
    if (_rewardedAd == null) return;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        isVideoLoaded = false;
        loadRewardedAd();
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        isVideoLoaded = false;
        loadRewardedAd();
        onAdDismissed();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        onUserEarnedReward(reward);
      },
    );
  }
}