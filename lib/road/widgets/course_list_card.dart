import 'package:flutter/material.dart';
import '../models/road.dart';

/// 로드(코스) 목록에서 개별 코스 항목을 보여주는 카드 위젯
class CourseListCard extends StatelessWidget {
  final Road road;
  final VoidCallback? onTap;

  const CourseListCard({
    super.key,
    required this.road,
    this.onTap,
  });

  // YamYamRoad 브랜드 공식 컬러 상수 정의
  static const Color deepChocolate = Color(0xFF4A3225); // 텍스트 및 메인 포인트
  static const Color subBrown = Color(0xFF7A6B63);      // 서브 브라운 텍스트 및 아이콘
  static const Color cardBorder = Color(0xFFEFEBE4);    // 따뜻한 톤의 카드 테두리
  static const Color placeholderBg = Color(0xFFF2ECE4);  // 플레이스홀더 배경
  static const Color placeholderIcon = Color(0xFFA89A91);// 플레이스홀더 아이콘

  @override
  Widget build(BuildContext context) {
    // roadPlace 리스트의 길이를 기반으로 가게 수 연산
    final int placeCount = road.roadPlace.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.0),
        side: const BorderSide(color: cardBorder, width: 1.0),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.0),
        splashColor: deepChocolate.withOpacity(0.05),
        highlightColor: deepChocolate.withOpacity(0.02),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. 썸네일 이미지 영역
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: road.thumbnailUrl.isNotEmpty
                    ? Image.network(
                  road.thumbnailUrl,
                  width: 68,
                  height: 68,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildImagePlaceholder(),
                )
                    : _buildImagePlaceholder(),
              ),
              const SizedBox(width: 14.0),

              // 2. 텍스트 정보 영역 (제목 + 가게 수 + 설명)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 제목 줄 & 가게 수 (🍽 N곳)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 코스 제목 (길어지면 자동 말줄임)
                        Expanded(
                          child: Text(
                            road.title,
                            style: const TextStyle(
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                              color: deepChocolate,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8.0),

                        // 가게 수 표시 태그 (🍽 N곳)
                        Text(
                          '🍽 $placeCount곳',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: subBrown,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5.0),

                    // 코스 설명글 (최대 2줄 노출 후 말줄임)
                    Text(
                      road.description,
                      style: const TextStyle(
                        fontSize: 12.0,
                        color: subBrown,
                        height: 1.35,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 이미지 로딩 실패 시 표시할 대체 박스
  Widget _buildImagePlaceholder() {
    return Container(
      width: 68,
      height: 68,
      color: placeholderBg,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: placeholderIcon,
        size: 26,
      ),
    );
  }
}