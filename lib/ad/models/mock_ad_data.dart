/// 🍩 자체 제휴 광고 Mock 데이터 모델 클래스
class InHouseAdMock {
  final String adId;
  final String brandName;
  final String title;
  final int durationSeconds;
  final int rewardPoints;

  const InHouseAdMock({
    required this.adId,
    required this.brandName,
    required this.title,
    required this.durationSeconds,
    required this.rewardPoints,
  });
}

/// 📋 자체 제휴 광고 Mock 데이터 리스트
final List<InHouseAdMock> mockInHouseAds = [
  const InHouseAdMock(
    adId: 'inhouse_bakery',
    brandName: '얌얌 베이커리',
    title: '🍰 [제휴] 얌얌 베이커리 신메뉴 홍보',
    durationSeconds: 10,
    rewardPoints: 30,
  ),
  const InHouseAdMock(
    adId: 'inhouse_americano',
    brandName: '카페 아메리카노',
    title: '☕ [제휴] 카페 아메리카노 감성 CF',
    durationSeconds: 7,
    rewardPoints: 20,
  ),
  const InHouseAdMock(
    adId: 'inhouse_donut',
    brandName: '도넛홀릭',
    title: '🍩 [제휴] 도넛홀릭 브랜드 스토리',
    durationSeconds: 15,
    rewardPoints: 40,
  ),
];