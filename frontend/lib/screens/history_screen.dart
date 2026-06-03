import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../controllers/history_controller.dart';
import '../controllers/scan_controller.dart'; 
import '../models/scan_result.dart';
import '../widgets/offline_banner.dart';
import '../controllers/connectivity_controller.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl         = Get.find<HistoryController>();
    final connectivity = Get.find<ConnectivityController>();

    return Scaffold(
      backgroundColor: AgroColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Obx(() => connectivity.isOnline.value
                ? const SizedBox.shrink()
                : const OfflineBanner()),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AgroColors.green, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('Historial',
                      style: TextStyle(
                        fontFamily: AgroText.fontDisplay,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AgroColors.green,
                      )),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear(); 
                      ctrl.loadHistory();
                    },
                    child: const Icon(Icons.refresh_rounded,
                        color: AgroColors.green, size: 22),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => _confirmDeleteAll(context, ctrl),
                    child: const Icon(Icons.delete_sweep_rounded,
                        color: AgroColors.red, size: 22),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AgroColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AgroColors.border),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(
                      fontFamily: AgroText.fontBody, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Buscar planta o enfermedad...',
                    hintStyle: TextStyle(
                        fontFamily: AgroText.fontBody,
                        color: AgroColors.textHint,
                        fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: AgroColors.green, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            _buildFilters(ctrl),

            const SizedBox(height: 12),

            Obx(() {
              final total = ctrl.scans.length;
              final enfermas = ctrl.scans.where((s) => s.severityLevel != 'healthy').length;
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AgroColors.greenFaint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bar_chart_rounded,
                          color: AgroColors.green, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '$total registros · $enfermas con novedades',
                        style: const TextStyle(
                          fontFamily: AgroText.fontBody,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AgroColors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 8),

            Expanded(
              child: Obx(() {
                if (ctrl.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AgroColors.green),
                  );
                }

                List<ScanResult> items = ctrl.filteredScans;

                final searchTerm = _searchCtrl.text.toLowerCase();
                if (searchTerm.isNotEmpty) {
                  items = items.where((scan) {
                    return scan.displayName.toLowerCase().contains(searchTerm) ||
                           (scan.description?.toLowerCase().contains(searchTerm) ?? false);
                  }).toList();
                }

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.eco_outlined,
                            color: AgroColors.border, size: 56),
                        const SizedBox(height: 12),
                        Text('No hay escaneos que mostrar',
                            style: Get.textTheme.bodyMedium?.copyWith(
                                color: AgroColors.textHint)),
                        const SizedBox(height: 8),
                        if (ctrl.scans.isEmpty) 
                          ElevatedButton.icon(
                            onPressed: () =>
                                Get.toNamed(AgroRoutes.camera),
                            icon: const Icon(
                                Icons.camera_alt_outlined, size: 16),
                            label: const Text('Escanear ahora'),
                          ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AgroColors.green,
                  onRefresh: ctrl.loadHistory,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        _HistoryCard(scan: items[i], ctrl: ctrl),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(HistoryController ctrl) {
    // NUEVO: 'Otros' agregado a la botonera de la granja
    final filters = [
      'Todas',
      'Fruta',
      'Verdura',
      'Planta',
      'Flor',
      'Otros' 
    ];

    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: filters.map((f) => Obx(() {
          final isSelected = ctrl.filterCategory.value == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => ctrl.setFilter(f),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AgroColors.green
                      : AgroColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AgroColors.green
                        : AgroColors.border,
                  ),
                ),
                child: Text(f,
                  style: TextStyle(
                    fontFamily: AgroText.fontBody,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : AgroColors.textSecondary,
                  )),
              ),
            ),
          );
        })).toList(),
      ),
    );
  }

  void _confirmDeleteAll(BuildContext context, HistoryController ctrl) {
    if (ctrl.scans.isEmpty) return; 

    Get.dialog(
      AlertDialog(
        title: const Text('¿Borrar todo el historial?', 
          style: TextStyle(fontFamily: AgroText.fontDisplay, color: AgroColors.green, fontWeight: FontWeight.bold)),
        content: const Text('Esta acción eliminará todos los registros guardados permanentemente y no se puede deshacer.',
          style: TextStyle(fontFamily: AgroText.fontBody)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar', style: TextStyle(color: AgroColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AgroColors.red),
            onPressed: () async {
              Get.back();
              for (var scan in ctrl.scans.toList()) {
                await ctrl.deleteScan(scan.id);
              }
              Get.snackbar('Historial limpio', 'Se han borrado todos los escaneos.',
                snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.white);
            },
            child: const Text('Borrar Todo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final ScanResult      scan;
  final HistoryController ctrl;
  const _HistoryCard({required this.scan, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy · HH:mm', 'es');

    return Dismissible(
      key: Key(scan.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AgroColors.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AgroColors.red),
      ),
      onDismissed: (_) => ctrl.deleteScan(scan.id),
      
      child: GestureDetector(
        onTap: () {
          final scanCtrl = Get.find<ScanController>();
          scanCtrl.result.value = scan;
          scanCtrl.capturedImage.value = null; 
          Get.toNamed(AgroRoutes.results);
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AgroColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AgroColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: scan.severityColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      scan.severityLevel == 'healthy'
                          ? Icons.check_circle_outline_rounded
                          : Icons.warning_amber_rounded,
                      color: scan.severityColor,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(scan.displayName,
                          style: TextStyle(
                            fontFamily: AgroText.fontBody,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: scan.severityLevel == 'healthy'
                                ? AgroColors.healthy
                                : AgroColors.textPrimary,
                          )),
                        const SizedBox(height: 3),
                        Text(fmt.format(scan.timestamp),
                          style: const TextStyle(
                            fontFamily: AgroText.fontBody,
                            fontSize: 11,
                            color: AgroColors.brown,
                          )),
                      ],
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AgroColors.yellowLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(scan.confidencePercent,
                          style: const TextStyle(
                            fontFamily: AgroText.fontBody,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AgroColors.brown,
                          )),
                      ),
                      const SizedBox(height: 8),
                      if (!scan.isSynced)
                        const Icon(Icons.cloud_off_outlined,
                            size: 14, color: AgroColors.textHint),
                    ],
                  ),
                ],
              ),
              
              if (scan.description != null && scan.description!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  scan.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AgroText.fontBody,
                    fontSize: 12,
                    color: AgroColors.textPrimary.withOpacity(0.8),
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}