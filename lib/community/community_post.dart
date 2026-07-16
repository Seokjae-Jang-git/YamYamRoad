import 'package:cloud_firestore/cloud_firestore.dart';

// 🌟 커뮤니티 글 데이터를 담는 모델 클래스
class CommunityPost {
  final String id;
  final String authorId;
  final String? authorNickname;
  final String? authorProfileImage;
  final List<String> authorBadges; // 뱃지 이름 리스트 (예: ['그로플러버','성수한주'])
  final String region;   // 지역별 카테고리 (예: 성수동, 가로수길)
  final String category; // 메뉴별 카테고리 (예: 빵, 떡, 음료, 유행상품)
  final String content;
  final List<String> imageUrls;
  final int likeCount;
  final int commentCount;
  final int scrapCount;
  final int reportCount;
  final List<String> likedBy;
  final List<String> scrappedBy;
  final DateTime createdAt;

  CommunityPost({
    required this.id,
    required this.authorId,
    required this.authorNickname,
    this.authorProfileImage,
    this.authorBadges = const [],
    required this.region,
    required this.category,
    required this.content,
    this.imageUrls = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.scrapCount = 0,
    this.reportCount = 0,
    this.likedBy = const [],
    this.scrappedBy = const [],
    required this.createdAt,
  });

  // 🌟 Firestore 문서 -> 객체 변환
  factory CommunityPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityPost(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorNickname: data['authorNickname'] ?? '익명',
      authorProfileImage: data['authorProfileImage'],
      authorBadges: List<String>.from(data['authorBadges'] ?? []),
      region: data['region'] ?? '전체',
      category: data['category'] ?? '전체',
      content: data['content'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      scrapCount: data['scrapCount'] ?? 0,
      reportCount: data['reportCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      scrappedBy: List<String>.from(data['scrappedBy'] ?? []),
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // 🌟 객체 -> Firestore 저장용 Map 변환
  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorNickname': authorNickname,
      'authorProfileImage': authorProfileImage,
      'authorBadges': authorBadges,
      'region': region,
      'category': category,
      'content': content,
      'imageUrls': imageUrls,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'scrapCount': scrapCount,
      'reportCount': reportCount,
      'likedBy': likedBy,
      'scrappedBy': scrappedBy,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
