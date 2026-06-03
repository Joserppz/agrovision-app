import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../controllers/history_controller.dart';
import '../controllers/scan_controller.dart'; // IMPORTANTE: Importamos el controlador de escaneo
import '../models/scan_result.dart';
import '../widgets/offline_banner.dart';
import '../controllers/connectivity_controller.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

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

            // Header
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
                  const Text('Historial de escaneos',
                      style: TextStyle(
                        fontFamily: AgroText.fontDisplay,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AgroColors.green,
                      )),
                  const Spacer(),
                  GestureDetector(
                    onTap: ctrl.loadHistory,
                    child: const Icon(Icons.refresh_rounded,
                        color: AgroColors.green, size: 22),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Filtros
            _buildFilters(ctrl),

            const SizedBox(height: 8),

            // Resumen
            Obx(() => Padding(
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
                      '${ctrl.scans.length} escaneos totales · '
                      '${ctrl.scans.where((s) => s.severityLevel != 'healthy').length} enfermedades',
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
            )),

            const SizedBox(height: 8),

            // Lista
            Expanded(
              child: Obx(() {
                if (ctrl.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AgroColors.green),
                  );
                }

                final items = ctrl.filteredScans;

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.eco_outlined,
                            color: AgroColors.border, size: 56),
                        const SizedBox(height: 12),
                        Text('No hay escaneos aún',
                            style: Get.textTheme.bodyMedium?.copyWith(
                                color: AgroColors.textHint)),
                        const SizedBox(height: 8),
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
    final filters = [
      ('all',      'Todos'),
      ('critical', 'Crítico'),
      ('moderate', 'Moderado'),
      ('healthy',  'Sano'),
    ];

    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: filters.map((f) => Obx(() => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => ctrl.setFilter(f.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: ctrl.filterLevel.value == f.$1
                    ? AgroColors.green
                    : AgroColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: ctrl.filterLevel.value == f.$1
                      ? AgroColors.green
                      : AgroColors.border,
                ),
              ),
              child: Text(f.$2,
                style: TextStyle(
                  fontFamily: AgroText.fontBody,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: ctrl.filterLevel.value == f.$1
                      ? Colors.white
                      : AgroColors.textSecondary,
                )),
            ),
          ),
        ))).toList(),
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
      
      // NUEVO: Envolvemos en GestureDetector para poder tocar el historial
      child: GestureDetector(
        onTap: () {
          // Cargamos el controlador de escaneo (debe estar registrado en la app)
          // Evitamos usar Get.put() porque ScanController requiere argumentos.
          final scanCtrl = Get.find<ScanController>();
              
          // Le inyectamos el resultado histórico
          scanCtrl.result.value = scan;
          // Limpiamos la imagen temporal para que muestre el recuadro gris
          scanCtrl.capturedImage.value = null; 
          
          // Navegamos al Result Screen
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
                  // Icono de enfermedad
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

                  // Info
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

                  // Confianza + flecha
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
              
              // NUEVO: Agregamos un pequeño extracto de la descripción si la IA lo detectó
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