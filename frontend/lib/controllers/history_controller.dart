import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scan_result.dart';
import '../services/local_db_service.dart';

// 1. ESTADO INMUTABLE
class HistoryState {
  final List<ScanResult> scans;
  final bool isLoading;
  final String filterCategory;

  HistoryState({
    this.scans = const [],
    this.isLoading = false,
    this.filterCategory = 'Todas',
  });

  HistoryState copyWith({
    List<ScanResult>? scans,
    bool? isLoading,
    String? filterCategory,
  }) {
    return HistoryState(
      scans: scans ?? this.scans,
      isLoading: isLoading ?? this.isLoading,
      filterCategory: filterCategory ?? this.filterCategory,
    );
  }
}

// 2. NOTIFIER
class HistoryController extends Notifier<HistoryState> {
  @override
  HistoryState build() {
    Future.microtask(() => loadHistory());
    return HistoryState();
  }

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true);
    try {
      final db = ref.read(localDbProvider);
      await db.init();
      final all = await db.getAllScans(limit: 100);
      state = state.copyWith(scans: all, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  List<ScanResult> get filteredScans {
    if (state.filterCategory == 'Todas') return state.scans;
    return state.scans.where((s) {
      final cat = s.plantCategory ?? 'Planta';
      return cat.toLowerCase() == state.filterCategory.toLowerCase();
    }).toList();
  }

  Future<void> deleteScan(String id) async {
    final db = ref.read(localDbProvider);
    await db.deleteScan(id);
    final updatedScans = state.scans.where((s) => s.id != id).toList();
    state = state.copyWith(scans: updatedScans);
  }

  void setFilter(String category) {
    state = state.copyWith(filterCategory: category);
  }
}

// 3. PROVIDER GLOBAL
final historyControllerProvider = NotifierProvider<HistoryController, HistoryState>(() {
  return HistoryController();
});