import 'package:flutter/material.dart';

import '../models/point_models.dart';
import 'point_shop_common.dart';

/// 이모티콘 목록의 개별 그리드 썸네일 위젯
class EmoticonThumbnail extends StatelessWidget {
  const EmoticonThumbnail({
    super.key,
    required this.emoticon,
    required this.onTap,
  });

  final EmoticonProduct emoticon;
  final VoidCallback onTap;

  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color cardBorder = Color(0xFFEFEBE4);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          children: [
            Expanded(
              child: ProductImage(
                imageUrl: emoticon.imageUrl,
                icon: Icons.emoji_emotions_outlined,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              emoticon.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: deepChocolate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 이모티콘 클릭 시 하단에서 올라오는 구성 품목 및 구매 확인 바텀시트 위젯
class EmoticonPackageSheet extends StatelessWidget {
  const EmoticonPackageSheet({
    super.key,
    required this.emoticon,
    required this.onPurchase,
  });

  final EmoticonProduct emoticon;
  final Future<void> Function() onPurchase;

  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color subBrown = Color(0xFF7A6B63);
  static const Color cardBorder = Color(0xFFEFEBE4);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.68,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emoticon.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: deepChocolate,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '구성 이모티콘 ${emoticon.items.length}개',
                          style: const TextStyle(
                            color: subBrown,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${formatPointNumber(emoticon.pricePoint)} P',
                    style: const TextStyle(
                      color: pointCoralRed,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: cardBorder),
            Expanded(
              child: emoticon.items.isEmpty
                  ? const PageMessage(
                icon: Icons.emoji_emotions_outlined,
                message: '등록된 구성 이모티콘이 없습니다.',
              )
                  : GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: emoticon.items.length,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  return ProductImage(
                    imageUrl: emoticon.items[index].imageUrl,
                    icon: Icons.emoji_emotions_outlined,
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: emoticon.items.isEmpty ? null : onPurchase,
                    style: FilledButton.styleFrom(
                      backgroundColor: pointCoralRed,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      '패키지 구매하기',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}