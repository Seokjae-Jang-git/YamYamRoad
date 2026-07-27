import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/auth_service.dart';
import '../services/point_service.dart';
import 'models/point_model.dart';
import 'models/mock_ad_data.dart';
import 'widgets/point_status_card.dart';
import 'widgets/ad_tab_bar.dart';
import 'widgets/ad_reward_card.dart';
import 'in_house_ad_player_page.dart';

class AdStationPage extends StatefulWidget {
  const AdStationPage({super.key});

  @override
  State<AdStationPage> createState() => _AdStationPageState();
}

class _AdStationPageState extends State<AdStationPage> {
  final PointService _pointService = PointService();

  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;

  // Google AdMob 테스트용 리워드 비디오 광고 단위 ID (안드로이드/iOS 공용 테스트 ID)
  final String _adUnitId = 'ca-app-pub-3940256099942544/5224354917';

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  /// 🎬 Google AdMob 리워드 광고 미리 로드
  void _loadRewardedAd() {
    setState(() {
      _isAdLoading = true;
    });

    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() {
            _rewardedAd = ad;
            _isAdLoading = false;
          });
          debugPrint('✅ AdMob 리워드 광고 로드 완료');
        },
        onAdFailedToLoad: (error) {
          if (!mounted) return;
          setState(() {
            _rewardedAd = null;
            _isAdLoading = false;
          });
          debugPrint('❌ AdMob 리워드 광고 로드 실패: $error');
        },
      ),
    );
  }

  /// 🎬 Google AdMob 광고 시청 및 정산 호출
  void _showAdMobRewardAd(String uid, int rewardPoints) {
    if (_rewardedAd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isAdLoading ? '광고를 불러오는 중입니다. 잠시 후 시도해주세요.' : '광고 준비에 실패했습니다. 다시 시도합니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadRewardedAd();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewardedAd(); // 다음 시청을 위한 재로드
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadRewardedAd();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('광고 재생 중 오류가 발생했습니다.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
        // Firestore DB에 AdMob 시청 무료 포인트 적립 트랜잭션 수행
        final bool success = await _pointService.earnAdMobReward(
          uid: uid,
          rewardAmount: rewardPoints,
        );

        if (!mounted) return;

        if (success) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              title: const Row(
                children: [
                  Icon(Icons.monetization_on, color: Colors.amber),
                  SizedBox(width: 8),
                  Text('AdMob 포인트 적립 완료!'),
                ],
              ),
              content: Text('구글 광고 시청 보상으로\n$rewardPoints P가 성공적으로 적립되었습니다.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('확인', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('포인트 적립 실패: 오류가 발생했습니다.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  /// 자체 광고 시청 처리 및 Firestore 포인트 적립 연동 함수
  Future<void> _playInHouseAd({
    required String uid,
    required String adId,
    required String brandName,
    required int durationSeconds,
    required int rewardPoints,
    required PointModel pointModel,
  }) async {
    // 0. 오늘 이미 시청한 광고인지 사전 체크
    if (pointModel.hasWatchedToday(adId)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('오늘 이미 시청 보상을 받은 광고입니다. 내일 다시 참여해주세요!'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 1. 디버그 콘솔 로그 기록
    debugPrint('=============== IN-HOUSE AD TRIGGER ===============');
    debugPrint('시청 광고 브랜드: $brandName');
    debugPrint('재생 대기 시간: $durationSeconds초');
    debugPrint('지급 적립 포인트: $rewardPoints P');
    debugPrint('==================================================');

    // 2. 광고 비디오 재생 화면 호출 및 결과 수신 대기
    final bool? isCompleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => InHouseAdPlayerPage(
          brandName: brandName,
          duration: durationSeconds,
          reward: rewardPoints,
        ),
      ),
    );

    // 3. 광고를 다 봤다면 Firestore DB 트랜잭션 정산 진행
    if (isCompleted == true) {
      if (!mounted) return;

      // 로딩 인디케이터 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Firestore 포인트 증가 + ad_view 로그 생성
      final bool success = await _pointService.claimAdReward(
        uid: uid,
        adId: adId,
        rewardAmount: rewardPoints,
        adTitle: '[$brandName] 광고 시청',
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // 로딩 닫기

      if (success) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            title: const Row(
              children: [
                Icon(Icons.monetization_on, color: Colors.amber),
                SizedBox(width: 8),
                Text('포인트 적립 완료!'),
              ],
            ),
            content: Text('[$brandName] 광고 시청 보상으로\n$rewardPoints P가 성공적으로 적립되었습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('포인트 적립 실패: 오늘 이미 보상을 받았거나 오류가 발생했습니다.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? uid = AuthService.currentUser?.uid;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            '무료 포인트 충전소',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1.0),
            child: Divider(color: Colors.grey, height: 1.0, thickness: 0.5),
          ),
        ),
        backgroundColor: Colors.white,
        body: uid == null
            ? const Center(
          child: Text(
            '로그인이 필요한 서비스입니다.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        )
            : StreamBuilder<PointModel>(
          stream: _pointService.getPointStream(uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('데이터를 불러오는데 실패했습니다: ${snapshot.error}'),
              );
            }

            final pointModel = snapshot.data ?? PointModel.initial();

            return Column(
              children: [
                // 1. 내 현재 포인트 잔액 표시 카드
                PointStatusCard(points: pointModel.points),

                // 2. 세련된 세그먼트형 알약 탭바
                const AdTabBar(),

                const SizedBox(height: 16),

                // 3. 탭 전환 콘텐츠 영역
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildAdMobTab(context, uid),
                      _buildInHouseTab(context, uid, pointModel),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // [탭 1] 구글 애드몹 뷰 영역 (실제 AdMob 시청 연동 완료)
  Widget _buildAdMobTab(BuildContext context, String uid) {
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
          specs: _isAdLoading ? '광고 로딩 중...' : '특징: 광고 시청 시 즉시 보상 지급!',
          reward: '10 P',
          isSponsor: false,
          onTap: () => _showAdMobRewardAd(uid, 10),
        ),

        AdRewardCard(
          title: '🎬 보상형 영상 광고',
          specs: _isAdLoading ? '광고 로딩 중...' : '특징: 15초~30초 시청 시 큰 보상 지급',
          reward: '30 P',
          isSponsor: false,
          onTap: () => _showAdMobRewardAd(uid, 30),
        ),
      ],
    );
  }

  // [탭 2] 자체 제휴 뷰 영역 (Mock 데이터 동적 바인딩)
  Widget _buildInHouseTab(
      BuildContext context,
      String uid,
      PointModel pointModel,
      ) {
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
            onTap: () => _playInHouseAd(
              uid: uid,
              adId: ad.adId,
              brandName: ad.brandName,
              durationSeconds: ad.durationSeconds,
              rewardPoints: ad.rewardPoints,
              pointModel: pointModel,
            ),
          );
        }),
      ],
    );
  }
}