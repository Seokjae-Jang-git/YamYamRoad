import 'package:flutter/material.dart';
import '../data/road_mock_data.dart'; // 🆕 분리된 데이터 모델 파일을 상대경로로 안전하게 임포트합니다.

class CourseListCard extends StatelessWidget {
  final CourseData course;
  final VoidCallback onTap;

  const CourseListCard({
    super.key,
    required this.course,
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
              // 가상 관리자 수급 사진 영역
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey[200]!),
                ),
                alignment: Alignment.center,
                child: Text(
                  '코스사진',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ),
              const SizedBox(width: 14),
              // 코스 정보 및 스탬프 수량 컴팩트 정렬 영역
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${course.description}  ·  🍒 스탬프 ${course.stampCount}개',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // 완료한 코스일 때 보여주는 🍊 귤 배너 데코레이션
              if (course.isCompleted)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '🍊',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}