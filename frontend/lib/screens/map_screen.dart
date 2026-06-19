import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart';
import '../core/constants.dart';
import '../controllers/map_controller.dart';
import '../controllers/scan_controller.dart';
import '../models/scan_result.dart';
import '../widgets/scan_result_card.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  static const _categoryColors = {
    'Fruta':   Color(0xFFE53935),
    'Verdura': Color(0xFFFFB300),
    'Planta':  Color(0xFF43A047),
    'Flor':    Color(0xFFE91E63),
    'Otros':   Color(0xFF795548),
  };

  static Color _colorForCategory(String? cat) => _categoryColors[cat] ?? _categoryColors['Otros']!;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mapControllerProvider);
    final ctrl = ref.read(mapControllerProvider.notifier);
    final mapCamera = fmap.MapController();

    return Scaffold(
      backgroundColor: AgroColors.cream,
      body: Stack(
        children: [
          fmap.FlutterMap(
            mapController: mapCamera,
            options: fmap.MapOptions(initialCenter: ctrl.mapCenter, initialZoom: 14.0),
            children: [
              fmap.TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.agrovision.app'),
              
              if (state.isHeatmapMode)
                fmap.CircleLayer(
                  circles: [
                    ...ctrl.filteredPoints.where((s) => s.hasLocation).map((s) => fmap.CircleMarker(
                      point: LatLng(s.latitude!, s.longitude!), radius: 45, useRadiusInMeter: false,
                      color: _colorForCategory(s.plantCategory).withOpacity(0.25),
                      borderColor: _colorForCategory(s.plantCategory).withOpacity(0.65), borderStrokeWidth: 1.5,
                    )),
                  ],
                ),

              if (!state.isHeatmapMode)
                fmap.MarkerLayer(
                  markers: [
                    ...ctrl.filteredPoints.where((s) => s.hasLocation).map((scan) => fmap.Marker(
                      point: LatLng(scan.latitude!, scan.longitude!), width: 30, height: 30,
                      child: GestureDetector(onTap: () => _showMarkerDetails(context, ref, scan), child: _buildPin(scan)),
                    )),
                    if (ctrl.isCurrentPositionUnique && state.currentPosition != null)
                      fmap.Marker(
                        point: state.currentPosition!, width: 34, height: 34,
                        child: GestureDetector(onTap: () => _showCurrentPositionDetail(context), child: _buildCurrentPositionPin()),
                      ),
                  ],
                ),
            ],
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(context, state, mapCamera),
                  const SizedBox(height: 10),
                  _buildCategoryFilters(state, ctrl),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 24, right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'center', backgroundColor: Colors.white, elevation: 3,
                  onPressed: () { if (state.currentPosition != null) mapCamera.move(state.currentPosition!, 15); },
                  child: const Icon(Icons.my_location_rounded, color: AgroColors.green, size: 20),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'heat', backgroundColor: state.isHeatmapMode ? AgroColors.red : Colors.white, elevation: 3,
                  onPressed: ctrl.toggleHeatmap,
                  child: Icon(Icons.coronavirus_rounded, color: state.isHeatmapMode ? Colors.white : Colors.grey, size: 20),
                ),
              ],
            ),
          ),
          Positioned(bottom: 24, left: 16, child: _buildLegend()),
        ],
      ),
    );
  }

  Widget _buildPin(ScanResult scan) {
    final color = _colorForCategory(scan.plantCategory);
    return Container(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2.5), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]),
    );
  }

  Widget _buildCurrentPositionPin() {
    return Container(
      decoration: BoxDecoration(color: AgroColors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: AgroColors.green.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)]),
    );
  }

  Widget _buildTopBar(BuildContext context, MapState state, fmap.MapController map) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.pop(),
          child: Container(width: 38, height: 38, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)]), child: const Icon(Icons.arrow_back_ios_new_rounded, color: AgroColors.green, size: 16)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)]),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ScanResult>(
                isExpanded: true,
                hint: const Text('Ir a un registro...', style: TextStyle(fontFamily: AgroText.fontBody, fontSize: 13, color: AgroColors.textHint)),
                items: state.scanPoints.where((s) => s.hasLocation).map((s) => DropdownMenuItem(value: s, child: Text('${s.displayName} · ${s.confidencePercent}', style: const TextStyle(fontFamily: AgroText.fontBody, fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (val) { if (val != null) map.move(LatLng(val.latitude!, val.longitude!), 16.0); },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilters(MapState state, MapController ctrl) {
    final cats = ['Todas', 'Fruta', 'Verdura', 'Planta', 'Flor', 'Otros'];
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: cats.map((c) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => ctrl.setCategory(c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: state.selectedCategory == c ? (c == 'Todas' ? AgroColors.green : _colorForCategory(c)) : Colors.white,
                borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4)],
              ),
              child: Text(c, style: TextStyle(fontFamily: AgroText.fontBody, fontSize: 12, fontWeight: FontWeight.w500, color: state.selectedCategory == c ? Colors.white : AgroColors.textSecondary)),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildLegend() {
    final items = [('Fruta', const Color(0xFFE53935)), ('Verdura', const Color(0xFFFFB300)), ('Planta', const Color(0xFF43A047)), ('Flor', const Color(0xFFE91E63)), ('Otros', const Color(0xFF795548))];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Categorías', style: TextStyle(fontFamily: AgroText.fontBody, fontSize: 11, fontWeight: FontWeight.w700, color: AgroColors.green, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: item.$2, shape: BoxShape.circle)), const SizedBox(width: 6), Text(item.$1, style: const TextStyle(fontFamily: AgroText.fontBody, fontSize: 11, color: AgroColors.brown))]),
          )),
        ],
      ),
    );
  }

  void _showMarkerDetails(BuildContext context, WidgetRef ref, ScanResult scan) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16), decoration: BoxDecoration(color: AgroColors.cream, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 8), decoration: BoxDecoration(color: AgroColors.border, borderRadius: BorderRadius.circular(2))),
            Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: ScanResultCard(result: scan)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    final scanCtrl = ref.read(scanControllerProvider.notifier);
                    scanCtrl.state = scanCtrl.state.copyWith(result: scan, capturedImage: null);
                    context.push(AgroRoutes.results);
                  },
                  icon: const Icon(Icons.open_in_full_rounded, size: 16), label: const Text('Ver registro completo'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrentPositionDetail(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16), decoration: BoxDecoration(color: AgroColors.cream, borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 16), decoration: BoxDecoration(color: AgroColors.border, borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.my_location_rounded, color: AgroColors.green, size: 40),
                  SizedBox(height: 12),
                  Text('Tu ubicación actual', style: TextStyle(fontFamily: AgroText.fontBody, fontSize: 15, fontWeight: FontWeight.w600, color: AgroColors.green)),
                  SizedBox(height: 6),
                  Text('Aún no hay escaneos registrados aquí.\nUsa la cámara para evaluar un cultivo.', textAlign: TextAlign.center, style: TextStyle(fontFamily: AgroText.fontBody, fontSize: 13, color: AgroColors.brown)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}