import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'course_detail_screen.dart';
import 'models/road.dart';
import 'repositories/road_repository.dart';

class RoadSearchScreen extends StatefulWidget {
  const RoadSearchScreen({super.key});

  @override
  State<RoadSearchScreen> createState() => _RoadSearchScreenState();
}

class _RoadSearchScreenState extends State<RoadSearchScreen> {
  // YamYamRoad 브랜드 공식 컬러 상수 정의
  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color creamyIvory = Color(0xFFFFFDF9);

  final TextEditingController _searchController = TextEditingController();
  final RoadRepository _roadRepository = RoadRepository();
  final ScrollController _scrollController = ScrollController();

  List<Road> _searchResults = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 스크롤 감지 및 하단 도달 시 추가 페이징 요청
  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (maxScroll - currentScroll <= 200 &&
        !_isFetchingMore &&
        !_isLoading &&
        _hasMore) {
      _fetchMoreSearchResults();
    }
  }

  /// 1. 검색어 제출 시 첫 페이지 데이터 로드
  Future<void> _performSearch(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      setState(() {
        _searchResults = [];
        _lastDocument = null;
        _hasMore = false;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _searchResults = [];
      _lastDocument = null;
      _hasMore = true;
    });

    try {
      final result = await _roadRepository.searchRoadsPaged(
        query: trimmedQuery,
        lastDocument: null,
        limit: 15, // 화면 스크롤 확보를 위해 15개로 상향
      );

      setState(() {
        _searchResults = result.roads;
        _lastDocument = result.lastDocument;
        _hasMore = result.hasMore;
        _isLoading = false;
      });
    } catch (e) {
      print('검색 중 오류 발생: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 2. 하단 스크롤 시 다음 검색 결과 추가 로드
  Future<void> _fetchMoreSearchResults() async {
    final query = _searchController.text.trim();
    if (query.isEmpty || _isFetchingMore || !_hasMore) return;

    setState(() {
      _isFetchingMore = true;
    });

    try {
      final result = await _roadRepository.searchRoadsPaged(
        query: query,
        lastDocument: _lastDocument,
        limit: 15, // 추가 로드 시에도 15개씩 수신
      );

      setState(() {
        _searchResults.addAll(result.roads);
        _lastDocument = result.lastDocument;
        _hasMore = result.hasMore;
        _isFetchingMore = false;
      });
    } catch (e) {
      print('추가 검색 로드 중 오류 발생: $e');
      setState(() {
        _isFetchingMore = false;
      });
    }
  }

  /// 코스 터치 시 상세 화면으로 이동
  void _navigateToDetail(Road road) {
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
      appBar: AppBar(
        backgroundColor: creamyIvory,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: deepChocolate),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (value) => _performSearch(value),
          style: const TextStyle(fontSize: 16, color: deepChocolate),
          decoration: InputDecoration(
            hintText: '로드를 검색할 수 있어요',
            hintStyle: TextStyle(
              color: deepChocolate.withOpacity(0.4),
              fontSize: 16,
            ),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear, color: deepChocolate, size: 20),
              onPressed: () {
                _searchController.clear();
                _performSearch('');
              },
            )
                : null,
          ),
          onChanged: (text) {
            setState(() {}); // Clear 버튼 상태 업데이트
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: deepChocolate),
            onPressed: () => _performSearch(_searchController.text),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: deepChocolate),
      );
    }

    if (_searchController.text.trim().isEmpty) {
      return Center(
        child: Text(
          '검색어를 입력해 주세요.',
          style: TextStyle(color: deepChocolate.withOpacity(0.5), fontSize: 14),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          '검색 결과가 없습니다.',
          style: TextStyle(color: deepChocolate.withOpacity(0.5), fontSize: 14),
        ),
      );
    }

    final totalItemCount = _searchResults.length + (_isFetchingMore ? 1 : 0);

    return ListView.separated(
      controller: _scrollController,
      itemCount: totalItemCount,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        thickness: 0.5,
        color: Color(0xFFE0E0E0),
        indent: 16,
        endIndent: 16,
      ),
      itemBuilder: (context, index) {
        if (index < _searchResults.length) {
          final road = _searchResults[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            title: Text(
              road.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: deepChocolate,
              ),
            ),
            onTap: () => _navigateToDetail(road),
          );
        }

        // 추가 로딩 인디케이터
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
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
    );
  }
}