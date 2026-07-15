import 'package:flutter/material.dart';

class RegionSelectPage extends StatelessWidget {
  const RegionSelectPage({super.key});

  // 🆕 '전체' 항목이 빠진 순수 17개 지역 노선 목록
  static const List<String> _allRegions = [
    '서울', '경기', '인천', '강원', '세종', '대전', '충북', '충남',
    '광주', '전북', '전남', '부산', '대구', '울산', '경북', '경남', '제주'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '지역 선택', // 🆕 '상품/지역 선택' -> '지역 선택' 명칭 간소화 완료
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(color: Colors.grey, height: 1.0, thickness: 0.5),
        ),
      ),
      body: ListView.builder(
        itemCount: _allRegions.length, // 🆕 불필요한 '전체'/'한국' 인덱스가 제거되어 단순화된 루프
        itemBuilder: (context, index) {
          final region = _allRegions[index];

          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: ClipOval(
                  child: Image.asset(
                    'assets/images/seoul.PNG', // 임시 지정된 대표 이미지 파일
                    fit: BoxFit.cover,
                    width: 44,
                    height: 44,
                    errorBuilder: (context, error, stackTrace) {
                      // 에셋 경로 유실 대비 안전장치용 🍊 플레이스홀더
                      return Container(
                        width: 44,
                        height: 44,
                        color: Colors.orange[100],
                        alignment: Alignment.center,
                        child: const Text(
                          '🍊',
                          style: TextStyle(fontSize: 18),
                        ),
                      );
                    },
                  ),
                ),
                title: Text(
                  region,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                onTap: () {
                  // 선택한 지역명을 품고 메인 화면으로 복귀!
                  Navigator.pop(context, region);
                },
              ),
              const Divider(color: Colors.black12, height: 1.0, thickness: 0.5),
            ],
          );
        },
      ),
    );
  }
}