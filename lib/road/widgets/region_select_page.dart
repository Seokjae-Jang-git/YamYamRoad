import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

class RegionSelectPage extends StatefulWidget {
  const RegionSelectPage({super.key});

  @override
  State<RegionSelectPage> createState() => _RegionSelectPageState();
}

class _RegionSelectPageState extends State<RegionSelectPage> {
  // 17개 전국 주요 지역 목록
  static const List<String> _allRegions = [
    '서울',
    '경기',
    '인천',
    '강원',
    '세종',
    '대전',
    '충북',
    '충남',
    '광주',
    '전북',
    '전남',
    '부산',
    '대구',
    '울산',
    '경북',
    '경남',
    '제주',
  ];

  // 한글 지역명과 Firebase Storage (city_img) 내 영문 파일명 매핑
  static const Map<String, String> _regionImageMap = {
    '서울': 'seoul.png',
    '경기': 'gyeonggi.png',
    '인천': 'incheon.png',
    '강원': 'gangwon.png',
    '세종': 'sejong.png',
    '대전': 'daejeon.png',
    '충북': 'chungbuk.png',
    '충남': 'chungnam.png',
    '광주': 'gwangju.png',
    '전북': 'jeonbuk.png',
    '전남': 'jeonnam.png',
    '부산': 'busan.png',
    '대구': 'daegu.png',
    '울산': 'ulsan.png',
    '경북': 'gyeongbuk.png',
    '경남': 'gyeongnam.png',
    '제주': 'jeju.png',
  };

  // 💡 static 정적 캐시: 화면이 닫혀도 메모리에 URL을 영구 기억하여 중복 API 호출을 방지합니다.
  static final Map<String, Future<String>> _urlFutureCache = {};

  // Firebase Storage에서 동적으로 Download URL을 받아오는 메서드
  Future<String> _getRegionImageUrl(String regionName) {
    // 1. 이미 받아온 URL 캐시가 있다면 파이어베이스를 호출하지 않고 즉시 반환
    if (_urlFutureCache.containsKey(regionName)) {
      return _urlFutureCache[regionName]!;
    }

    // 2. 캐시가 없을 때만 딱 한 번 Firebase Storage에 요청
    final fileName = _regionImageMap[regionName] ?? 'seoul.png';
    final future = FirebaseStorage.instance
        .ref('city_img/$fileName')
        .getDownloadURL();

    _urlFutureCache[regionName] = future;
    return future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '지역 선택',
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
        itemCount: _allRegions.length,
        itemBuilder: (context, index) {
          final region = _allRegions[index];

          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                leading: ClipOval(
                  child: FutureBuilder<String>(
                    future: _getRegionImageUrl(region),
                    builder: (context, snapshot) {
                      // 1. Storage에서 Download URL 수신 성공 시
                      if (snapshot.hasData && snapshot.data != null) {
                        return Image.network(
                          snapshot.data!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderContainer();
                          },
                        );
                      }

                      // 2. 로딩 중이거나 에러 발생 시 Fallback
                      return _buildPlaceholderContainer();
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
                  // 선택한 지역명을 메인 화면으로 전달하며 닫기
                  Navigator.pop(context, region);
                },
              ),
              const Divider(
                color: Colors.black12,
                height: 1.0,
                thickness: 0.5,
              ),
            ],
          );
        },
      ),
    );
  }

  // 로딩 중이거나 이미지를 찾을 수 없을 때 노출되는 안전용 🍊 플레이스홀더
  Widget _buildPlaceholderContainer() {
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
  }
}