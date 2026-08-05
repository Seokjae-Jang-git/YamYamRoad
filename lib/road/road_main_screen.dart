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
  RoadMainScreenState createState() => RoadMainScreenState();
}

class RoadMainScreenState extends State<RoadMainScreen> {
  // YamYamRoad 브랜드 공식 컬러 상수 정의
  static const Color pointCoralRed = Color(0xFFFF6B57);    // 시그니처 코랄 레드
  static const Color deepChocolate = Color(0xFF4A3225);    // 텍스트 & 아이콘 메인
  static const Color creamyIvory = Color(0xFFFFFDF9);      // 화면 바탕 크림 아이보리
  static const Color subTextColor = Color(0xFF7A6B63);      // 서브 브라운 텍스트

  final RoadRepository _roadRepository = RoadRepository();
  final ScrollController _scrollController = ScrollController();

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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 🌟 상단 탭 재클릭 시 리스트를 최상단으로 부드럽게 스크롤하는 메서드
  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
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
      backgroundColor: creamyIvory,
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
      return const Center(
        child: CircularProgressIndicator(color: deepChocolate),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: pointCoralRed, fontSize: 13),
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
      color: pointCoralRed,
      backgroundColor: Colors.white,
      onRefresh: _fetchRoadsFromFirestore,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: uiItems.length,
        itemBuilder: (context, index) {
          return uiItems[index];
        },
      ),
    );
  }
}