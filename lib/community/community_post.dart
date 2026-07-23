import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPost {
  final String id;
  final String userId; // 🌟 authorId → userId
  final String? authorNickname;
  final String? authorProfileImage;
  final List<String> authorBadges;
  final String region;
  final String category;
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
    required this.userId,
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

  // 🌟 Firestore 필드가 List가 아니라 빈 문자열("")이나 null로 저장돼 있어도
  //    안전하게 List<String>으로 변환합니다.
  //    (List<String>.from("") 을 호출하면 "type 'String' is not a subtype of
  //     type 'Iterable<dynamic>'" 에러가 발생하기 때문에 방어 코드가 필요합니다.)
  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      return value.isEmpty ? [] : [value];
    }
    return [];
  }

  factory CommunityPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityPost(
      id: doc.id,
      userId: (data['userId'] ?? '').toString(),
      authorNickname: (data['nickname'] ?? '익명').toString(),
      authorProfileImage: (data['profileImageUrl'] as String?)?.isNotEmpty == true
          ? data['profileImageUrl'] as String
          : null,
      authorBadges: _toStringList(data['badge']),
      region: (data['region'] as String?)?.isNotEmpty == true ? data['region'] : '전체',
      category: (data['category'] as String?)?.isNotEmpty == true ? data['category'] : '전체',
      content: (data['content'] ?? '').toString(),
      imageUrls: _toStringList(data['imageUrls']),
      likeCount: (data['likeCount'] is int) ? data['likeCount'] : 0,
      commentCount: (data['commentCount'] is int) ? data['commentCount'] : 0,
      scrapCount: (data['scrapCount'] is int) ? data['scrapCount'] : 0,
      reportCount: (data['reportCount'] is int) ? data['reportCount'] : 0,
      likedBy: _toStringList(data['likedBy']),
      scrappedBy: _toStringList(data['scrappedBy']),
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'nickname': authorNickname,
      'profileImageUrl': authorProfileImage,
      'badge': authorBadges,
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
