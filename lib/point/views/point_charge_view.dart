import 'package:flutter/material.dart';

import '../logic/point_repository.dart';
import '../models/point_models.dart';
import '../widgets/point_charge_widgets.dart';
import '../widgets/point_shop_common.dart';

/// 포인트 충전 탭 화면 View
class PointChargeView extends StatelessWidget {
  const PointChargeView({
    super.key,
    required this.repository,
    required this.onPurchasePackage,
  });

  final PointShopRepository repository;
  final ValueChanged<PointPackage> onPurchasePackage;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PointPackage>>(
      stream: repository.watchPointPackages(),
      builder: (context, snapshot) {
        return AsyncContent<List<PointPackage>>(
          snapshot: snapshot,
          emptyMessage: '구매 가능한 포인트 상품이 없습니다.',
          builder: (packages) {
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: packages.length + 3,
              separatorBuilder: (_, index) {
                final isSectionBoundary =
                    index == 0 || index == packages.length;
                return SizedBox(height: isSectionBoundary ? 20 : 8);
              },
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const PointShopBanner();
                }

                if (index == packages.length + 1) {
                  return const PointUsageGuide();
                }

                if (index == packages.length + 2) {
                  return const PointTermsNotice();
                }

                final pointPackage = packages[index - 1];
                return PointPackageTile(
                  pointPackage: pointPackage,
                  displayPrice:
                  '${formatPointNumber(pointPackage.priceCash)}원',
                  onTap: () => onPurchasePackage(pointPackage),
                );
              },
            );
          },
        );
      },
    );
  }
}