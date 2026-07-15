import 'package:flutter/material.dart';

class AdRewardCard extends StatelessWidget {
  final String title;
  final String specs;
  final String reward;
  final VoidCallback onTap;
  final bool isSponsor;

  const AdRewardCard({
    super.key,
    required this.title,
    required this.specs,
    required this.reward,
    required this.onTap,
    required this.isSponsor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey[200]!, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                // 썸네일 박스 영역
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: isSponsor ? Colors.orange[50] : Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSponsor ? Colors.orange[100]! : Colors.blue[100]!,
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isSponsor ? 'SPONSOR' : 'AD\nMOB',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isSponsor ? Colors.orange[800] : Colors.blue[800],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 광고 상세 설명 텍스트
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        specs,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 보상 및 버튼 영역
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '보상포인트: $reward',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSponsor ? Colors.orange[800] : Colors.blue[800],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSponsor ? Colors.orange : Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: 0,
                  ),
                  onPressed: onTap,
                  child: Text(
                    isSponsor ? '스폰서 영상 시청' : '광고 시청하기',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}