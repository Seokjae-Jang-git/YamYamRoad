import 'package:flutter/material.dart';

class AdStationPage extends StatelessWidget {
  const AdStationPage({super.key});

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
            // 1. 내 현재 포인트 잔액 표시 카드
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[100]!, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.monetization_on, color: Colors.amber, size: 24),
                      SizedBox(width: 8),
                      Text(
                        '내 현재 포인트',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '150 P',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ],
              ),
            ),

            // 2. 세련된 세그먼트형 알약 탭바 (Modern Segmented Tab)
            Container(
              height: 46,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: Colors.blue[600],
                  borderRadius: BorderRadius.circular(22),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
                tabs: const [
                  Tab(text: '구글 애드몹 (Phase 1)'),
                  Tab(text: '자체 제휴 (Phase 2)'),
                ],
              ),
            ),

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
        // 안내 배너 문구
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

        // 광고 타입 1: 전면형
        _buildAdCard(
          context: context,
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

        // 광고 타입 2: 동영상
        _buildAdCard(
          context: context,
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

  // [탭 2] 자체 제휴 (Phase 2) 뷰 영역
  Widget _buildInHouseTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // 안내 배너 문구
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

        // 제휴 브랜드 1: 얌얌베이커리
        _buildAdCard(
          context: context,
          title: '🍰 [제휴] 얌얌 베이커리 신메뉴 홍보',
          specs: '보상: 30 P (영상 길이: 30초)',
          reward: '30 P',
          isSponsor: true,
          onTap: () {
            _printInHouseLog('Yamyam Bakery', 30, '30 P');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('자체 제휴: 얌얌 베이커리 영상 광고 재생 페이지를 구동합니다.'),
                backgroundColor: Colors.orange,
              ),
            );
          },
        ),

        // 제휴 브랜드 2: 카페 아메리카노
        _buildAdCard(
          context: context,
          title: '☕ [제휴] 카페 아메리카노 감성 CF',
          specs: '보상: 20 P (영상 길이: 20초)',
          reward: '20 P',
          isSponsor: true,
          onTap: () {
            _printInHouseLog('Cafe Americano', 20, '20 P');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('자체 제휴: 카페 아메리카노 감성 CF 영상 페이지를 구동합니다.'),
                backgroundColor: Colors.orange,
              ),
            );
          },
        ),

        // 제휴 브랜드 3: 도넛홀릭
        _buildAdCard(
          context: context,
          title: '🍩 [제휴] 도넛홀릭 브랜드 스토리',
          specs: '보상: 40 P (영상 길이: 45초)',
          reward: '40 P',
          isSponsor: true,
          onTap: () {
            _printInHouseLog('Donut Holic', 45, '40 P');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('자체 제휴: 도넛홀릭 브랜드 비디오 페이지를 구동합니다.'),
                backgroundColor: Colors.orange,
              ),
            );
          },
        ),
      ],
    );
  }

  // 디버깅 콘솔 로그 헬퍼
  void _printInHouseLog(String brandName, int durationSeconds, String rewardPoints) {
    debugPrint('=============== IN-HOUSE AD EVENT ===============');
    debugPrint('[자체 제휴 광고 트리거] 로컬 플레이어로 광고 데이터 전달 완료');
    debugPrint('광고 브랜드명: $brandName');
    debugPrint('비디오 재생 규격시간: ${durationSeconds}초');
    debugPrint('시청 완료 시 정산 포인트: $rewardPoints');
    debugPrint('==================================================');
  }

  // 공통 커스텀 카드 위젯 빌더
  Widget _buildAdCard({
    required BuildContext context,
    required String title,
    required String specs,
    required String reward,
    required VoidCallback onTap,
    required bool isSponsor,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey[200]!, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                // 썸네일 박스 영역
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: isSponsor ? Colors.orange[50] : Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSponsor ? Colors.orange[100]! : Colors.blue[100]!,
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isSponsor ? 'SPONSOR' : 'AD\nMOB',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isSponsor ? Colors.orange[800] : Colors.blue[800],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 광고 상세 설명 텍스트
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        specs,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 보상 및 버튼 영역
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '보상포인트: $reward',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSponsor ? Colors.orange[800] : Colors.blue[800],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSponsor ? Colors.orange : Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: 0,
                  ),
                  onPressed: onTap,
                  child: Text(
                    isSponsor ? '스폰서 영상 시청' : '광고 시청하기',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}