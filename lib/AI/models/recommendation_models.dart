class RecommendationMessageSection {
  const RecommendationMessageSection({
    required this.recommendation,
    required this.reasons,
  });

  final String? recommendation;
  final List<String> reasons;

  factory RecommendationMessageSection.fromMap(Object? value) {
    final data = _asMap(value);
    return RecommendationMessageSection(
      recommendation: _nullableString(data['recommend']),
      reasons: _asStringList(data['reasons']),
    );
  }
}

class RecommendationMessage {
  const RecommendationMessage({required this.place, required this.course});

  final RecommendationMessageSection place;
  final RecommendationMessageSection course;

  factory RecommendationMessage.fromMap(Object? value) {
    final data = _asMap(value);
    return RecommendationMessage(
      place: RecommendationMessageSection.fromMap(data['place']),
      course: RecommendationMessageSection.fromMap(data['course']),
    );
  }
}

class PlaceRecommendation {
  const PlaceRecommendation({
    required this.placeId,
    required this.name,
    required this.score,
    required this.reasons,
  });

  final String placeId;
  final String name;
  final int score;
  final List<String> reasons;

  factory PlaceRecommendation.fromMap(Object? value) {
    final data = _asMap(value);
    return PlaceRecommendation(
      placeId: _requiredString(data['placeId'], 'placeId'),
      name: _requiredString(data['name'], 'name'),
      score: _asInt(data['score']),
      reasons: _asStringList(data['reasons']),
    );
  }
}

class CourseRecommendation {
  const CourseRecommendation({
    required this.courseId,
    required this.title,
    required this.score,
    required this.visitedRatio,
    required this.reasons,
  });

  final String courseId;
  final String title;
  final int score;
  final double visitedRatio;
  final List<String> reasons;

  factory CourseRecommendation.fromMap(Object? value) {
    final data = _asMap(value);
    return CourseRecommendation(
      courseId: _requiredString(data['courseId'], 'courseId'),
      title: _requiredString(data['title'], 'title'),
      score: _asInt(data['score']),
      visitedRatio: _asDouble(data['visitedRatio']),
      reasons: _asStringList(data['reasons']),
    );
  }
}

class RecommendationResult {
  const RecommendationResult({
    required this.userId,
    required this.message,
    required this.placeRecommendations,
    required this.courseRecommendations,
    this.currentRegionId,
    this.userLat,
    this.userLng,
  });

  final String userId;
  final String? currentRegionId;
  final double? userLat;
  final double? userLng;
  final RecommendationMessage message;
  final List<PlaceRecommendation> placeRecommendations;
  final List<CourseRecommendation> courseRecommendations;

  factory RecommendationResult.fromMap(Map<String, dynamic> data) {
    return RecommendationResult(
      userId: _requiredString(data['userId'], 'userId'),
      currentRegionId: _nullableString(data['currentRegionId']),
      userLat: _asNullableDouble(data['userLat']),
      userLng: _asNullableDouble(data['userLng']),
      message: RecommendationMessage.fromMap(data['message']),
      placeRecommendations: _asList(
        data['placeRecommendations'],
      ).map(PlaceRecommendation.fromMap).toList(growable: false),
      courseRecommendations: _asList(
        data['courseRecommendations'],
      ).map(CourseRecommendation.fromMap).toList(growable: false),
    );
  }
}

class RecommendationException implements Exception {
  const RecommendationException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is! Map) {
    throw const FormatException('Expected a JSON object.');
  }
  return value.map((key, item) => MapEntry(key.toString(), item));
}

List<Object?> _asList(Object? value) {
  if (value == null) return const [];
  if (value is! List) {
    throw const FormatException('Expected a JSON array.');
  }
  return List<Object?>.unmodifiable(value);
}

List<String> _asStringList(Object? value) {
  return _asList(value)
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

String _requiredString(Object? value, String fieldName) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) {
    throw FormatException('$fieldName is required.');
  }
  return text;
}

String? _nullableString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int _asInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _asNullableDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
