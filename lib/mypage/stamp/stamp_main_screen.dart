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
    _loadCategoriesAndRegions();
  }

  void _loadCategoriesAndRegions() async {
    final categories = await StampRepository.getCategoryNames();
    final regions = await StampRepository.getRegionNames();
    if (mounted) {
      setState(() {
        _dbMenuFilters = categories;
        _dbRegionFilters = regions;
      });
    }
  }

  // 1. 메뉴 더보기 팝업 모달
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

  // 2. 지역 더보기 팝업 모달
  Future<void> _openRegionSelectModal() async {
    final selectedRegion = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegionSelectPage(),
      ),
    );

    if (selectedRegion != null && selectedRegion is String) {
      setState(() {
        _selectedFilter = selectedRegion;
      });
    }
  }

  // 3. 필터링 및 정렬 처리 함수
  List<Map<String, dynamic>> _processRoads(List<Map<String, dynamic>> rawList) {
    List<Map<String, dynamic>> result = List.from(rawList);

    // 1차 필터링: region 필드 유무로 지역 로드 / 메뉴 로드 분리
    if (_selectedTab == '지역별') {
      result = result.where((r) => r['region'] != null && r['region'].toString().trim().isNotEmpty).toList();
    } else if (_selectedTab == '메뉴별') {
      result = result.where((r) => r['region'] == null || r['region'].toString().trim().isEmpty).toList();
    }

    // 🌟 2차 필터링: 하위 필터
    if (_selectedFilter != '전체') {
      if (_selectedTab == '지역별') {
        result = result.where((r) => r['region'] == _selectedFilter).toList();
      } else if (_selectedTab == '메뉴별') {
        result = result.where((r) {
          // 🌟 categoryIds 배열을 사용하여 필터링
          final categoryList = r['categoryIds'];
          if (categoryList is List && categoryList.contains(_selectedFilter)) return true;
          return false;
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
      result.sort((a, b) => (b['myStampCount'] ?? 0).compareTo(a['myStampCount'] ?? 0));
    }

    return result;
  }

  // 스탬프 판 팝업 모달
  void _showStampBoardModal(Map<String, dynamic> roadData) async {
    // 🌟 roadPlace 필드 사용
    final List<dynamic> placeIds = roadData['roadPlace'] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FutureBuilder<List<dynamic>>(
          future: Future.wait([
            StampRepository.getMyStampsMap(),
            // 💡 주의: StampRepository.getPlaceNames 내부 로직이 placeIds 리스트를 받아 'place' 컬렉션에서 상호명을 조회하도록 구현되어 있어야 합니다.
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

                  if (placeIds.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text('등록된 매장이 없습니다.', style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
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
                          final String storeName = placeNamesMap[placeId] ?? '매장 ${index + 1}';

                          final stampData = myStampsMap[placeId] ?? {};
                          if (stampData['placeName'] == null || stampData['placeName'].toString().isEmpty) {
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
                                ? _buildRedStampUI(stampData, storeName)
                                : Text(
                              storeName,
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

  // 5. 붉은색 동그라미 도장 UI
  Widget _buildRedStampUI(Map<String, dynamic>? stampData, String storeName) {
    String dateStr = '';
    if (stampData != null && stampData['issuedAt'] != null) {
      final DateTime dt = (stampData['issuedAt'] as Timestamp).toDate();
      dateStr = DateFormat('yy.MM.dd').format(dt);
    }

    final String displayName = stampData?['placeName'] ?? storeName;

    return Transform.rotate(
      angle: -0.12,
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
              displayName,
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
              style: TextStyle(color: Colors.red.shade700, fontSize: 8),
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
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      _buildTabButton('지역별'),
                      _buildTabButton('메뉴별'),
                    ],
                  ),
                  SortingBar(
                    selectedSort: _selectedSort,
                    onSortChanged: (sort) => setState(() => _selectedSort = sort),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 가로 서브 필터 칩
            SubFilterChips(
              selectedTab: _selectedTab,
              selectedFilter: _selectedFilter,
              // 💡 팁: 만약 여기서 지역칩이 안 보인다면, SubFilterChips 내부에
              // 지역 필터 배열을 받는 속성도 추가되어야 완벽하게 작동할 수 있습니다.
              menuFilters: _dbMenuFilters,
              onFilterSelected: (filter) => setState(() => _selectedFilter = filter),
              onMorePressed: _selectedTab == '지역별' ? _openRegionSelectModal : _openMenuSelectModal,
            ),
            const SizedBox(height: 8),

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

  // 스탬프 로드 카드 뷰
  Widget _buildStampCourseCard(Map<String, dynamic> road) {
    // 🌟 1. 전체 스탬프 개수 계산 로직
    int totalStampCount = 0;

    // 지역 로드: placeCount 필드가 있으면 그 값을 사용
    if (road['placeCount'] != null && road['placeCount'] is int) {
      totalStampCount = road['placeCount'];
    }
    // 메뉴 로드: placeCount가 없으면 roadPlace(또는 placeIds) 배열의 길이를 사용
    else {
      final List<dynamic> places = road['roadPlace'] ?? road['placeIds'] ?? [];
      totalStampCount = places.length;
    }

    // 🌟 2. 획득한 스탬프 개수
    final int myStampCount = road['myStampCount'] ?? 0;

    // 🌟 3. 이미지 URL (지역은 imageUrl, 메뉴는 thumbnailUrl 대응)
    final String imageUrl = road['imageUrl'] ?? road['thumbnailUrl'] ?? road['thumbnail'] ?? '';

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

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    road['title'] ?? '제목 없음',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(
                        Icons.verified,
                        size: 16,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        // 🌟 0/0 오류 완벽 해결!
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