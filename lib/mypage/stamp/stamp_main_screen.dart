import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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
  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color strawberryPink = Color(0xFFFFA09B);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color creamyIvory = Color(0xFFFFFDF9);
  static const Color subTextColor = Color(0xFF7A6B63);

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

  void _openMenuSelectModal() async {
    final List<String> menuOptions = _dbMenuFilters;

    final String? selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: creamyIvory,
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
                  const Text(
                    '메뉴 선택',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: deepChocolate,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: deepChocolate),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(color: deepChocolate.withOpacity(0.12)),
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
                          selectedColor: pointCoralRed,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : deepChocolate,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected ? pointCoralRed : deepChocolate.withOpacity(0.15),
                            ),
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

  List<Map<String, dynamic>> _processRoads(List<Map<String, dynamic>> rawList) {
    List<Map<String, dynamic>> result = List.from(rawList);

    if (_selectedTab == '지역별') {
      result = result.where((r) => r['region'] != null && r['region'].toString().trim().isNotEmpty).toList();
    } else if (_selectedTab == '메뉴별') {
      result = result.where((r) => r['region'] == null || r['region'].toString().trim().isEmpty).toList();
    }

    if (_selectedFilter != '전체') {
      if (_selectedTab == '지역별') {
        result = result.where((r) => r['region'] == _selectedFilter).toList();
      } else if (_selectedTab == '메뉴별') {
        result = result.where((r) {
          final categoryList = r['categoryIds'];
          if (categoryList is List && categoryList.contains(_selectedFilter)) return true;
          return false;
        }).toList();
      }
    }

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

  void _showStampBoardModal(Map<String, dynamic> roadData) async {
    final List<dynamic> placeIds = roadData['roadPlace'] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: creamyIvory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return FutureBuilder<List<dynamic>>(
          future: Future.wait([
            StampRepository.getMyStampsMap(),
            StampRepository.getPlaceNames(placeIds),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator(color: deepChocolate)),
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: deepChocolate,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: deepChocolate),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Divider(color: deepChocolate.withOpacity(0.12)),
                  const SizedBox(height: 10),

                  if (placeIds.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          '등록된 매장이 없습니다.',
                          style: TextStyle(color: subTextColor),
                        ),
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
                              border: Border.all(color: deepChocolate.withOpacity(0.12)),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                            ),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(4),
                            child: isStamped
                                ? _buildRedStampUI(stampData, storeName)
                                : Text(
                              storeName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: deepChocolate,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
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
          border: Border.all(color: pointCoralRed, width: 2.0),
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: pointCoralRed,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dateStr,
              style: const TextStyle(color: pointCoralRed, fontSize: 8),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamyIvory,
      appBar: AppBar(
        title: const Text(
          '스탬프',
          style: TextStyle(color: deepChocolate, fontWeight: FontWeight.bold),
        ),
        backgroundColor: creamyIvory,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: deepChocolate),
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

            SubFilterChips(
              selectedTab: _selectedTab,
              selectedFilter: _selectedFilter,
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
                    return const Center(child: CircularProgressIndicator(color: deepChocolate));
                  }

                  final rawList = snapshot.data ?? [];
                  final processedList = _processRoads(rawList);

                  if (processedList.isEmpty) {
                    return const Center(
                      child: Text(
                        '조건에 해당하는 스탬프 로드가 없습니다.',
                        style: TextStyle(color: subTextColor),
                      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? pointCoralRed : subTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 3,
              width: 36,
              decoration: BoxDecoration(
                color: isSelected ? pointCoralRed : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStampCourseCard(Map<String, dynamic> road) {
    int totalStampCount = 0;

    if (road['placeCount'] != null && road['placeCount'] is int) {
      totalStampCount = road['placeCount'];
    } else {
      final List<dynamic> places = road['roadPlace'] ?? road['placeIds'] ?? [];
      totalStampCount = places.length;
    }

    final int myStampCount = road['myStampCount'] ?? 0;
    final String imageUrl = road['imageUrl'] ?? road['thumbnailUrl'] ?? road['thumbnail'] ?? '';

    return GestureDetector(
      onTap: () => _showStampBoardModal(road),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: deepChocolate.withOpacity(0.12)),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: deepChocolate.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: creamyIvory,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.hardEdge,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Text('사진 없음', style: TextStyle(color: subTextColor, fontSize: 11)),
                ),
              )
                  : const Center(
                child: Text('코스사진', style: TextStyle(color: subTextColor, fontSize: 11)),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: deepChocolate,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.verified,
                        size: 16,
                        color: pointCoralRed,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '스탬프 $myStampCount / $totalStampCount 개',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: deepChocolate,
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