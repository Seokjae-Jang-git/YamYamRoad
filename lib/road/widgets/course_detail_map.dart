import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/place_model.dart';

class CourseDetailMap extends StatefulWidget {
  final List<PlaceModel> places;
  final EdgeInsets padding;

  const CourseDetailMap({
    super.key,
    required this.places,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<CourseDetailMap> createState() => _CourseDetailMapState();
}

class _CourseDetailMapState extends State<CourseDetailMap> {
  GoogleMapController? _mapController;

  @override
  void didUpdateWidget(covariant CourseDetailMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 장소 데이터 목록이나 패딩이 변경되면 지도 카메라 영역 재조정
    if (oldWidget.places != widget.places || oldWidget.padding != widget.padding) {
      _moveCameraToFitPlaces();
    }
  }

  /// 장소 목록을 기반으로 마커 Set을 생성합니다.
  Set<Marker> get _markers {
    return widget.places.map((place) {
      return Marker(
        markerId: MarkerId(place.id),
        position: LatLng(place.lat, place.lng),
        infoWindow: InfoWindow(
          title: place.name,
          snippet: place.address,
        ),
      );
    }).toSet();
  }

  /// 모든 마커가 화면에 들어오도록 카메라 영역을 계산하여 이동합니다.
  void _moveCameraToFitPlaces() {
    if (_mapController == null || widget.places.isEmpty) return;

    double minLat = widget.places.first.lat;
    double maxLat = widget.places.first.lat;
    double minLng = widget.places.first.lng;
    double maxLng = widget.places.first.lng;

    for (var place in widget.places) {
      if (place.lat < minLat) minLat = place.lat;
      if (place.lat > maxLat) maxLat = place.lat;
      if (place.lng < minLng) minLng = place.lng;
      if (place.lng > maxLng) maxLng = place.lng;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 60.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(37.5666102, 126.9783881), // 기본 임시 좌표 (서울시청)
        zoom: 14,
      ),
      padding: widget.padding,
      markers: _markers,
      myLocationButtonEnabled: false,
      indoorViewEnabled: true,
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        _moveCameraToFitPlaces();
      },
    );
  }
}