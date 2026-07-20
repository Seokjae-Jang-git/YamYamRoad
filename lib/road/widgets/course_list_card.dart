import 'package:flutter/material.dart';
import '../models/road.dart';

class CourseListCard extends StatelessWidget {
  final Road road;
  final VoidCallback onTap;

  const CourseListCard({
    super.key,
    required this.road,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey[200]!, width: 1.0),
        borderRadius: BorderRadius.circular(4.0),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // 코스 대표 이미지 (Firestore URL 또는 가상 박스)
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey[200]!),
                ),
                alignment: Alignment.center,
                child: road.imageUrl.isNotEmpty
                    ? Image.network(
                  road.imageUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildPlaceholderText(),
                )
                    : _buildPlaceholderText(),
              ),
              const SizedBox(width: 14),
              // 코스 정보 및 스탬프 수량 컴팩트 정렬 영역
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      road.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${road.description.isNotEmpty ? road.description : "${road.region} 코스"}  ·  🍒 스탬프 ${road.rewardPoints}개',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
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

  Widget _buildPlaceholderText() {
    return Text(
      '코스사진',
      style: TextStyle(color: Colors.grey[500], fontSize: 11),
    );
  }
}