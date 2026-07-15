import 'package:flutter/material.dart';
import 'widgets/point_status_card.dart';
import 'widgets/ad_tab_bar.dart';
import 'widgets/ad_reward_card.dart';
import 'in_house_ad_player_page.dart'; // 🆕 신규 동영상 플레이어 화면 임포트

class AdStationPage extends StatefulWidget {
  const AdStationPage({super.key});

  @override
  State<AdStationPage> createState() => _AdStationPageState();
}

class _AdStationPageState extends State<AdStationPage> {
  // 💰 실시간 포인트 가상 변수 (정산 테스트용)
  int _currentPoints = 150;

  // 자체 광고 시청 처리 및 포인트 적립 연동 함수
  Future<void> _playInHouseAd({
    required String brandName,
    required int durationSeconds,
    required int rewardPoints,
  }) async {
    // 1. 디버그 콘솔 로그 기록
    debugPrint('=============== IN-HOUSE AD TRIGGER ===============');
    debugPrint('시청 광고 브랜드: $brandName');
    debugPrint('재생 대기 시간: $durationSeconds초');
    debugPrint('지급 적립 포인트: $rewardPoints P');
    debugPrint('==================================================');

    // 2. 2안 몰입형 광고 비디오 재생 화면 호출 및 결과 수신 대기
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

    // 3. 광고를 다 봤다면 기분 좋은 정산 진행!
    if (isCompleted == true) {
      setState(() {
        _currentPoints += rewardPoints;
      });

      // 성공 축하 다이얼로그 팝업 안내
      if (!mounted) return;
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
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Navigator.pop(context); // 뒤로가기 동작
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
        body: Column(
          children: [
            // 1. 내 현재 포인트 잔액 표시 카드 (실시간 변수 연동 완료)
            PointStatusCard(points: _currentPoints),

            // 2. 세련된 세그먼트형 알약 탭바
            const AdTabBar(),

            const SizedBox(height: 16),

            // 3. 탭 전환 콘텐츠 영역
            Expanded(
              child: TabBarView(
                children: [
                  _buildAdMobTab(context),
                  _buildInHouseTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // [탭 1] 구글 애드몹 (Phase 1) 뷰 영역
  Widget _buildAdMobTab(BuildContext context) {
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
          specs: '특징: 광고 시작 5초 후 바로 스킵 가능!',
          reward: '10 P',
          isSponsor: false,
          onTap: () {
            debugPrint('================= ADMOB EVENT =================');
            debugPrint('[AdMob SDK] 보상형 전면 광고(Interstitial) 요청 발생');
            debugPrint('예상 리워드 지급액: 10 P');
            debugPrint('================================================');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('구글 AdMob 보상형 전면 테스트 광고판을 실행합니다.'),
                backgroundColor: Colors.blue,
              ),
            );
          },
        ),

        AdRewardCard(
          title: '🎬 보상형 영상 광고',
          specs: '특징: 15초~30초 끝까지 시청 시 보상 지급',
          reward: '30 P',
          isSponsor: false,
          onTap: () {
            debugPrint('================= ADMOB EVENT =================');
            debugPrint('[AdMob SDK] 보상형 비디오(Rewarded Video) 요청 발생');
            debugPrint('예상 리워드 지급액: 30 P');
            debugPrint('================================================');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('구글 AdMob 비디오 테스트 광고판을 실행합니다.'),
                backgroundColor: Colors.blue,
              ),
            );
          },
        ),
      ],
    );
  }

  // [탭 2] 자체 제휴 (Phase 2) 뷰 영역 (실제 광고 시청 및 정산 연결 완료)
  Widget _buildInHouseTab(BuildContext context) {
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

        AdRewardCard(
          title: '🍰 [제휴] 얌얌 베이커리 신메뉴 홍보',
          specs: '보상: 30 P (영상 길이: 10초로 단축 테스트)', // 테스트 편의를 위해 10초 설정
          reward: '30 P',
          isSponsor: true,
          onTap: () => _playInHouseAd(
            brandName: '얌얌 베이커리',
            durationSeconds: 10, // 원활한 검증을 위해 10초로 세팅 (추후 변경 가능)
            rewardPoints: 30,
          ),
        ),

        AdRewardCard(
          title: '☕ [제휴] 카페 아메리카노 감성 CF',
          specs: '보상: 20 P (영상 길이: 7초로 단축 테스트)',
          reward: '20 P',
          isSponsor: true,
          onTap: () => _playInHouseAd(
            brandName: '카페 아메리카노',
            durationSeconds: 7,
            rewardPoints: 20,
          ),
        ),

        AdRewardCard(
          title: '🍩 [제휴] 도넛홀릭 브랜드 스토리',
          specs: '보상: 40 P (영상 길이: 15초로 단축 테스트)',
          reward: '40 P',
          isSponsor: true,
          onTap: () => _playInHouseAd(
            brandName: '도넛홀릭',
            durationSeconds: 15,
            rewardPoints: 40,
          ),
        ),
      ],
    );
  }
}