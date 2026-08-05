import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  // 브랜드 공식 컬러 상수 정의
  static const Color pointCoralRed = Color(0xFFFF6B57);    // 시그니처 코랄 레드
  static const Color deepChocolate = Color(0xFF4A3225);    // 텍스트 & 아이콘 메인
  static const Color creamyIvory = Color(0xFFFFFDF9);      // 화면 바탕 크림 아이보리

  final RoadRepository _roadRepository = RoadRepository();
  final ScrollController _scrollController = ScrollController();

  String _selectedTab = '지역별';
  String _selectedFilter = '전체';
  String _selectedSort = '최신순';

  List<Road> _roads = [];
  bool _isLoading = true;          // 첫 데이터 로딩 상태
  bool _isFetchingMore = false;     // 하단 스크롤 시 추가 데이터 로딩 상태
  bool _hasMore = true;             // 다음 DB 데이터 존재 여부
  DocumentSnapshot? _lastDocument;  // 커서 페이징을 위한 마지막 문서 Snapshot
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchInitialRoads();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 스크롤 위치 감지하여 하단 도달 시 추가 데이터 페이징 요청
  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // 스크롤 바닥 200px 전 지점에 도달하고, 현재 로딩 중이 아니며, 불러올 데이터가 더 남아있을 때 실행
    if (maxScroll - currentScroll <= 200 &&
        !_isFetchingMore &&
        !_isLoading &&
        _hasMore) {
      _fetchMoreRoads();
    }
  }

  /// 상단 탭 재클릭 시 최상단으로 스크롤 이동
  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// 1. 첫 페이지 데이터 로드 (탭/필터/정렬 변경 및 Pull-to-Refresh 시)
  Future<void> _fetchInitialRoads() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _roads = [];
      _lastDocument = null;
      _hasMore = true;
    });

    try {
      final isRegionTab = _selectedTab == '지역별';
      final targetType = isRegionTab ? 'region' : 'category';

      final result = await _roadRepository.fetchRoadsPaged(
        type: targetType,
        selectedRegion: isRegionTab && _selectedFilter != '전체' ? _selectedFilter : null,
        selectedCategory: !isRegionTab && _selectedFilter != '전체' ? _selectedFilter : null,
        sortBy: _selectedSort,
        lastDocument: null,
        limit: 6,
      );

      List<Road> filteredRoads = result.roads;

      // '지역별' 탭 필터링 시 RegionMapper 유연한 매핑 적용
      if (isRegionTab && _selectedFilter != '전체') {
        filteredRoads = filteredRoads.where((road) {
          final regionIdMatch = RegionMapper.isMatch(
            selectedRegion: _selectedFilter,
            targetText: road.regionId,
          );
          final titleMatch = RegionMapper.isMatch(
            selectedRegion: _selectedFilter,
            targetText: road.title,
          );
          final descriptionMatch = RegionMapper.isMatch(
            selectedRegion: _selectedFilter,
            targetText: road.description,
          );
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
        _lastDocument = result.lastDocument;
        _hasMore = result.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '데이터를 불러오지 못했습니다: $e';
        _isLoading = false;
      });
    }
  }

  /// 2. 다음 페이지 추가 로드 (스크롤 하단 감지 시)
  Future<void> _fetchMoreRoads() async {
    if (_isFetchingMore || !_hasMore) return;

    setState(() {
      _isFetchingMore = true;
    });

    try {
      final isRegionTab = _selectedTab == '지역별';
      final targetType = isRegionTab ? 'region' : 'category';

      final result = await _roadRepository.fetchRoadsPaged(
        type: targetType,
        selectedRegion: isRegionTab && _selectedFilter != '전체' ? _selectedFilter : null,
        selectedCategory: !isRegionTab && _selectedFilter != '전체' ? _selectedFilter : null,
        sortBy: _selectedSort,
        lastDocument: _lastDocument,
        limit: 6,
      );

      List<Road> newRoads = result.roads;

      if (isRegionTab && _selectedFilter != '전체') {
        newRoads = newRoads.where((road) {
          final regionIdMatch = RegionMapper.isMatch(
            selectedRegion: _selectedFilter,
            targetText: road.regionId,
          );
          final titleMatch = RegionMapper.isMatch(
            selectedRegion: _selectedFilter,
            targetText: road.title,
          );
          final descriptionMatch = RegionMapper.isMatch(
            selectedRegion: _selectedFilter,
            targetText: road.description,
          );
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
        _roads.addAll(newRoads);
        _lastDocument = result.lastDocument;
        _hasMore = result.hasMore;
        _isFetchingMore = false;
      });
    } catch (e) {
      print('추가 데이터 로드 중 오류 발생: $e');
      setState(() {
        _isFetchingMore = false;
      });
    }
  }

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
      _fetchInitialRoads();
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
            // 1. 최상단 대분류 탭 및 검색
            CategoryTabs(
              selectedTab: _selectedTab,
              onTabChanged: (tab) {
                if (_selectedTab != tab) {
                  setState(() {
                    _selectedTab = tab;
                    _selectedFilter = '전체';
                  });
                  _fetchInitialRoads();
                }
              },
              onSearchPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('검색 페이지 연동 예정입니다.')),
                );
              },
            ),

            const SizedBox(height: 4),

            // 2. 가로 스크롤 서브 필터 칩
            SubFilterChips(
              selectedTab: _selectedTab,
              selectedFilter: _selectedFilter,
              onFilterSelected: (filter) {
                if (_selectedFilter != filter) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                  _fetchInitialRoads();
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
                  _fetchInitialRoads();
                }
              },
            ),

            // 4. Firestore 결과 리스트 영역
            Expanded(
              child: _buildListContent(),
            ),
          ],
        ),
      ),
    );
  }

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

    if (_roads.isEmpty) {
      return Center(
        child: Text(
          '해당 조건에 맞는 코스가 존재하지 않습니다.',
          style: TextStyle(color: deepChocolate.withAlpha(150), fontSize: 14),
        ),
      );
    }

    // 광고가 삽입된 UI 카드 위젯 리스트 생성
    final uiItems = RoadAdHelper.buildListWithAds(
      listToShow: _roads,
      onCardPressed: _onCardPressed,
    );

    // 하단 추가 페이징 로딩 스피너 카운트 포함
    final totalItemCount = uiItems.length + (_isFetchingMore ? 1 : 0);

    return RefreshIndicator(
      color: pointCoralRed,
      backgroundColor: Colors.white,
      onRefresh: _fetchInitialRoads,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: totalItemCount,
        itemBuilder: (context, index) {
          if (index < uiItems.length) {
            return uiItems[index];
          }

          // 스크롤 최하단 로딩 스피너
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: pointCoralRed,
                  strokeWidth: 2.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}