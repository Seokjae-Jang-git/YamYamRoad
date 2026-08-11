import 'package:cloud_firestore/cloud_firestore.dart';

class StampDataProcessor {
  /// Firestore에서 가져온 원본 리스트를 필터링 및 정렬하여 반환하는 순수 함수
  static List<Map<String, dynamic>> process({
    required List<Map<String, dynamic>> rawList,
    required String selectedTab,
    required String selectedFilter,
    required String selectedSort,
  }) {
    List<Map<String, dynamic>> result = List.from(rawList);

    // 1. 탭에 따른 대분류 필터링
    if (selectedTab == '지역별') {
      result = result
          .where((r) =>
      r['region'] != null && r['region'].toString().trim().isNotEmpty)
          .toList();
    } else if (selectedTab == '메뉴별') {
      result = result
          .where((r) =>
      r['region'] == null || r['region'].toString().trim().isEmpty)
          .toList();
    }

    // 2. 하위 필터 처리
    if (selectedFilter != '전체') {
      if (selectedTab == '지역별') {
        result = result.where((r) => r['region'] == selectedFilter).toList();
      } else if (selectedTab == '메뉴별') {
        result = result.where((r) {
          final categoryList = r['categoryIds'];
          if (categoryList is List && categoryList.contains(selectedFilter)) {
            return true;
          }
          return false;
        }).toList();
      }
    }

    // 3. 정렬 처리
    if (selectedSort == '최신순') {
      result.sort((a, b) {
        final aTime =
            (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final bTime =
            (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
    } else if (selectedSort == '이름순') {
      result.sort((a, b) => (a['title'] ?? '')
          .toString()
          .compareTo((b['title'] ?? '').toString()));
    } else if (selectedSort == '스탬프 순') {
      result.sort((a, b) => (b['myStampCount'] ?? 0).compareTo(a['myStampCount'] ?? 0));
    }

    return result;
  }
}