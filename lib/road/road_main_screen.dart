import 'package:flutter/material.dart';
import 'widgets/category_tabs.dart';
import 'widgets/sub_filter_chips.dart';
import 'widgets/sorting_bar.dart';
import 'widgets/course_list_card.dart';
import 'widgets/region_select_page.dart';
import 'data/road_mock_data.dart'; // 데이터 구조 임포트

class RoadMainScreen extends StatefulWidget {
  const RoadMainScreen({super.key});

  @override
  State<RoadMainScreen> createState() => _RoadMainScreenState();
}

class _RoadMainScreenState extends State<RoadMainScreen> {
  String _selectedTab = '지역별';
  String _selectedFilter = '전체';
  String _selectedSort = '최신순';

  // 🆕 컨텍스트 기반 분리 정렬 필터링 엔진
  List<CourseData> get _processedCourses {
    // 1. 현재 탭(지역별 vs 메뉴별)에 부합하는 독립 데이터 원본을 로드합니다.
    List<CourseData> baseCourses = _selectedTab == '지역별' ? regionCourses : menuCourses;
    List<CourseData> result = List.from(baseCourses);

    // 2. 하위 필터 처리 (전체가 아닐 경우에만 동적 키 매칭)
    if (_selectedFilter != '전체') {
      if (_selectedTab == '지역별') {
        result = result.where((c) => c.region == _selectedFilter).toList();
      } else if (_selectedTab == '메뉴별') {
        result = result.where((c) => c.category == _selectedFilter).toList();
      }
    }

    // 3. 정렬 시뮬레이션
    if (_selectedSort == '최신순') {
      result.sort((a, b) => b.id.compareTo(a.id));
    } else if (_selectedSort == '이름순') {
      result.sort((a, b) => a.title.compareTo(b.title));
    } else if (_selectedSort == '스탬프 순') {
      result.sort((a, b) => b.stampCount.compareTo(a.stampCount));
    }

    return result;
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
    }
  }

  // 피드형 광고 동적 배치 알고리즘
  List<Widget> _buildListWithAds(List<CourseData> listToShow) {
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
      for (var course in listToShow) {
        items.add(
          CourseListCard(
            course: course,
            onTap: () => _onCardPressed(course.title),
          ),
        );
      }
      items.add(_buildAdBanner());
    }
    // 카드 수가 3개 이상인 경우 3개 카드 마다 광고 획득 배치
    else {
      for (int i = 0; i < listToShow.length; i++) {
        final course = listToShow[i];
        items.add(
          CourseListCard(
            course: course,
            onTap: () => _onCardPressed(course.title),
          ),
        );

        if ((i + 1) % 3 == 0) {
          items.add(_buildAdBanner());
        }
      }
    }

    return items;
  }

  void _onCardPressed(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"$title" 상세 코스보기 화면 진입')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listToShow = _processedCourses;
    final uiItems = _buildListWithAds(listToShow);

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
                setState(() {
                  _selectedTab = tab;
                  _selectedFilter = '전체'; // 🆕 탭 전환 즉시 하위 칩 필터 상태 청소!
                });
              },
              onSearchPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('검색 페이지 연동을 환영합니다!')),
                );
              },
            ),

            const SizedBox(height: 4),

            // 2. 가로 스크롤형 동적 필터 칩 영역 (대분류 탭 정보 전달 연계)
            SubFilterChips(
              selectedTab: _selectedTab,
              selectedFilter: _selectedFilter,
              onFilterSelected: (filter) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              onMorePressed: _openRegionSelectPage,
            ),

            const SizedBox(height: 4),

            // 3. 정렬 상태 제어 바
            SortingBar(
              selectedSort: _selectedSort,
              onSortChanged: (sort) {
                setState(() {
                  _selectedSort = sort;
                });
              },
            ),

            // 4. 리스트 렌더링 영역
            Expanded(
              child: ListView.builder(
                itemCount: uiItems.length,
                itemBuilder: (context, index) {
                  return uiItems[index];
                },
              ),
            ),
          ],
        ),
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