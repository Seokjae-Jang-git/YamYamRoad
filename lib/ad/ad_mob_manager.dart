import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 🎬 Google AdMob SDK 로드 및 시청을 전담하는 매니저 클래스
class AdMobManager {
  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;

  bool get isAdLoading => _isAdLoading;
  bool get isAdLoaded => _rewardedAd != null;

  // Google AdMob 안드로이드/iOS 공용 테스트 ID
  static const String _adUnitId = 'ca-app-pub-3940256099942544/5224354917';

  /// 보상형 광고 미리 로드
  void loadRewardedAd({VoidCallback? onLoaded, VoidCallback? onFailed}) {
    _isAdLoading = true;

    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdLoading = false;
          debugPrint('✅ AdMob 리워드 광고 로드 완료');
          if (onLoaded != null) onLoaded();
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isAdLoading = false;
          debugPrint('❌ AdMob 리워드 광고 로드 실패: $error');
          if (onFailed != null) onFailed();
        },
      ),
    );
  }

  /// 보상형 광고 시청 표출
  void showRewardedAd({
    required Function(RewardItem reward) onUserEarnedReward,
    required VoidCallback onAdDismissed,
    required Function(String error) onError,
  }) {
    if (_rewardedAd == null) {
      onError(_isAdLoading ? '광고를 불러오는 중입니다. 잠시 후 시도해주세요.' : '광고 준비에 실패했습니다. 다시 시도합니다.');
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

  /// 메모리 해제
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}