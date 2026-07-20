import 'package:flutter/material.dart';
import 'widgets/category_tabs.dart';
import 'widgets/sub_filter_chips.dart';
import 'widgets/sorting_bar.dart';
import 'widgets/course_list_card.dart';
import 'widgets/region_select_page.dart';
import 'course_detail_screen.dart';
import 'models/road.dart';
import 'repositories/road_repository.dart';

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

  /// Firestore에서 비동기로 실데이터 가져오는 로직
  Future<void> _fetchRoadsFromFirestore() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isRegionTab = _selectedTab == '지역별';

      final fetchedRoads = await _roadRepository.fetchRoads(
        selectedRegion: isRegionTab ? _selectedFilter : null,
        selectedCategory: !isRegionTab ? _selectedFilter : null,
        sortBy: _selectedSort,
      );

      setState(() {
        _roads = fetchedRoads;
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

  // 피드형 광고 동적 배치 알고리즘 (기존 구조 유지)
  List<Widget> _buildListWithAds(List<Road> listToShow) {
    List<Widget> items = [];

    if (listToShow.isEmpty) {
      items.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 64.0),
          child: Center(
            child: Text(
              '해당 조건에 맞는 코스가 존재하지 않습니다.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ),
      );
      items.add(_buildAdBanner());
      return items;
    }

    // 카드 수가 2개 이하인 경우 바로 밑에 노출
    if (listToShow.length <= 2) {
      for (var road in listToShow) {
        items.add(
          CourseListCard(
            road: road,
            onTap: () => _onCardPressed(road),
          ),
        );
      }
      items.add(_buildAdBanner());
    }
    // 카드 수가 3개 이상인 경우 3개 카드 마다 광고 획득 배치
    else {
      for (int i = 0; i < listToShow.length; i++) {
        final road = listToShow[i];
        items.add(
          CourseListCard(
            road: road,
            onTap: () => _onCardPressed(road),
          ),
        );

        if ((i + 1) % 3 == 0) {
          items.add(_buildAdBanner());
        }
      }
    }

    return items;
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
            // 1. 최상단 대분류 및 검색 버튼 (기존 위젯)
            CategoryTabs(
              selectedTab: _selectedTab,
              onTabChanged: (tab) {
                if (_selectedTab != tab) {
                  setState(() {
                    _selectedTab = tab;
                    _selectedFilter = '전체';
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

            // 2. 가로 스크롤형 동적 필터 칩 영역 (기존 위젯)
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

            // 3. 정렬 상태 제어 바 (기존 위젯)
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

    final uiItems = _buildListWithAds(_roads);

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

  Widget _buildAdBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(4.0),
      ),
      alignment: Alignment.center,
      child: const Text(
        '배너 광고',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}