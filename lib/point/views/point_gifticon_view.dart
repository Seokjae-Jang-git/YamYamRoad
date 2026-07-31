import 'package:flutter/material.dart';

import '../logic/point_repository.dart';
import '../models/point_models.dart';
import '../widgets/point_gifticon_widgets.dart';
import '../widgets/point_shop_common.dart';

/// 기프티콘 탭 화면 View
class PointGifticonView extends StatelessWidget {
  const PointGifticonView({
    super.key,
    required this.repository,
    required this.onSelectGifticon,
  });

  final PointShopRepository repository;
  final ValueChanged<GifticonProduct> onSelectGifticon;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<GifticonProduct>>(
      stream: repository.watchGifticons(),
      builder: (context, snapshot) {
        return AsyncContent<List<GifticonProduct>>(
          snapshot: snapshot,
          emptyMessage: '판매 중인 기프티콘이 없습니다.',
          builder: (gifticons) {
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: gifticons.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 12,
                childAspectRatio: 0.74,
              ),
              itemBuilder: (context, index) {
                final gifticon = gifticons[index];
                return GifticonCard(
                  gifticon: gifticon,
                  onTap: gifticon.isSoldOut
                      ? null
                      : () => onSelectGifticon(gifticon),
                );
              },
            );
          },
        );
      },
    );
  }
}