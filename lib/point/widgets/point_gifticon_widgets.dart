import 'package:flutter/material.dart';

import '../models/point_models.dart';
import 'point_shop_common.dart';

/// 기프티콘 목록의 개별 카드 위젯
class GifticonCard extends StatelessWidget {
  const GifticonCard({
    super.key,
    required this.gifticon,
    required this.onTap,
  });

  final GifticonProduct gifticon;
  final VoidCallback? onTap;

  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color subBrown = Color(0xFF7A6B63);
  static const Color cardBorder = Color(0xFFEFEBE4);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ProductImage(
                imageUrl: gifticon.imageUrl,
                icon: Icons.card_giftcard_outlined,
              ),
            ),
            const SizedBox(height: 10),
            if (gifticon.brandName?.isNotEmpty == true)
              Text(
                gifticon.brandName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: subBrown, fontSize: 10),
              ),
            const SizedBox(height: 3),
            Text(
              gifticon.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: deepChocolate,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              gifticon.isSoldOut
                  ? '품절'
                  : '${formatPointNumber(gifticon.requiredPoint)} P',
              style: TextStyle(
                color: gifticon.isSoldOut
                    ? const Color(0xFFD9534F)
                    : pointCoralRed,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}