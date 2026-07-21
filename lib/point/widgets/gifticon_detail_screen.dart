import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/point_models.dart';

class GifticonDetailScreen extends StatelessWidget {
  const GifticonDetailScreen({
    super.key,
    required this.gifticon,
    required this.onPurchase,
  });

  final GifticonProduct gifticon;
  final Future<void> Function() onPurchase;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF222222),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          '기프티콘 상세',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE5E5E5)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: _GifticonDetailImage(imageUrl: gifticon.imageUrl),
          ),
          const SizedBox(height: 24),
          if (gifticon.brandName?.isNotEmpty == true) ...[
            Text(
              gifticon.brandName!,
              style: const TextStyle(
                color: Color(0xFF777777),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            gifticon.name,
            style: const TextStyle(
              color: Color(0xFF222222),
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${_formatPoint(gifticon.requiredPoint)} P',
                style: const TextStyle(
                  color: Color(0xFF2468D8),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              _AvailabilityBadge(isSoldOut: gifticon.isSoldOut),
            ],
          ),
          const SizedBox(height: 28),
          const Divider(height: 1, color: Color(0xFFE5E5E5)),
          const SizedBox(height: 24),
          const _DetailSection(
            title: '상품 정보',
            messages: [
              '보유 포인트를 사용해 교환하는 모바일 기프티콘입니다.',
              '구매하기 전에 상품명과 브랜드를 확인해 주세요.',
            ],
          ),
          const SizedBox(height: 28),
          const _DetailSection(
            title: '이용 안내',
            messages: [
              '상품 발행이 완료된 이후에는 취소 및 환불이 제한될 수 있습니다.',
              '브랜드 정책에 따라 실제 상품의 구성이나 이용 조건이 달라질 수 있습니다.',
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: gifticon.isSoldOut
                  ? null
                  : () async {
                      await onPurchase();
                    },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4D8DFF),
                disabledBackgroundColor: const Color(0xFFD5D5D5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                gifticon.isSoldOut
                    ? '품절된 상품입니다'
                    : '${_formatPoint(gifticon.requiredPoint)}P로 구매하기',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GifticonDetailImage extends StatelessWidget {
  const _GifticonDetailImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: url == null || url.isEmpty
          ? const Center(
              child: Icon(
                Icons.card_giftcard_outlined,
                size: 72,
                color: Color(0xFFAAAAAA),
              ),
            )
          : Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Center(
                child: Icon(
                  Icons.card_giftcard_outlined,
                  size: 72,
                  color: Color(0xFFAAAAAA),
                ),
              ),
            ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge({required this.isSoldOut});

  final bool isSoldOut;

  @override
  Widget build(BuildContext context) {
    final foreground = isSoldOut
        ? const Color(0xFFE05252)
        : const Color(0xFF287A45);
    final background = isSoldOut
        ? const Color(0xFFFFEEEE)
        : const Color(0xFFECF8F0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isSoldOut ? '품절' : '구매 가능',
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.messages});

  final String title;
  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...messages.map(
          (message) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: CircleAvatar(
                    radius: 2,
                    backgroundColor: Color(0xFF777777),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _formatPoint(int value) =>
    NumberFormat.decimalPattern('ko_KR').format(value);
