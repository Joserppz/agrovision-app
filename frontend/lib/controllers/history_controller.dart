import 'package:get/get.dart';
import '../models/scan_result.dart';
import '../services/local_db_service.dart';

class HistoryController extends GetxController {
  final LocalDbService _db;

  HistoryController(this._db);

  final scans      = <ScanResult>[].obs;
  final isLoading  = false.obs;
  final filterLevel = 'all'.obs; // all | critical | moderate | healthy

  @override
  void onInit() {
    super.onInit();
    loadHistory();
    // Recarga cuando cambia el filtro
    ever(filterLevel, (_) => _applyFilter());
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

  void _applyFilter() {
    // La lista filtrada se calcula como getter — no necesitamos otra obs
    // Los widgets usan filteredScans que llama a esto reactivamente
  }

  List<ScanResult> get filteredScans {
    if (filterLevel.value == 'all') return scans;
    return scans.where((s) => s.severityLevel == filterLevel.value).toList();
  }

  Future<void> deleteScan(String id) async {
    await _db.deleteScan(id);
    scans.removeWhere((s) => s.id == id);
  }

  void setFilter(String level) => filterLevel.value = level;
}