import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart';
import '../core/constants.dart';
import '../controllers/map_controller.dart';
import '../controllers/scan_controller.dart';
import '../models/scan_result.dart';
import '../widgets/scan_result_card.dart';

import '../services/api_service.dart';
import '../services/scan_service.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  // NUEVOS COLORES EXACTOS
  static const _categoryColors = {
    'Fruta':   Color(0xFFE53935), // Rojo
    'Verdura': Color(0xFFFFB300), // Amarillo
    'Planta':  Color(0xFF43A047), // Verde
    'Flor':    Color(0xFFE91E63), // Rosa
    'Otros':   Color(0xFF795548), // Café
  };

  static Color _colorForCategory(String? cat) =>
      _categoryColors[cat] ?? _categoryColors['Otros']!;

  @override
  Widget build(BuildContext context) {
    final ctrl      = Get.find<MapController>();
    final mapCamera = fmap.MapController();

    return Scaffold(
      backgroundColor: AgroColors.cream,
      body: Stack(
        children: [
          // ── Mapa ────────────────────────────────────────────────
          Obx(() => fmap.FlutterMap(
            mapController: mapCamera,
            options: fmap.MapOptions(
              initialCenter: ctrl.mapCenter,
              initialZoom:   14.0,
            ),
            children: [
              fmap.TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.agrovision.app',
              ),

              // Heatmap — círculos grandes superpuestos para el mapa de calor
              if (ctrl.isHeatmapMode.value)
                fmap.CircleLayer(
                  circles: [
                    ...ctrl.filteredPoints
                        .where((s) => s.hasLocation)
                        .map((s) => fmap.CircleMarker(
                              point:  LatLng(s.latitude!, s.longitude!),
                              radius: 45,
                              useRadiusInMeter: false, 
                              color:  _colorForCategory(s.plantCategory).withOpacity(0.25),
                              borderColor: _colorForCategory(s.plantCategory).withOpacity(0.65),
                              borderStrokeWidth: 1.5,
                            )),
                  ],
                ),

              // Pins de registros (Puntos llenos)
              if (!ctrl.isHeatmapMode.value)
                fmap.MarkerLayer(
                  markers: [
                    ...ctrl.filteredPoints
                        .where((s) => s.hasLocation)
                        .map((scan) => fmap.Marker(
                              point:  LatLng(scan.latitude!, scan.longitude!),
                              width:  30, // Tamaño del punto
                              height: 30,
                              child: GestureDetector(
                                onTap: () => _showMarkerDetails(context, scan),
                                child: _buildPin(scan),
                              ),
                            )),

                    // Posición actual
                    if (ctrl.isCurrentPositionUnique && ctrl.currentPosition.value != null)
                      fmap.Marker(
                        point:  ctrl.currentPosition.value!,
                        width:  34,
                        height: 34,
                        child: GestureDetector(
                          onTap: () => _showCurrentPositionDetail(context, ctrl),
                          child: _buildCurrentPositionPin(),
                        ),
                      ),
                  ],
                ),
            ],
          )),

          // ── Controles superiores ───────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(ctrl, mapCamera),
                  const SizedBox(height: 10),
                  _buildCategoryFilters(ctrl),
                ],
              ),
            ),
          ),

          // ── FABs derecha ───────────────────────────────────────
          Positioned(
            bottom: 24,
            right:  16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag:         'center',
                  backgroundColor: Colors.white,
                  elevation:       3,
                  onPressed: () {
                    if (ctrl.currentPosition.value != null) {
                      mapCamera.move(ctrl.currentPosition.value!, 15);
                    }
                  },
                  child: const Icon(Icons.my_location_rounded, color: AgroColors.green, size: 20),
                ),
                const SizedBox(height: 10),
                Obx(() => FloatingActionButton.small(
                  heroTag:         'heat',
                  backgroundColor: ctrl.isHeatmapMode.value ? AgroColors.red : Colors.white,
                  elevation: 3,
                  onPressed: ctrl.toggleHeatmap,
                  child: Icon(
                    Icons.coronavirus_rounded, 
                    color: ctrl.isHeatmapMode.value ? Colors.white : Colors.grey,
                    size: 20,
                  ),
                )),
              ],
            ),
          ),

          // ── Leyenda categorías ─────────────────────────────────
          Positioned(
            bottom: 24,
            left:   16,
            child: _buildLegend(),
          ),
        ],
      ),
    );
  }

  // ── Pin de registro guardado (PUNTO LLENO) ─────────────────────────────

  Widget _buildPin(ScanResult scan) {
    final color = _colorForCategory(scan.plantCategory);
    return Container(
      decoration: BoxDecoration(
        color: color, // Color de relleno (Punto lleno)
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5), // Borde blanco para resaltar en el mapa
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  // ── Pin de posición actual (Diferente para distinguirlo) ───────────────

  Widget _buildCurrentPositionPin() {
    return Container(
      decoration: BoxDecoration(
        color:  AgroColors.green,
        shape:  BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AgroColors.green.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar(MapController ctrl, fmap.MapController map) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            width:  38,
            height: 38,
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: AgroColors.green, size: 16),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
            ),
            child: Obx(() => DropdownButtonHideUnderline(
              child: DropdownButton<ScanResult>(
                isExpanded: true,
                hint: const Text(
                  'Ir a un registro...',
                  style: TextStyle(fontFamily: AgroText.fontBody, fontSize: 13, color: AgroColors.textHint),
                ),
                items: ctrl.scanPoints
                    .where((s) => s.hasLocation)
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(
                            '${s.displayName} · ${s.confidencePercent}',
                            style: const TextStyle(fontFamily: AgroText.fontBody, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )).toList(),
                onChanged: (val) {
                  if (val != null) map.move(LatLng(val.latitude!, val.longitude!), 16.0);
                },
              ),
            )),
          ),
        ),
      ],
    );
  }

  // ── Filtros de categoría ──────────────────────────────────────────────────

  Widget _buildCategoryFilters(MapController ctrl) {
    final cats = ['Todas', 'Fruta', 'Verdura', 'Planta', 'Flor', 'Otros'];
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: cats
            .map((c) => Obx(() => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => ctrl.setCategory(c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: ctrl.selectedCategory.value == c
                            ? (c == 'Todas' ? AgroColors.green : _colorForCategory(c))
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4)],
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          fontFamily: AgroText.fontBody,
                          fontSize:   12,
                          fontWeight: FontWeight.w500,
                          color: ctrl.selectedCategory.value == c ? Colors.white : AgroColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                )))
            .toList(),
      ),
    );
  }

  // ── Leyenda ───────────────────────────────────────────────────────────────

  Widget _buildLegend() {
    final items = [
      ('Fruta',   const Color(0xFFE53935)),
      ('Verdura', const Color(0xFFFFB300)),
      ('Planta',  const Color(0xFF43A047)),
      ('Flor',    const Color(0xFFE91E63)),
      ('Otros',   const Color(0xFF795548)),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:        Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize:       MainAxisSize.min,
        children: [
          const Text('Categorías', style: TextStyle(fontFamily: AgroText.fontBody, fontSize: 11, fontWeight: FontWeight.w700, color: AgroColors.green, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: item.$2, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(item.$1, style: const TextStyle(fontFamily: AgroText.fontBody, fontSize: 11, color: AgroColors.brown)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── Bottom sheet al tocar pin de registro ─────────────────────────────────

  void _showMarkerDetails(BuildContext context, ScanResult scan) {
    showModalBottomSheet(
      context:         context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        AgroColors.cream,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 8), decoration: BoxDecoration(color: AgroColors.border, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ScanResultCard(result: scan),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.back(); 
                    _navigateToResult(scan);
                  },
                  icon:  const Icon(Icons.open_in_full_rounded, size: 16),
                  label: const Text('Ver registro completo'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom sheet al tocar posición actual ─────────────────────────────────

  void _showCurrentPositionDetail(BuildContext context, MapController ctrl) {
    showModalBottomSheet(
      context:         context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AgroColors.cream, borderRadius: BorderRadius.circular(20)),
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
                  Text(
                    'Tu ubicación actual',
                    style: TextStyle(fontFamily: AgroText.fontBody, fontSize: 15, fontWeight: FontWeight.w600, color: AgroColors.green),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Aún no hay escaneos registrados aquí.\nUsa la cámara para evaluar un cultivo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: AgroText.fontBody, fontSize: 13, color: AgroColors.brown),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Navegar a results con protección de inyección ─────────────────────────

  void _navigateToResult(ScanResult scan) {
    if (!Get.isRegistered<ApiService>()) {
      Get.lazyPut(() => ApiService());
    }
    if (!Get.isRegistered<ScanService>()) {
      Get.lazyPut(() => ScanService(Get.find(), Get.find()));
    }
    
    if (!Get.isRegistered<ScanController>()) {
      Get.lazyPut(() => ScanController(Get.find(), Get.find(), Get.find()));
    }

    final ctrl = Get.find<ScanController>();
    ctrl.result.value = scan;
    ctrl.capturedImage.value = null;
    
    Get.toNamed(AgroRoutes.results);
  }
}