import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPost {
  final String id;
  final String userId;
  final String? nickname;
  final String? profileImage;
  final List<String> badge;
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
    this.nickname,
    this.profileImage,
    this.badge = const [],
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

  /// Firestore 데이터 타입 불일치 방지 헬퍼 메서드
  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      return value.trim().isEmpty ? [] : [value];
    }
    return [];
  }

  /// 숫자 데이터 안전 변환 헬퍼 메서드
  static int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  /// Map 데이터 기반 객체 생성 (단위 테스트 및 일반 Map 변환용)
  factory CommunityPost.fromMap(Map<String, dynamic> data, String id) {
    return CommunityPost(
      id: id,
      userId: (data['userId'] ?? '').toString(),
      nickname: (data['nickname'] ?? '익명').toString(),
      profileImage: (data['profileImageUrl'] as String?)?.isNotEmpty == true
          ? data['profileImageUrl'] as String
          : null,
      badge: _toStringList(data['badge']),
      region: (data['region'] as String?)?.isNotEmpty == true ? data['region'] : '전체',
      category: (data['category'] as String?)?.isNotEmpty == true ? data['category'] : '전체',
      content: (data['content'] ?? '').toString(),
      imageUrls: _toStringList(data['imageUrls']),
      likeCount: _toInt(data['likeCount']),
      commentCount: _toInt(data['commentCount']),
      scrapCount: _toInt(data['scrapCount']),
      reportCount: _toInt(data['reportCount']),
      likedBy: _toStringList(data['likedBy']),
      scrappedBy: _toStringList(data['scrappedBy']),
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : (data['createdAt'] is String)
          ? DateTime.tryParse(data['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Firestore DocumentSnapshot 기반 객체 생성
  factory CommunityPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CommunityPost.fromMap(data, doc.id);
  }

  /// Firestore 저장용 Map 변환
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'nickname': nickname ?? '익명',
      'profileImageUrl': profileImage,
      'badge': badge,
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

  /// 불변 객체의 상태 변경을 위한 copyWith 추가
  CommunityPost copyWith({
    String? id,
    String? userId,
    String? authorNickname,
    String? authorProfileImage,
    List<String>? authorBadges,
    String? region,
    String? category,
    String? content,
    List<String>? imageUrls,
    int? likeCount,
    int? commentCount,
    int? scrapCount,
    int? reportCount,
    List<String>? likedBy,
    List<String>? scrappedBy,
    DateTime? createdAt,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nickname: nickname ?? this.nickname,
      profileImage: profileImage ?? this.profileImage,
      badge: badge ?? this.badge,
      region: region ?? this.region,
      category: category ?? this.category,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      scrapCount: scrapCount ?? this.scrapCount,
      reportCount: reportCount ?? this.reportCount,
      likedBy: likedBy ?? this.likedBy,
      scrappedBy: scrappedBy ?? this.scrappedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}