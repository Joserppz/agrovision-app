import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/scan_result.dart';
import '../services/local_db_service.dart';
import '../controllers/scan_controller.dart'; // locationServiceProvider

// 1. ESTADO INMUTABLE
class MapState {
  final List<ScanResult> scanPoints;
  final LatLng? currentPosition;
  final bool isLoading;
  final String selectedCategory;
  final bool isHeatmapMode;

  MapState({
    this.scanPoints = const [],
    this.currentPosition,
    this.isLoading = false,
    this.selectedCategory = 'Todas',
    this.isHeatmapMode = false,
  });

  MapState copyWith({
    List<ScanResult>? scanPoints,
    LatLng? currentPosition,
    bool? isLoading,
    String? selectedCategory,
    bool? isHeatmapMode,
  }) {
    return MapState(
      scanPoints: scanPoints ?? this.scanPoints,
      currentPosition: currentPosition ?? this.currentPosition,
      isLoading: isLoading ?? this.isLoading,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isHeatmapMode: isHeatmapMode ?? this.isHeatmapMode,
    );
  }
}

// 2. NOTIFIER
class MapController extends Notifier<MapState> {
  static const defaultCenter = LatLng(-16.5000, -68.1500);

  @override
  MapState build() {
    Future.microtask(() {
      loadPoints();
      _loadCurrentPosition();
    });
    return MapState();
  }

  Future<void> loadPoints() async {
    state = state.copyWith(isLoading: true);
    try {
      final db = ref.read(localDbProvider);
      await db.init();
      final points = await db.getScansWithLocation();
      state = state.copyWith(scanPoints: points, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _loadCurrentPosition() async {
    final locationService = ref.read(locationServiceProvider);
    final pos = await locationService.getCurrentPosition();
    if (pos != null) {
      state = state.copyWith(currentPosition: LatLng(pos.latitude, pos.longitude));
    }
  }

  List<ScanResult> get filteredPoints {
    if (state.selectedCategory == 'Todas') return state.scanPoints;
    return state.scanPoints.where((s) => (s.plantCategory ?? 'Otros') == state.selectedCategory).toList();
  }

  bool get isCurrentPositionUnique {
    if (state.currentPosition == null) return false;
    if (filteredPoints.isEmpty) return true;
    
    final Distance distance = const Distance();
    for(var p in filteredPoints) {
      if (p.hasLocation) {
        final d = distance.as(LengthUnit.Meter, state.currentPosition!, LatLng(p.latitude!, p.longitude!));
        if (d < 20) return false;
      }
    }
    return true;
  }

  void toggleHeatmap() => state = state.copyWith(isHeatmapMode: !state.isHeatmapMode);
  void setCategory(String cat) => state = state.copyWith(selectedCategory: cat);

  LatLng get mapCenter => state.currentPosition ?? defaultCenter;
}

// 3. PROVIDER
final mapControllerProvider = NotifierProvider<MapController, MapState>(() {
  return MapController();
});