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
  
  // Filtros
  final selectedCategory = 'Todas'.obs; // Fruta, Verdura, Planta, Flor, Otros
  final isHeatmapMode    = false.obs;   // Toggle de mapa de calor

  static const defaultCenter = LatLng(-16.5000, -68.1500);

  @override
  Future<void> onInit() async {
    super.onInit();
    await loadPoints();
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
    if (pos != null) currentPosition.value = LatLng(pos.latitude, pos.longitude);
  }

  List<ScanResult> get filteredPoints {
    if (selectedCategory.value == 'Todas') return scanPoints;
    return scanPoints.where((s) => (s.plantCategory ?? 'Otros') == selectedCategory.value).toList();
  }

  // Lógica para evitar puntos duplicados si estás parado sobre un escaneo
  bool get isCurrentPositionUnique {
    if (currentPosition.value == null) return false;
    if (filteredPoints.isEmpty) return true;
    
    final Distance distance = const Distance();
    for(var p in filteredPoints) {
      if (p.hasLocation) {
        final d = distance.as(LengthUnit.Meter, currentPosition.value!, LatLng(p.latitude!, p.longitude!));
        if (d < 20) return false;
      }
    }
    return true;
  }

  void toggleHeatmap() => isHeatmapMode.value = !isHeatmapMode.value;
  void setCategory(String cat) => selectedCategory.value = cat;

  LatLng get mapCenter => currentPosition.value ?? defaultCenter;
}