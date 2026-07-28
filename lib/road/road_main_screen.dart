import 'package:flutter/material.dart';
import '../../common/utils/region_mapper.dart';
import 'widgets/category_tabs.dart';
import 'widgets/sub_filter_chips.dart';
import 'widgets/sorting_bar.dart';
import 'widgets/region_select_page.dart';
import 'course_detail_screen.dart';
import 'models/road.dart';
import 'repositories/road_repository.dart';
import 'utils/road_ad_helper.dart';

class RoadMainScreen extends StatefulWidget {
  const RoadMainScreen({super.key});

  @override
  State<RoadMainScreen> createState() => _RoadMainScreenState();
}

class _RoadMainScreenState extends State<RoadMainScreen> {
  final RoadRepository _roadRepository = RoadRepository();

  String _selectedTab = '지역별';
  String _selectedFilter = '전체';
  String _selectedSort = '최신순';

  List<Road> _roads = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRoadsFromFirestore();
  }

  /// Firestore에서 비동기로 실데이터 가져오는 로직 (type 분기 및 RegionMapper 연동)
  Future<void> _fetchRoadsFromFirestore() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isRegionTab = _selectedTab == '지역별';
      final targetType = isRegionTab ? 'region' : 'category';

      // 💡 탭 종류('region' / 'category')에 따른 Firestore 데이터 분기 조회
      final fetchedRoads = await _roadRepository.fetchRoads(
        type: targetType,
        selectedRegion: null, // 지역별은 아래의 RegionMapper로 유연하게 처리
        selectedCategory: !isRegionTab ? _selectedFilter : null,
        sortBy: _selectedSort,
      );

      List<Road> filteredRoads = fetchedRoads;

      // '지역별' 탭이고 선택된 필터가 '전체'가 아닌 경우 (예: '충북') RegionMapper 매핑 검사
      if (isRegionTab && _selectedFilter != '전체') {
        filteredRoads = fetchedRoads.where((road) {
          // 1. regionId 매핑 검사 ('충북' <-> '충청북도')
          final regionIdMatch = RegionMapper.isMatch(
            selectedRegion: _selectedFilter,
            targetText: road.regionId,
          );
          // 2. title 매핑 검사
          final titleMatch = RegionMapper.isMatch(
            selectedRegion: _selectedFilter,
            targetText: road.title,
          );
          // 3. description 매핑 검사
          final descriptionMatch = RegionMapper.isMatch(
            selectedRegion: _selectedFilter,
            targetText: road.description,
          );
          // 4. searchKeywords 매핑 검사
          final keywordsMatch = road.searchKeywords.any(
                (kw) => RegionMapper.isMatch(
              selectedRegion: _selectedFilter,
              targetText: kw,
            ),
          );

          return regionIdMatch || titleMatch || descriptionMatch || keywordsMatch;
        }).toList();
      }

      setState(() {
        _roads = filteredRoads;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '데이터를 불러오지 못했습니다: $e';
        _isLoading = false;
      });
    }
  }

  // '지역 더보기' 전체 화면 선택 창 띄우기 로직
  void _openRegionSelectPage() async {
    final String? selectedRegion = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const RegionSelectPage(),
        fullscreenDialog: true,
      ),
    );

    if (selectedRegion != null) {
      setState(() {
        _selectedFilter = selectedRegion;
      });
      _fetchRoadsFromFirestore();
    }
  }

  void _onCardPressed(Road road) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseDetailScreen(road: road),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. 최상단 대분류 및 검색 버튼
            CategoryTabs(
              selectedTab: _selectedTab,
              onTabChanged: (tab) {
                if (_selectedTab != tab) {
                  setState(() {
                    _selectedTab = tab;
                    _selectedFilter = '전체'; // 탭 전환 시 서브 필터 초기화
                  });
                  _fetchRoadsFromFirestore();
                }
              },
              onSearchPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('검색 페이지 연동 예정입니다.')),
                );
              },
            ),

            const SizedBox(height: 4),

            // 2. 가로 스크롤형 동적 필터 칩 영역
            SubFilterChips(
              selectedTab: _selectedTab,
              selectedFilter: _selectedFilter,
              onFilterSelected: (filter) {
                if (_selectedFilter != filter) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                  _fetchRoadsFromFirestore();
                }
              },
              onMorePressed: _openRegionSelectPage,
            ),

            const SizedBox(height: 4),

            // 3. 정렬 상태 제어 바
            SortingBar(
              selectedSort: _selectedSort,
              onSortChanged: (sort) {
                if (_selectedSort != sort) {
                  setState(() {
                    _selectedSort = sort;
                  });
                  _fetchRoadsFromFirestore();
                }
              },
            ),

            // 4. Firestore 리스트 렌더링 영역
            Expanded(
              child: _buildListContent(),
            ),
          ],
        ),
      ),
    );
  }

  /// 로딩 / 에러 / 실데이터 연동 영역
  Widget _buildListContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final uiItems = RoadAdHelper.buildListWithAds(
      listToShow: _roads,
      onCardPressed: _onCardPressed,
    );

    return RefreshIndicator(
      onRefresh: _fetchRoadsFromFirestore,
      child: ListView.builder(
        itemCount: uiItems.length,
        itemBuilder: (context, index) {
          return uiItems[index];
        },
      ),
    );
  }
}