import 'package:flutter/material.dart';

import '../models/point_models.dart';

/// 포인트 충전 상단 비주얼 안내 배너
class PointShopBanner extends StatelessWidget {
  const PointShopBanner({super.key});

  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color subBrown = Color(0xFF7A6B63);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE3DE)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEBE8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.monetization_on_outlined,
              color: pointCoralRed,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '얌얌 포인트 충전',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: deepChocolate,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '테스트 버전입니다.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subBrown,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 충전 가능한 포인트 상품 개별 타일 위젯
class PointPackageTile extends StatelessWidget {
  const PointPackageTile({
    super.key,
    required this.pointPackage,
    required this.displayPrice,
    required this.onTap,
  });

  final PointPackage pointPackage;
  final String displayPrice;
  final VoidCallback? onTap;

  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color cardBorder = Color(0xFFEFEBE4);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: cardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              const Icon(Icons.paid_outlined, color: pointCoralRed),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  pointPackage.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: deepChocolate,
                  ),
                ),
              ),
              Text(
                displayPrice,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: deepChocolate,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: Color(0xFFAFA7A0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 포인트 사용처 소개 섹션 위젯
class PointUsageGuide extends StatelessWidget {
  const PointUsageGuide({super.key});

  static const Color deepChocolate = Color(0xFF4A3225);

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '포인트 사용처',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: deepChocolate,
          ),
        ),
        SizedBox(height: 12),
        PointUsageCard(
          icon: Icons.emoji_emotions_outlined,
          title: '커뮤니티 이모티콘',
          description: '마음에 드는 이모티콘 패키지를 구매하고 커뮤니티에서 사용할 수 있어요.',
        ),
        SizedBox(height: 10),
        PointUsageCard(
          icon: Icons.card_giftcard_outlined,
          title: '기프티콘 교환',
          description: '보유 포인트를 카페와 디저트 브랜드의 기프티콘으로 교환할 수 있어요.',
        ),
      ],
    );
  }
}

/// 포인트 사용처 개별 정보 카드
class PointUsageCard extends StatelessWidget {
  const PointUsageCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color subBrown = Color(0xFF7A6B63);
  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color cardBorder = Color(0xFFEFEBE4);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF7F5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: pointCoralRed, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: deepChocolate,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: subBrown,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 포인트 이용 안내 유의사항 박스
class PointTermsNotice extends StatelessWidget {
  const PointTermsNotice({super.key});

  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color subBrown = Color(0xFF7A6B63);

  static const _notices = [
    '충전된 유료 포인트는 회원 계정에 귀속되며 다른 회원에게 양도할 수 없습니다.',
    '상품 구매 시 무료 포인트가 먼저 사용되고 부족한 금액은 유료 포인트에서 차감됩니다.',
    '유료 포인트는 결제 확인이 완료된 후 지급되며 결제 도중 앱을 종료하면 지급이 지연될 수 있습니다.',
    '무료 포인트는 스탬프, 광고, 이벤트 등의 보상으로만 지급됩니다.',
    '이모티콘 지급 또는 기프티콘 발행이 완료된 구매 건은 환불이 제한될 수 있습니다.',
    '포인트 사용처와 이용 조건은 서비스 운영 정책에 따라 변경될 수 있습니다.',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: subBrown),
              SizedBox(width: 7),
              Text(
                '포인트 이용 안내',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: deepChocolate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._notices.map(
                (notice) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: SizedBox(
                      width: 3,
                      height: 3,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: subBrown,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notice,
                      style: const TextStyle(
                        color: subBrown,
                        fontSize: 11,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            '※ 세부 환불 기준은 별도의 이용약관 및 환불 정책을 따릅니다.',
            style: TextStyle(
              color: Color(0xFFAFA7A0),
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}