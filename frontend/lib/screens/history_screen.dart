import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../controllers/history_controller.dart';
import '../controllers/scan_controller.dart'; 
import '../models/scan_result.dart';
// import '../widgets/offline_banner.dart'; // Comentado temporalmente

// Usamos HookConsumerWidget para manejar texto sin StatefulWidget
class HistoryScreen extends HookConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Magia de Flutter Hooks: controlador de texto sin State
    final searchCtrl = useTextEditingController();
    useListenable(searchCtrl); // Escucha cambios al escribir

    final state = ref.watch(historyControllerProvider);
    final ctrl = ref.read(historyControllerProvider.notifier);
    
    final bool isOnline = true; // Simulación hasta migrar conectividad

    return Scaffold(
      backgroundColor: AgroColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            if (!isOnline)
              Container(
                width: double.infinity,
                color: AgroColors.brown,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: const Text('Modo Offline', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 12)),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: AgroColors.green, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('Historial', style: TextStyle(fontFamily: AgroText.fontDisplay, fontSize: 20, fontWeight: FontWeight.w700, color: AgroColors.green)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      searchCtrl.clear(); 
                      ctrl.loadHistory();
                    },
                    child: const Icon(Icons.refresh_rounded, color: AgroColors.green, size: 22),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => _confirmDeleteAll(context, state, ctrl),
                    child: const Icon(Icons.delete_sweep_rounded, color: AgroColors.red, size: 22),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 40,
                decoration: BoxDecoration(color: AgroColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AgroColors.border)),
                child: TextField(
                  controller: searchCtrl,
                  style: const TextStyle(fontFamily: AgroText.fontBody, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Buscar planta o enfermedad...',
                    hintStyle: TextStyle(fontFamily: AgroText.fontBody, color: AgroColors.textHint, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: AgroColors.green, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            _buildFilters(state, ctrl),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: AgroColors.greenFaint, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.bar_chart_rounded, color: AgroColors.green, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${state.scans.length} registros · ${state.scans.where((s) => s.severityLevel != 'healthy').length} con novedades',
                      style: const TextStyle(fontFamily: AgroText.fontBody, fontSize: 12, fontWeight: FontWeight.w500, color: AgroColors.green),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: Builder(builder: (context) {
                if (state.isLoading) return const Center(child: CircularProgressIndicator(color: AgroColors.green));

                List<ScanResult> items = ctrl.filteredScans;
                final searchTerm = searchCtrl.text.toLowerCase();
                if (searchTerm.isNotEmpty) {
                  items = items.where((scan) {
                    return scan.displayName.toLowerCase().contains(searchTerm) || (scan.description?.toLowerCase().contains(searchTerm) ?? false);
                  }).toList();
                }

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.eco_outlined, color: AgroColors.border, size: 56),
                        const SizedBox(height: 12),
                        const Text('No hay escaneos que mostrar', style: TextStyle(color: AgroColors.textHint, fontFamily: AgroText.fontBody)),
                        const SizedBox(height: 8),
                        if (state.scans.isEmpty) 
                          ElevatedButton.icon(
                            onPressed: () => context.push(AgroRoutes.camera),
                            icon: const Icon(Icons.camera_alt_outlined, size: 16),
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
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _HistoryCard(scan: items[i], ctrl: ctrl),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(HistoryState state, HistoryController ctrl) {
    final filters = ['Todas', 'Fruta', 'Verdura', 'Planta', 'Flor', 'Otros'];

    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: filters.map((f) {
          final isSelected = state.filterCategory == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => ctrl.setFilter(f),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? AgroColors.green : AgroColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? AgroColors.green : AgroColors.border),
                ),
                child: Text(f, style: TextStyle(fontFamily: AgroText.fontBody, fontSize: 12, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : AgroColors.textSecondary)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _confirmDeleteAll(BuildContext context, HistoryState state, HistoryController ctrl) {
    if (state.scans.isEmpty) return; 

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Borrar todo el historial?', style: TextStyle(fontFamily: AgroText.fontDisplay, color: AgroColors.green, fontWeight: FontWeight.bold)),
        content: const Text('Esta acción eliminará todos los registros guardados permanentemente y no se puede deshacer.', style: TextStyle(fontFamily: AgroText.fontBody)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: AgroColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AgroColors.red),
            onPressed: () async {
              Navigator.pop(context);
              for (var scan in state.scans.toList()) {
                await ctrl.deleteScan(scan.id);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Se han borrado todos los escaneos.')));
              }
            },
            child: const Text('Borrar Todo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Widget interno extraído para usar WidgetRef si necesita navegar inyectando el resultado
class _HistoryCard extends ConsumerWidget {
  final ScanResult scan;
  final HistoryController ctrl;
  
  const _HistoryCard({required this.scan, required this.ctrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('dd MMM yyyy · HH:mm', 'es');

    return Dismissible(
      key: Key(scan.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: AgroColors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_outline_rounded, color: AgroColors.red),
      ),
      onDismissed: (_) => ctrl.deleteScan(scan.id),
      child: GestureDetector(
        onTap: () {
          // Cargamos el resultado en el controlador de la cámara y navegamos
          final scanCtrl = ref.read(scanControllerProvider.notifier);
          scanCtrl.state = scanCtrl.state.copyWith(result: scan, capturedImage: null);
          context.push(AgroRoutes.results);
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AgroColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AgroColors.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(color: scan.severityColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                    child: Icon(scan.severityLevel == 'healthy' ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded, color: scan.severityColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(scan.displayName, style: TextStyle(fontFamily: AgroText.fontBody, fontSize: 14, fontWeight: FontWeight.w600, color: scan.severityLevel == 'healthy' ? AgroColors.healthy : AgroColors.textPrimary)),
                        const SizedBox(height: 3),
                        Text(fmt.format(scan.timestamp), style: const TextStyle(fontFamily: AgroText.fontBody, fontSize: 11, color: AgroColors.brown)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AgroColors.yellowLight, borderRadius: BorderRadius.circular(8)),
                        child: Text(scan.confidencePercent, style: const TextStyle(fontFamily: AgroText.fontBody, fontSize: 11, fontWeight: FontWeight.w700, color: AgroColors.brown)),
                      ),
                      const SizedBox(height: 8),
                      if (!scan.isSynced) const Icon(Icons.cloud_off_outlined, size: 14, color: AgroColors.textHint),
                    ],
                  ),
                ],
              ),
              if (scan.description != null && scan.description!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(scan.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: AgroText.fontBody, fontSize: 12, color: AgroColors.textPrimary.withOpacity(0.8), height: 1.3)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}