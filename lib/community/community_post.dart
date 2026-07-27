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
  final List<String> videoUrls;       // 🌟 추가
  final List<String> tags;            // 🌟 추가
  final List<String> emoticonIds;     // 🌟 추가
  final List<String> searchKeywords;  // 🌟 추가
  final String status;                // 🌟 추가
  final int likeCount;
  final int commentCount;
  final int scrapCount;
  final int reportCount;
  final List<String> likedBy;
  final List<String> scrappedBy;
  final DateTime createdAt;
  final DateTime? updatedAt;          // 🌟 추가

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
    this.videoUrls = const [],
    this.tags = const [],
    this.emoticonIds = const [],
    this.searchKeywords = const [],
    this.status = 'active',
    this.likeCount = 0,
    this.commentCount = 0,
    this.scrapCount = 0,
    this.reportCount = 0,
    this.likedBy = const [],
    this.scrappedBy = const [],
    required this.createdAt,
    this.updatedAt,
  });

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

  static int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  static DateTime? _toDateTimeOrNull(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

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
      videoUrls: _toStringList(data['videoUrls']),
      tags: _toStringList(data['tags']),
      emoticonIds: _toStringList(data['emoticonIds']),
      searchKeywords: _toStringList(data['searchKeywords']),
      status: (data['status'] as String?)?.isNotEmpty == true ? data['status'] : 'active',
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
      updatedAt: _toDateTimeOrNull(data['updatedAt']),
    );
  }

  factory CommunityPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CommunityPost.fromMap(data, doc.id);
  }

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
      'videoUrls': videoUrls,
      'tags': tags,
      'emoticonIds': emoticonIds,
      'searchKeywords': searchKeywords,
      'status': status,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'scrapCount': scrapCount,
      'reportCount': reportCount,
      'likedBy': likedBy,
      'scrappedBy': scrappedBy,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  CommunityPost copyWith({
    String? id,
    String? userId,
    String? nickname,
    String? profileImage,
    List<String>? badge,
    String? region,
    String? category,
    String? content,
    List<String>? imageUrls,
    List<String>? videoUrls,
    List<String>? tags,
    List<String>? emoticonIds,
    List<String>? searchKeywords,
    String? status,
    int? likeCount,
    int? commentCount,
    int? scrapCount,
    int? reportCount,
    List<String>? likedBy,
    List<String>? scrappedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      videoUrls: videoUrls ?? this.videoUrls,
      tags: tags ?? this.tags,
      emoticonIds: emoticonIds ?? this.emoticonIds,
      searchKeywords: searchKeywords ?? this.searchKeywords,
      status: status ?? this.status,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      scrapCount: scrapCount ?? this.scrapCount,
      reportCount: reportCount ?? this.reportCount,
      likedBy: likedBy ?? this.likedBy,
      scrappedBy: scrappedBy ?? this.scrappedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}