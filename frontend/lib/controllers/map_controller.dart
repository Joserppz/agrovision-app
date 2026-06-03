import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../models/scan_result.dart';
import '../services/local_db_service.dart';
import '../services/location_service.dart';

class MapController extends GetxController {
  final LocalDbService  _db;
  final LocationService _location;

  MapController(this._db, this._location);

  final scanPoints      = <ScanResult>[].obs;
  final currentPosition = Rxn<LatLng>();
  final isLoading       = false.obs;
  final selectedFilter  = 'all'.obs;

  // Centro por defecto: La Paz, Bolivia
  static const defaultCenter = LatLng(-16.5000, -68.1500);

  @override
  void onInit() {
    super.onInit();
    loadPoints();
    _loadCurrentPosition();
  }

  Future<void> loadPoints() async {
    isLoading.value = true;
    try {
      final points = await _db.getScansWithLocation();
      scanPoints.value = points;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadCurrentPosition() async {
    final pos = await _location.getCurrentPosition();
    if (pos != null) {
      currentPosition.value = LatLng(pos.latitude, pos.longitude);
    }
  }

  // CORRECCIÓN: Filtramos por el nivel de severidad en lugar de la clase exacta
  List<ScanResult> get filteredPoints {
    if (selectedFilter.value == 'all') return scanPoints;
    return scanPoints
        .where((s) => s.severityLevel == selectedFilter.value)
        .toList();
  }

  void setFilter(String filter) => selectedFilter.value = filter;

  LatLng get mapCenter => currentPosition.value ?? defaultCenter;
}