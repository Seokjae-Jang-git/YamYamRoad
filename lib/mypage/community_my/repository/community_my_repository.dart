import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../common/user_data.dart'; // 프로젝트 구조에 맞게 수정 필요

class CommunityMyRepository {
  // 시간차 계산 헬퍼 함수 (예: '3일전', '2시간 전')
  static String getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '방금 전';
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inDays > 0) return '${diff.inDays}일 전';
    if (diff.inHours > 0) return '${diff.inHours}시간 전';
    if (diff.inMinutes > 0) return '${diff.inMinutes}분 전';
    return '방금 전';
  }

  // 스트림에서 가져온 데이터를 필터링하고 정렬하는 비즈니스 로직
  static List<Map<String, dynamic>> processFeeds({
    required List<QueryDocumentSnapshot> docs,
    required String selectedFilter,
    required String selectedSort,
  }) {
    List<Map<String, dynamic>> feeds = docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      data['postId'] = doc.id;
      return data;
    }).toList();

    // 내 피드 필터링
    if (selectedFilter == '내 피드') {
      feeds = feeds.where((feed) => feed['userId'] == UserData.uid).toList();
    }

    // 정렬 규칙 적용
    feeds.sort((a, b) {
      if (selectedSort == '좋아요순') {
        return (b['likeCount'] ?? 0).compareTo(a['likeCount'] ?? 0);
      } else if (selectedSort == '댓글순') {
        return (b['commentCount'] ?? 0).compareTo(a['commentCount'] ?? 0);
      } else if (selectedSort == '스크랩순') {
        return (b['scrapCount'] ?? 0).compareTo(a['scrapCount'] ?? 0);
      } else {
        Timestamp aTime = a['createdAt'] ?? Timestamp.now();
        Timestamp bTime = b['createdAt'] ?? Timestamp.now();
        return bTime.compareTo(aTime);
      }
    });

    return feeds;
  }
}