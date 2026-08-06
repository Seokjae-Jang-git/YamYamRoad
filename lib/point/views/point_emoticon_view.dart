import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../logic/point_repository.dart';
import '../models/point_models.dart';
import '../widgets/point_emoticon_widgets.dart';
import '../widgets/point_shop_common.dart';

/// 이모티콘 탭 화면 View
class PointEmoticonView extends StatelessWidget {
  const PointEmoticonView({
    super.key,
    required this.repository,
    required this.userId,
    required this.onSelectEmoticon,
    required this.onOpenAiRecommendationPage,
    required this.onOpenStampDevPage,
  });

  final PointShopRepository repository;
  final String userId;
  final ValueChanged<EmoticonProduct> onSelectEmoticon;
  final VoidCallback onOpenAiRecommendationPage;
  final VoidCallback onOpenStampDevPage;

  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color cardBorder = Color(0xFFEFEBE4);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EmoticonProduct>>(
      stream: repository.watchEmoticons(userId),
      builder: (context, snapshot) {
        return Column(
          children: [
            Expanded(
              child: AsyncContent<List<EmoticonProduct>>(
                snapshot: snapshot,
                emptyMessage: '판매 중인 이모티콘이 없습니다.',
                builder: (emoticons) {
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: emoticons.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.74,
                        ),
                    itemBuilder: (context, index) {
                      final emoticon = emoticons[index];
                      return EmoticonThumbnail(
                        emoticon: emoticon,
                        onTap: emoticon.isPurchased
                            ? null
                            : () => onSelectEmoticon(emoticon),
                      );
                    },
                  );
                },
              ),
            ),
            if (kDebugMode)
              SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: onOpenAiRecommendationPage,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: deepChocolate,
                          side: const BorderSide(color: cardBorder),
                        ),
                        icon: const Icon(Icons.auto_awesome_outlined),
                        label: const Text('AI 추천 페이지 테스트'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: onOpenStampDevPage,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: deepChocolate,
                          side: const BorderSide(color: cardBorder),
                        ),
                        icon: const Icon(Icons.bug_report_outlined),
                        label: const Text('개발용 스탬프 테스트'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
