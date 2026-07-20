import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/place_model.dart';

class PlaceRepository {
  final FirebaseFirestore _firestore;

  PlaceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 코스의 placeIds 목록에 해당하는 장소 문서들을 Firestore에서 가져옵니다.
  Future<List<PlaceModel>> fetchPlacesByIds(List<String> placeIds) async {
    if (placeIds.isEmpty) return [];

    try {
      final futures = placeIds.map((id) => _firestore.collection('places').doc(id).get());
      final snapshots = await Future.wait(futures);

      final List<PlaceModel> places = [];
      for (var doc in snapshots) {
        if (doc.exists && doc.data() != null) {
          places.add(PlaceModel.fromFirestore(doc));
        }
      }
      return places;
    } catch (e) {
      print('Error fetching places by ids: $e');
      rethrow;
    }
  }
}