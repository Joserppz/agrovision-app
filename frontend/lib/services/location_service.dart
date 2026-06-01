import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';

class LocationService extends GetxService {

  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    // API actualizada en geolocator ^13 — usar LocationSettings
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy:  LocationAccuracy.medium,
        timeLimit: Duration(seconds: 8),
      ),
    );
  }

  Future<String?> getLocationName(double lat, double lon) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isEmpty) return null;
      final place = placemarks.first;
      final parts = [
        place.locality,
        place.administrativeArea,
        place.country,
      ].where((p) => p != null && p.isNotEmpty).toList();
      return parts.join(', ');
    } catch (_) {
      return '${lat.toStringAsFixed(4)}°, ${lon.toStringAsFixed(4)}°';
    }
  }

  double distanceBetween(
    double startLat, double startLon,
    double endLat,   double endLon,
  ) =>
      Geolocator.distanceBetween(startLat, startLon, endLat, endLon);

  Stream<Position> get positionStream => Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy:       LocationAccuracy.high,
      distanceFilter: 5,
    ),
  );
}