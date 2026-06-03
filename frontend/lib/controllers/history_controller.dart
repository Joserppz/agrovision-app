import 'package:get/get.dart';
import '../models/scan_result.dart';
import '../services/local_db_service.dart';

class HistoryController extends GetxController {
  final LocalDbService _db;

  HistoryController(this._db);

  final scans      = <ScanResult>[].obs;
  final isLoading  = false.obs;
  
  // NUEVO: Filtros basados en categoría botánica
  final filterCategory = 'Todas'.obs; 

  @override
  void onInit() {
    super.onInit();
    loadHistory();
    ever(filterCategory, (_) => _applyFilter());
  }

  Future<void> loadHistory() async {
    isLoading.value = true;
    try {
      final all = await _db.getAllScans(limit: 100);
      scans.value = all;
      _applyFilter();
    } finally {
      isLoading.value = false;
    }
  }

  void _applyFilter() {}

  List<ScanResult> get filteredScans {
    if (filterCategory.value == 'Todas') return scans;
    
    // Filtramos exactamente por el string de la categoría que nos devuelve Groq
    return scans.where((s) {
        final cat = s.plantCategory ?? 'Planta'; // Si es nulo, asumimos Planta
        return cat.toLowerCase() == filterCategory.value.toLowerCase();
    }).toList();
  }

  Future<void> deleteScan(String id) async {
    await _db.deleteScan(id);
    scans.removeWhere((s) => s.id == id);
  }

  void setFilter(String category) => filterCategory.value = category;
}