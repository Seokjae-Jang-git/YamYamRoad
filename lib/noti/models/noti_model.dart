import 'package:cloud_firestore/cloud_firestore.dart';

enum NotiType {
  like,
  scrap,
  stamp,
  badge,
  point,
  unknown;

  static NotiType fromValue(Object? value) {
    return switch (value?.toString().toLowerCase()) {
      'like' => NotiType.like,
      'scrap' => NotiType.scrap,
      'stamp' => NotiType.stamp,
      'badge' => NotiType.badge,
      'point' => NotiType.point,
      _ => NotiType.unknown,
    };
  }
}

class NotiItem {
  const NotiItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    this.refType,
    this.refId,
    this.createdAt,
  });

  final String id;
  final NotiType type;
  final String title;
  final String body;
  final String? refType;
  final String? refId;
  final bool isRead;
  final DateTime? createdAt;

  factory NotiItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};

    return NotiItem(
      id: document.id,
      type: NotiType.fromValue(data['type']),
      title: data['title']?.toString() ?? '',
      body: data['body']?.toString() ?? '',
      refType: _nullableString(data['refType']),
      refId: _nullableString(data['refId']),
      isRead: data['isRead'] == true,
      createdAt: _asDateTime(data['createdAt']),
    );
  }
}

String? _nullableString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

DateTime? _asDateTime(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
