import 'package:flutter/material.dart';
import 'package:frontend/controllers/scan_controller.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart' as fmap; // ALIAS: Para no chocar con tu MapController
import 'package:latlong2/latlong.dart';
import '../core/constants.dart';
import '../controllers/map_controller.dart';
import '../models/scan_result.dart';
import '../widgets/scan_result_card.dart'; // Reutilizamos tu tarjeta del historial

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Obtenemos tu controlador de lógica (GetX)
    final ctrl = Get.find<MapController>();
    // 2. Creamos el controlador físico de la cámara del mapa
    final fmap.MapController mapCamera = fmap.MapController();

    return Scaffold(
      backgroundColor: AgroColors.cream,
      appBar: AppBar(
        title: const Text(
          'Mapa Epidemiológico',
          style: TextStyle(
            fontFamily: AgroText.fontDisplay,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AgroColors.green,
          ),
        ),
        backgroundColor: AgroColors.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AgroColors.green),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AgroColors.green));
        }

        return Stack(
          children: [
            // --- CAPA 1: EL MAPA ---
            fmap.FlutterMap(
              mapController: mapCamera,
              options: fmap.MapOptions(
                initialCenter: ctrl.mapCenter, // Usa tu GPS o La Paz por defecto
                initialZoom: 13.5,
                maxZoom: 18.0,
              ),
              children: [
                // Baldosas de OpenStreetMap (Gratis y sin API Keys)
                fmap.TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.agrovision',
                ),
                // Marcadores de las enfermedades
                fmap.MarkerLayer(
                  markers: ctrl.filteredPoints.map((scan) {
                    return fmap.Marker(
                      point: LatLng(scan.latitude!, scan.longitude!),
                      width: 45,
                      height: 45,
                      child: GestureDetector(
                        onTap: () => _showMarkerDetails(context, scan),
                        child: Column(
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white, // Borde blanco para resaltar
                              ),
                              child: Icon(
                                Icons.location_on_rounded,
                                color: scan.severityColor,
                                size: 38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            // --- CAPA 2: BARRA DE FILTROS SUPERIOR ---
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: _buildFilters(ctrl),
            ),

            // --- CAPA 3: BOTÓN DE MI UBICACIÓN ---
            Positioned(
              bottom: 30,
              right: 20,
              child: FloatingActionButton(
                backgroundColor: AgroColors.green,
                elevation: 4,
                child: const Icon(Icons.my_location_rounded, color: Colors.white),
                onPressed: () {
                  if (ctrl.currentPosition.value != null) {
                    // Mueve la cámara suavemente a tu ubicación
                    mapCamera.move(ctrl.currentPosition.value!, 15.0);
                  } else {
                    Get.snackbar('GPS', 'Buscando tu ubicación...');
                  }
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  // Lista deslizable de botones para filtrar el mapa
  Widget _buildFilters(MapController ctrl) {
    final filters = [
      ('all',      'Todos'),
      ('critical', 'Críticos'),
      ('moderate', 'Moderados'),
      ('healthy',  'Sanos'),
    ];

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: filters.map((f) => Obx(() {
          final isSelected = ctrl.selectedFilter.value == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => ctrl.setFilter(f.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AgroColors.green : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    f.$2,
                    style: TextStyle(
                      fontFamily: AgroText.fontBody,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AgroColors.green,
                    ),
                  ),
                ),
              ),
            ),
          );
        })).toList(),
      ),
    );
  }

  // Abre una tarjeta informativa desde abajo cuando tocas un pin
  void _showMarkerDetails(BuildContext context, ScanResult scan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: ScanResultCard(
          result: scan,
          onTap: () {
            // Cierra el BottomSheet y nos lleva a ver el tratamiento completo
            Get.back();
            // Inyectamos la información en el ScanController para la pantalla de Resultados
            Get.find<ScanController>().result.value = scan;
            Get.find<ScanController>().capturedImage.value = null;
            Get.toNamed(AgroRoutes.results);
          },
        ),
      ),
    );
  }
}