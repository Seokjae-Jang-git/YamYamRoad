import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 🎬 Google AdMob SDK 로드 및 시청을 전담하는 매니저 클래스
class AdMobManager {
  RewardedAd? _rewardedAd;
  RewardedInterstitialAd? _rewardedInterstitialAd;

  bool _isRewardedAdLoading = false;
  bool _isRewardedInterstitialAdLoading = false;

  bool get isAdLoading => _isRewardedAdLoading || _isRewardedInterstitialAdLoading;
  bool get isRewardedAdLoaded => _rewardedAd != null;
  bool get isRewardedInterstitialAdLoaded => _rewardedInterstitialAd != null;

  // Google AdMob 안드로이드 공용 테스트 ID (영상 / 전면)
  static const String _rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _rewardedInterstitialAdUnitId = 'ca-app-pub-3940256099942544/5354046379';

  /// 🎬 보상형 영상 광고 미리 로드
  void loadRewardedAd({VoidCallback? onLoaded, VoidCallback? onFailed}) {
    _isRewardedAdLoading = true;

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoading = false;
          debugPrint('✅ AdMob 보상형 영상 광고 로드 완료');
          if (onLoaded != null) onLoaded();
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isRewardedAdLoading = false;
          debugPrint('❌ AdMob 보상형 영상 광고 로드 실패: $error');
          if (onFailed != null) onFailed();
        },
      ),
    );
  }

  /// ⚡ 보상형 전면 광고 미리 로드
  void loadRewardedInterstitialAd({VoidCallback? onLoaded, VoidCallback? onFailed}) {
    _isRewardedInterstitialAdLoading = true;

    RewardedInterstitialAd.load(
      adUnitId: _rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd = ad;
          _isRewardedInterstitialAdLoading = false;
          debugPrint('✅ AdMob 보상형 전면 광고 로드 완료');
          if (onLoaded != null) onLoaded();
        },
        onAdFailedToLoad: (error) {
          _rewardedInterstitialAd = null;
          _isRewardedInterstitialAdLoading = false;
          debugPrint('❌ AdMob 보상형 전면 광고 로드 실패: $error');
          if (onFailed != null) onFailed();
        },
      ),
    );
  }

  /// 🎬 보상형 영상 광고 시청 표출
  void showRewardedAd({
    required Function(RewardItem reward) onUserEarnedReward,
    required VoidCallback onAdDismissed,
    required Function(String error) onError,
  }) {
    if (_rewardedAd == null) {
      onError(_isRewardedAdLoading ? '광고를 불러오는 중입니다. 잠시 후 시도해주세요.' : '광고 준비에 실패했습니다. 다시 시도합니다.');
      loadRewardedAd();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        onError('광고 재생 중 오류가 발생했습니다.');
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        onUserEarnedReward(reward);
      },
    );
  }

  /// ⚡ 보상형 전면 광고 시청 표출
  void showRewardedInterstitialAd({
    required Function(RewardItem reward) onUserEarnedReward,
    required VoidCallback onAdDismissed,
    required Function(String error) onError,
  }) {
    if (_rewardedInterstitialAd == null) {
      onError(_isRewardedInterstitialAdLoading ? '광고를 불러오는 중입니다. 잠시 후 시도해주세요.' : '광고 준비에 실패했습니다. 다시 시도합니다.');
      loadRewardedInterstitialAd();
      return;
    }

    _rewardedInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedInterstitialAd = null;
        loadRewardedInterstitialAd();
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedInterstitialAd = null;
        loadRewardedInterstitialAd();
        onError('광고 재생 중 오류가 발생했습니다.');
      },
    );

    _rewardedInterstitialAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        onUserEarnedReward(reward);
      },
    );
  }

  /// 메모리 해제
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _rewardedInterstitialAd?.dispose();
    _rewardedInterstitialAd = null;
  }
}