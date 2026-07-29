import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // 날짜 포맷용
import 'repository/stamp_repository.dart';
import 'widgets/sub_filter_chips.dart';
import 'widgets/sorting_bar.dart';
import '../../../../road/widgets/region_select_page.dart';
class StampMainScreen extends StatefulWidget {
  const StampMainScreen({super.key});

  @override
  State<StampMainScreen> createState() => _StampMainScreenState();
}

class _StampMainScreenState extends State<StampMainScreen> {
  String _selectedTab = '지역별';
  String _selectedFilter = '전체';
  String _selectedSort = '최신순';

  List<String> _dbMenuFilters = ['전체'];
  List<String> _dbRegionFilters = ['전체'];

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndRegions(); // 🌟 화면 시작 시 DB 데이터 동시 로드
  }

  void _loadCategoriesAndRegions() async {
    final categories = await StampRepository.getCategoryNames();
    final regions = await StampRepository.getRegionNames();
    if (mounted) {
      setState(() {
        _dbMenuFilters = categories;
        _dbRegionFilters = regions; // DB 지역 세팅
      });
    }
  }

  // 1. 🌟 메뉴 더보기 팝업 모달
  void _openMenuSelectModal() async {
    final List<String> menuOptions = _dbMenuFilters;

    final String? selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('메뉴 선택', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: menuOptions.map((menu) {
                        final bool isSelected = menu == _selectedFilter;
                        return ChoiceChip(
                          showCheckmark: false,
                          label: Text(menu),
                          selected: isSelected,
                          selectedColor: Colors.orange[50],
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.orange[800] : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (_) => Navigator.pop(context, menu),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      setState(() => _selectedFilter = selected);
    }
  }

  // 2. 🌟 지역 더보기 팝업 모달
  // 🌟 기존 모달창을 띄우던 코드를 지우고, RegionSelectPage 호출로 변경
  Future<void> _openRegionSelectModal() async {
    // 1. 지역 선택 페이지로 이동
    final selectedRegion = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegionSelectPage(),
      ),
    );

    // 2. 사용자가 지역을 선택하고 돌아왔다면(뒤로가기 취소가 아니라면) 필터 상태 업데이트
    if (selectedRegion != null && selectedRegion is String) {
      setState(() {
        _selectedFilter = selectedRegion;
      });
    }
  }

  // 3. 필터링 및 정렬 처리 함수
  List<Map<String, dynamic>> _processRoads(List<Map<String, dynamic>> rawList) {
    List<Map<String, dynamic>> result = List.from(rawList);

    // 필터링 처리
    if (_selectedFilter != '전체') {
      if (_selectedTab == '지역별') {
        result = result.where((r) => r['region'] == _selectedFilter).toList();
      } else if (_selectedTab == '메뉴별') {
        result = result.where((r) {
          // 🌟 categoryIds -> categoryNames 로 수정! (한글 이름 매칭)
          final List categories = r['categoryNames'] ?? [];
          return categories.contains(_selectedFilter);
        }).toList();
      }
    }

    // 정렬
    if (_selectedSort == '최신순') {
      result.sort((a, b) {
        final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
    } else if (_selectedSort == '이름순') {
      result.sort((a, b) => (a['title'] ?? '').toString().compareTo((b['title'] ?? '').toString()));
    } else if (_selectedSort == '스탬프 순') {
      // 내 스탬프 달성 수 기준 내림차순
      result.sort((a, b) => (b['myStampCount'] ?? 0).compareTo(a['myStampCount'] ?? 0));
    }

    return result;
  }

  // 4. 스탬프 판 팝업 모달 (실제 업체 이름 연동)
  void _showStampBoardModal(Map<String, dynamic> roadData) async {
    final List<dynamic> placeIds = roadData['placeIds'] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // 내 스탬프 맵과 업체 이름 맵을 동시에 미래(Future)로 불러옵니다.
        return FutureBuilder<List<dynamic>>(
          future: Future.wait([
            StampRepository.getMyStampsMap(),
            StampRepository.getPlaceNames(placeIds),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator(color: Colors.black)),
              );
            }

            final results = snapshot.data ?? [{}, {}];
            final myStampsMap = results[0] as Map<String, Map<String, dynamic>>;
            final placeNamesMap = results[1] as Map<String, String>;

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 모달 헤더
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        roadData['title'] ?? '스탬프 판',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),

                  // 3x3 스탬프 그리드 판
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: placeIds.length,
                      itemBuilder: (context, index) {
                        final String placeId = placeIds[index].toString();
                        final bool isStamped = myStampsMap.containsKey(placeId);

                        // 🌟 DB에서 가져온 실제 업체 이름 (없으면 매장 번호로 대체)
                        final String storeName = placeNamesMap[placeId] ?? '매장 ${index + 1}';

                        // 스탬프 데이터에 storeName이 없다면 실제 상호명을 쏙 넣어줍니다.
                        final stampData = myStampsMap[placeId];
                        if (stampData != null && (stampData['placeName'] == null || stampData['placeName'].toString().isEmpty)) {
                          stampData['placeName'] = storeName;
                        }

                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade50,
                          ),
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(4),
                          child: isStamped
                              ? _buildRedStampUI(stampData, storeName) // 🌟 실제 업체 이름 전달
                              : Text(
                            storeName, // 🌟 '매장 1' 대신 실제 업체 이름 출력
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 5. 붉은색 동그라미 도장 UI 렌더링 함수
  Widget _buildRedStampUI(Map<String, dynamic>? stampData, String storeName) {
    String dateStr = '';
    if (stampData != null && stampData['issuedAt'] != null) {
      final DateTime dt = (stampData['issuedAt'] as Timestamp).toDate();
      dateStr = DateFormat('yy.MM.dd').format(dt);
    }

    // 🌟 stampData에 저장된 이름이 있거나, 전달받은 storeName을 사용
    final String displayName = stampData?['placeName'] ?? storeName;

    return Transform.rotate(
      angle: -0.12, // 도장을 약간 비스듬하게 쾅 찍은 효과
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.red.shade700, width: 2.0),
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              displayName, // 🌟 '스탬프' 대신 실제 업체 이름 출력
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dateStr,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('스탬프', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🌟 1. 최상단: 대분류 탭(좌측) + 정렬 옵션(우측)을 한 Row 안에 배치!
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                // 🌟 CrossAlignment -> CrossAxisAlignment 로 수정!
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 좌측: 지역별 / 메뉴별 탭
                  Row(
                    children: [
                      _buildTabButton('지역별'),
                      _buildTabButton('메뉴별'),
                    ],
                  ),

                  // 우측: 정렬 옵션
                  SortingBar(
                    selectedSort: _selectedSort,
                    onSortChanged: (sort) => setState(() => _selectedSort = sort),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 2. 가로 서브 필터 칩 (DB 지역 리스트 전달)
            SubFilterChips(
              selectedTab: _selectedTab,
              selectedFilter: _selectedFilter,
              menuFilters: _dbMenuFilters,
              onFilterSelected: (filter) => setState(() => _selectedFilter = filter),
              onMorePressed: _selectedTab == '지역별' ? _openRegionSelectModal : _openMenuSelectModal,
            ),
            const SizedBox(height: 8),

            // 3. 실시간 DB 연결 리스트 렌더링
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: StampRepository.getRoadWithMyStampStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.black));
                  }

                  final rawList = snapshot.data ?? [];
                  final processedList = _processRoads(rawList);

                  if (processedList.isEmpty) {
                    return const Center(
                      child: Text('조건에 해당하는 스탬프 로드가 없습니다.', style: TextStyle(color: Colors.grey)),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: processedList.length,
                    itemBuilder: (context, index) {
                      final road = processedList[index];
                      return _buildStampCourseCard(road);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 상단 대분류 탭 버튼
  Widget _buildTabButton(String label) {
    final bool isSelected = _selectedTab == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = label;
          _selectedFilter = '전체';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.orange : Colors.transparent,
              width: 2.0,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.orange : Colors.grey,
          ),
        ),
      ),
    );
  }

  // 스탬프 로드 카드 뷰 (이미지 적용, 설명 제거, 오버플로우 원천 차단)
  Widget _buildStampCourseCard(Map<String, dynamic> road) {
    final int myStampCount = road['myStampCount'] ?? 0;
    final int totalStampCount = road['totalStampCount'] ?? 0;
    final String imageUrl = road['imageUrl'] ?? '';

    return GestureDetector(
      onTap: () => _showStampBoardModal(road),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 코스 사진 영역
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              clipBehavior: Clip.hardEdge,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Text('사진 없음', style: TextStyle(color: Colors.grey, fontSize: 11)),
                ),
              )
                  : const Center(
                child: Text('코스사진', style: TextStyle(color: Colors.grey, fontSize: 11)),
              ),
            ),
            const SizedBox(width: 12),

            // 2. 로드 정보 영역 (Expanded 덕분에 우측으로 절대 삐져나가지 않음)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 4),
                  // 제목
                  Text(
                    road['title'] ?? '제목 없음',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // 🌟 [수정됨] 문제가 되던 Row를 아예 없애고 단일 Text로 묶었습니다!
                  Row(
                    children: [
                      Icon(
                        Icons.verified, // 또는 Icons.approval, Icons.workspace_premium
                        size: 16,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '스탬프 $myStampCount / $totalStampCount 개',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}