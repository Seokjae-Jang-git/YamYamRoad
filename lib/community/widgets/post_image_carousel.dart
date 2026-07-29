import 'package:flutter/material.dart';

/// 🌟 게시글 이미지 여러 장을 좌우로 넘겨볼 수 있는 캐러셀.
/// 메인 피드(community_main.dart)와 상세 페이지(post_content_widget.dart)에서 공용으로 씁니다.
class PostImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final double height;

  const PostImageCarousel({
    Key? key,
    required this.imageUrls,
    this.height = 220,
  }) : super(key: key);

  @override
  State<PostImageCarousel> createState() => _PostImageCarouselState();
}

class _PostImageCarouselState extends State<PostImageCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: widget.height,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.imageUrls.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => Image.network(
                widget.imageUrls[i],
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade100,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
        if (widget.imageUrls.length > 1) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.imageUrls.length, (i) {
              final active = i == _index;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: active ? 6 : 5,
                height: active ? 6 : 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? const Color(0xFFFF8A3D) : Colors.grey.shade300,
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
